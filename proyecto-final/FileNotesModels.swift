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

// MARK: - Modelos para la respuesta del servidor

struct FileInfo: Codable {
    let id: Int
    let filename: String
    let url: String
    let path: String
    let type: String
    let uploadedAt: String
    let isActive: Bool
    let user: UserInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case filename
        case url
        case path
        case type
        case uploadedAt = "uploaded_at"
        case isActive = "is_active"
        case user
    }
}

struct UserInfo: Codable {
    let id: Int
    let fullName: String
    let email: String
    let googleId: String?
    let roles: [String]
    let createdAt: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName
        case email
        case googleId
        case roles
        case createdAt
        case isActive
    }
}

struct AuditRecord: Codable, Identifiable {
    let id: Int
    let notes: String
    let status: String
    let auditedAt: String
    let file: FileInfo
    
    // Propiedad computada para compatibilidad
    var fileId: Int {
        return file.id
    }
    
    // Propiedad computada para compatibilidad
    var createdAt: String {
        return auditedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case notes
        case status
        case auditedAt = "audited_at"
        case file
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
    @Published var isLoadingNotes = false
    
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
            
            // Verificar el código de respuesta HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                    // Éxito - el servidor creó/actualizó el registro
                    DispatchQueue.main.async {
                        self.showSuccess = true
                        self.currentNotes = ""
                        self.selectedStatus = .pending
                        self.errorMessage = nil
                        // Recargar la lista de registros
                        self.fetchAuditRecords(fileId: fileId)
                    }
                    return
                } else if httpResponse.statusCode == 204 {
                    // No content - también es éxito
                    DispatchQueue.main.async {
                        self.showSuccess = true
                        self.currentNotes = ""
                        self.selectedStatus = .pending
                        self.errorMessage = nil
                        // Recargar la lista de registros
                        self.fetchAuditRecords(fileId: fileId)
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No se recibieron datos del servidor"
                }
                return
            }
            
            // Intentar decodificar solo si hay datos
            if !data.isEmpty {
                do {
                    let response = try JSONDecoder().decode(FileAuditResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.showSuccess = true
                        self.currentNotes = ""
                        self.selectedStatus = .pending
                        self.errorMessage = nil
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
            } else {
                // Respuesta vacía pero exitosa
                DispatchQueue.main.async {
                    self.showSuccess = true
                    self.currentNotes = ""
                    self.selectedStatus = .pending
                    self.errorMessage = nil
                    // Recargar la lista de registros
                    self.fetchAuditRecords(fileId: fileId)
                }
            }
        }.resume()
    }
    
    func fetchAuditRecords(fileId: Int) {
        isLoadingNotes = true
        // Obtener todas las notas del usuario para mostrar en el historial
        fetchAllUserAuditRecords { [weak self] in
            DispatchQueue.main.async {
                // Filtrar solo los registros del archivo actual para el historial
                if let self = self {
                    self.auditRecords = self.auditRecords.filter { $0.fileId == fileId }
                }
                self?.isLoadingNotes = false
            }
        }
    }
    
    func loadExistingNotes(for fileId: Int) {
        isLoadingNotes = true
        errorMessage = nil
        
        // Primero cargar todas las notas del usuario
        fetchAllUserAuditRecords { [weak self] in
            DispatchQueue.main.async {
                // Buscar si ya existe una nota para este archivo específico
                if let existingRecord = self?.auditRecords.first(where: { $0.fileId == fileId }) {
                    self?.currentNotes = existingRecord.notes
                    self?.selectedStatus = FileStatus(rawValue: existingRecord.status) ?? .pending
                }
                self?.isLoadingNotes = false
            }
        }
    }
    
    private func fetchAuditRecordsForFile(fileId: Int) {
        guard let url = URL(string: "http://localhost:3000/api/audit-record?fileId=\(fileId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingNotes = false
            }
            
            if let error = error {
                print("❌ Error fetching audit records for file:", error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let records = try JSONDecoder().decode([AuditRecord].self, from: data)
                DispatchQueue.main.async {
                    // Filtrar solo los registros del archivo actual
                    self.auditRecords = records.filter { $0.fileId == fileId }
                }
            } catch {
                print("❌ Error decodificando audit records for file:", error)
                if let raw = String(data: data, encoding: .utf8) {
                    print("📄 Respuesta cruda:", raw)
                }
            }
        }.resume()
    }
    
    func fetchAllUserAuditRecords(completion: (() -> Void)? = nil) {
        guard let url = URL(string: "http://localhost:3000/api/audit-record/user") else { 
            completion?()
            return 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error fetching user audit records:", error)
                completion?()
                return
            }
            
            guard let data = data else { 
                completion?()
                return 
            }
            
            do {
                let records = try JSONDecoder().decode([AuditRecord].self, from: data)
                DispatchQueue.main.async {
                    // Actualizar todos los registros del usuario
                    self.auditRecords = records
                    completion?()
                }
            } catch {
                print("❌ Error decodificando user audit records:", error)
                if let raw = String(data: data, encoding: .utf8) {
                    print("📄 Respuesta cruda:", raw)
                }
                completion?()
            }
        }.resume()
    }
}
