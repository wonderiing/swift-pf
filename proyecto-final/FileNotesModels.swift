import Foundation

// MARK: - Modelos para Notas y Estado de Archivos

struct FileAuditRequest: Codable {
    let fileId: Int
    let notes: String
    let status: String
    
    init(fileId: Int, notes: String, status: FileStatus) {
        self.fileId = fileId
        self.notes = notes
        self.status = status.rawValue
    }
}

enum FileStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case reviewed = "rejected"  // Nota: el backend usa 'rejected' pero el enum se llama 'reviewed'
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendiente"
        case .approved:
            return "Aprobado"
        case .reviewed:
            return "Revisado"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .approved:
            return "green"
        case .reviewed:
            return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .reviewed:
            return "eye.circle.fill"
        }
    }
}

// La respuesta del servidor es directamente un AuditRecord
typealias FileAuditResponse = AuditRecord

struct AuditRecord: Codable, Identifiable {
    let id: Int
    let fileId: Int
    let notes: String
    let status: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fileId = "file_id"
        case notes
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - ViewModel para Notas y Estado
class FileNotesViewModel: ObservableObject {
    @Published var currentNotes = ""
    @Published var selectedStatus: FileStatus = .pending
    @Published var isSubmitting = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    @Published var auditRecords: [AuditRecord] = []
    
    func submitNotes(fileId: Int) {
        guard !currentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Las notas no pueden estar vacías"
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/audit-record") else {
            errorMessage = "URL inválida"
            return
        }
        
        let request = FileAuditRequest(fileId: fileId, notes: currentNotes, status: selectedStatus)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = TokenManager.shared.currentToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            errorMessage = "Error codificando datos: \(error.localizedDescription)"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                self.isSubmitting = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error de red: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No se recibieron datos"
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(FileAuditResponse.self, from: data)
                DispatchQueue.main.async {
                    // Si llegamos aquí, la respuesta fue exitosa
                    self.showSuccess = true
                    self.currentNotes = ""
                    self.selectedStatus = .pending
                    // Recargar la lista de registros
                    self.fetchAuditRecords(fileId: fileId)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error decodificando respuesta: \(error.localizedDescription)"
                }
                print("❌ Error decodificando audit response:", error)
                if let raw = String(data: data, encoding: .utf8) {
                    print("📄 Respuesta cruda:", raw)
                }
            }
        }.resume()
    }
    
    func fetchAuditRecords(fileId: Int) {
        guard let url = URL(string: "http://localhost:3000/api/audit-record?fileId=\(fileId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error fetching audit records:", error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let records = try JSONDecoder().decode([AuditRecord].self, from: data)
                DispatchQueue.main.async {
                    self.auditRecords = records
                }
            } catch {
                print("❌ Error decodificando audit records:", error)
            }
        }.resume()
    }
}
