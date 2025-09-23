import SwiftUI
import UniformTypeIdentifiers

// ContentView.swift
struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            TabView {
                DashboardView()
                    .id(session.userId) // Forzar reconstrucción completa de DashboardView
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }

                FileFinder()
                    .tabItem {
                        Image(systemName: "folder.fill")
                        Text("FileFinder")
                    }
            }
        }
    }
}


enum PickerType {
    case document
    case contract
}

// Notificaciones para login/logout
extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
    static let fileUploaded = Notification.Name("fileUploaded")
}

// MARK: - Dashboard Stats Manager
class DashboardStatsManager: ObservableObject {
    @Published var totalFiles = 0
    @Published var completedAudits = 0
    @Published var pendingFiles = 0
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    func reset() {
        print("🔄 DashboardStatsManager reset called")
        totalFiles = 0
        completedAudits = 0
        pendingFiles = 0
        isLoading = true
        errorMessage = nil
    }
    
    func updatePendingFiles() {
        pendingFiles = max(totalFiles - completedAudits, 0)
    }
}


struct DashboardView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var statsManager = DashboardStatsManager()

    // Estados del dashboard - solo usar statsManager
    // Eliminamos las variables @State duplicadas
    
    // ID único para forzar reconstrucción
    @State private var viewId = UUID()
    
    // Forzar actualización de UI
    @State private var refreshTrigger = UUID()

    // Upload states
    enum PickerType: Identifiable {
        case document, contract
        var id: Int { hashValue }
    }
    @State private var activePicker: PickerType? = nil
    
    // Estados separados para cada uploader
    @State private var documentUploading = false
    @State private var documentProgress = 0.0
    @State private var documentFileName = ""
    @State private var documentShowSuccess = false
    @State private var documentMessage = ""
    
    @State private var contractUploading = false
    @State private var contractProgress = 0.0
    @State private var contractFileName = ""
    @State private var contractShowSuccess = false
    @State private var contractMessage = ""
    
    // Control para evitar uploads duplicados
    @State private var isProcessingUpload = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // HEADER
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("👋 Bienvenido")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Tu Dashboard")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        }
                        Spacer()
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal)

                // STATS
                if statsManager.isLoading {
                    ProgressView("Cargando estadísticas…")
                        .padding()
                } else {
                    HStack(spacing: 16) {
                        StatMiniCard(
                            title: "Totales", 
                            value: "\(statsManager.totalFiles)", 
                            color: .blue, 
                            icon: "doc.on.doc.fill",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        StatMiniCard(
                            title: "Completadas", 
                            value: "\(statsManager.completedAudits)", 
                            color: .green, 
                            icon: "checkmark.circle.fill",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        StatMiniCard(
                            title: "Pendientes", 
                            value: "\(statsManager.pendingFiles)", 
                            color: .yellow, 
                            icon: "clock.fill",
                            gradient: LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.yellow.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .padding(.horizontal)
                }

                // UPLOADERS
                VStack(spacing: 20) {
                    UploadCard(
                        title: "Subir Ventas",
                        subtitle: "Envia archivos de ventas. Formatos: CSV, Excel",
                        color: .blue,
                        icon: "arrow.up.doc.fill",
                        isUploading: $documentUploading,
                        progress: $documentProgress,
                        fileName: $documentFileName,
                        showSuccess: $documentShowSuccess,
                        uploadMessage: $documentMessage,
                        onPick: { 
                            guard !isProcessingUpload else { return }
                            activePicker = .document 
                        }
                    )

                    UploadCard(
                        title: "Subir Contrato",
                        subtitle: "Envía documentos legales al sistema",
                        color: .yellow,
                        icon: "doc.text.fill",
                        isUploading: $contractUploading,
                        progress: $contractProgress,
                        fileName: $contractFileName,
                        showSuccess: $contractShowSuccess,
                        uploadMessage: $contractMessage,
                        onPick: { 
                            guard !isProcessingUpload else { return }
                            activePicker = .contract 
                        }
                    )
                }
                .padding(.horizontal)

                // MENSAJES
                if let errorMessage = statsManager.errorMessage {
                    MessageView(text: errorMessage, color: .red, icon: "exclamationmark.triangle.fill")
                }

                // BOTÓN DE LOGOUT
                Button(action: {
                    session.logout()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                        Text("Cerrar Sesión")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.05),
                    Color.green.opacity(0.02),
                    Color.green.opacity(0.01)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            // Siempre resetear estado cuando aparece la vista
            statsManager.reset()
            resetDashboardState()
            
            // Usar Task con delay para asegurar que el token esté completamente propagado
            Task {
                // Pequeño delay para asegurar que el token esté disponible
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
                
                // Verificar token nuevamente después del delay
                if session.token != nil {
                    await fetchStats()
                } else {
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fileDeleted)) { _ in

            Task {
                await fetchStats()
            }
        }
        .refreshable { await fetchStats() }
        // Sheet único para uploads
        .sheet(item: $activePicker) { picker in
            DocumentPicker { url in
                switch picker {
                case .document:
                    uploadFile(from: url, to: "http://127.0.0.1:3000/api/processing-pipeline-module/data", type: .document)
                case .contract:
                    uploadFile(from: url, to: "http://127.0.0.1:3000/api/processing-pipeline-module/contract", type: .contract)
                }
            }
        }
    }

    // MARK: - Funciones de datos
    func fetchStats() async {
        
        guard let currentToken = session.token else {
            await MainActor.run {
                statsManager.isLoading = false
                resetDashboardState()
            }
            return
        }

        
        await MainActor.run {
            statsManager.isLoading = true
            statsManager.errorMessage = nil
        }

        do {
            // Pasar el token directamente sin almacenarlo en variable local
            try await fetchFiles(token: currentToken)
            try await fetchAudits(token: currentToken)
            
            await MainActor.run {
                statsManager.isLoading = false
                refreshTrigger = UUID()
                print("✅ Stats fetched successfully - Files: \(statsManager.totalFiles), Audits: \(statsManager.completedAudits)")
            }
        } catch {
            await MainActor.run {
                statsManager.isLoading = false
                print("❌ Error fetchStats: \(error)")
                statsManager.errorMessage = "Error cargando datos: \(error.localizedDescription)"
            }
        }
    }

    func fetchFiles(token: String) async throws {
        print("📁 Dashboard fetchFiles called with token: \(token.prefix(20))...")
        guard let url = URL(string: "http://localhost:3000/api/files/user?limit=50") else { return }
        print("🔍 Dashboard: URL de consulta: \(url)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("📁 Request header: Bearer \(token.prefix(20))...")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let respBody = String(data: data, encoding: .utf8) ?? "No body"
            print("Error fetchFiles statusCode: \(httpResponse.statusCode), body: \(respBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            print("📊 Dashboard: Total archivos recibidos: \(json.count)")
            
            // Mostrar todos los archivos antes del filtrado
            print("📋 Dashboard: Lista completa de archivos:")
            for (index, file) in json.enumerated() {
                let isActive = file["is_active"] as? Bool ?? false
                let filename = file["filename"] as? String ?? "Sin nombre"
                let fileId = file["id"] as? Int ?? 0
                let fileType = file["type"] as? String ?? "Sin tipo"
                let status = isActive ? "ACTIVO" : "INACTIVO"
                print("📁 Dashboard: Archivo \(index + 1): \(filename) (ID: \(fileId), Status: \(status), Tipo: \(fileType))")
            }
            
            // Filtrar solo archivos activos
            let activeFiles = json.filter { file in
                if let isActive = file["is_active"] as? Bool {
                    return isActive
                }
                return false
            }
            
            print("📊 Dashboard: Archivos activos: \(activeFiles.count) de \(json.count)")
            
            // Mostrar archivos activos después del filtrado
            print("📋 Dashboard: Lista de archivos activos:")
            for (index, file) in activeFiles.enumerated() {
                let filename = file["filename"] as? String ?? "Sin nombre"
                let fileId = file["id"] as? Int ?? 0
                let fileType = file["type"] as? String ?? "Sin tipo"
                print("📁 Dashboard: Activo \(index + 1): \(filename) (ID: \(fileId), Tipo: \(fileType))")
            }
            
            await MainActor.run {
                statsManager.totalFiles = activeFiles.count
                statsManager.updatePendingFiles()
            }
        }
    }

    func fetchAudits(token: String) async throws {
        guard let url = URL(string: "http://localhost:3000/api/audit-record/user?limit=5") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let respBody = String(data: data, encoding: .utf8) ?? "No body"
            print("Error fetchAudits statusCode: \(httpResponse.statusCode), body: \(respBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            await MainActor.run {
                statsManager.completedAudits = json.count
                statsManager.updatePendingFiles()
            }
        }
    }


    func resetDashboardState() {
        print("🔄 Resetting dashboard state...")
        // Solo resetear statsManager, no variables locales
        statsManager.reset()
        
        // Resetear estados de upload separados
        documentUploading = false
        documentProgress = 0
        documentFileName = ""
        documentShowSuccess = false
        documentMessage = ""
        
        contractUploading = false
        contractProgress = 0
        contractFileName = ""
        contractShowSuccess = false
        contractMessage = ""
        
        // Resetear flag de control de uploads
        isProcessingUpload = false
        
        refreshTrigger = UUID() // Forzar actualización de UI
        print("🔄 Dashboard state reset complete - Files: \(statsManager.totalFiles), Audits: \(statsManager.completedAudits)")
    }

    // MARK: - Upload
    func uploadFile(from url: URL, to endpoint: String, type: PickerType) {
        // Evitar uploads duplicados
        guard !isProcessingUpload else {
            print("⚠️ Upload ya en progreso, ignorando llamada duplicada")
            return
        }
        
        guard let token = session.token else {
            statsManager.errorMessage = "No hay token de autenticación"
            return
        }

        let fileName = url.lastPathComponent
        statsManager.errorMessage = nil
        
        // Marcar que estamos procesando un upload
        isProcessingUpload = true
        
        // Configurar estados según el tipo
        switch type {
        case .document:
            documentFileName = fileName
            documentUploading = true
            documentShowSuccess = false
            documentProgress = 0.0
        case .contract:
            contractFileName = fileName
            contractUploading = true
            contractShowSuccess = false
            contractProgress = 0.0
        }

        Task {
            do {
                for i in 1...3 {
                    await MainActor.run {
                        switch type {
                        case .document:
                            documentProgress = Double(i)/4.0
                        case .contract:
                            contractProgress = Double(i)/4.0
                        }
                    }
                    try await Task.sleep(nanoseconds: 500_000_000)
                }

                try await performUpload(fileURL: url, token: token, endpoint: endpoint)

                await MainActor.run {
                    switch type {
                    case .document:
                        documentProgress = 1.0
                        documentUploading = false
                        documentShowSuccess = true
                        documentMessage = "¡Archivo '\(fileName)' subido exitosamente!"
                    case .contract:
                        contractProgress = 1.0
                        contractUploading = false
                        contractShowSuccess = true
                        contractMessage = "¡Archivo '\(fileName)' subido exitosamente!"
                    }
                }

                await fetchStats()
                
                // Notificar que se subió un archivo
                NotificationCenter.default.post(name: .fileUploaded, object: nil)
            } catch {
                await MainActor.run {
                    switch type {
                    case .document:
                        documentUploading = false
                    case .contract:
                        contractUploading = false
                        
                        
                        
                        
                    }
                    statsManager.errorMessage = "Error subiendo archivo: \(error.localizedDescription)"
                }
                print("Upload error: \(error)")
            }
            
            // Resetear el flag de control al final del proceso
            await MainActor.run {
                isProcessingUpload = false
            }
        }
    }

    func performUpload(fileURL: URL, token: String, endpoint: String) async throws {
        guard let uploadURL = URL(string: endpoint) else { throw APIError.invalidURL }
        let fileData = try Data(contentsOf: fileURL)
        let boundary = UUID().uuidString

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.timeoutInterval = 120.0

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("📤 Sending request to: \(endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
                        if !(200...299).contains(httpResponse.statusCode) {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Error response: \(responseBody)")
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // AGREGAR: Log de la respuesta exitosa
            if let responseBody = String(data: data, encoding: .utf8) {
                print("✅ Success response: \(responseBody.prefix(200))...")
            }
        }
    }
}// MARK: - COMPONENTES UI
struct StatMiniCard: View {
    var title: String
    var value: String
    var color: Color
    var icon: String
    var gradient: LinearGradient?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(gradient ?? LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(gradient ?? LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
    }
}

struct UploadCard: View {
    var title: String
    var subtitle: String
    var color: Color
    var icon: String
    @Binding var isUploading: Bool
    @Binding var progress: Double
    @Binding var fileName: String
    @Binding var showSuccess: Bool
    @Binding var uploadMessage: String
    var onPick: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            if isUploading {
                VStack(spacing: 12) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(color)
                        Text("Subiendo: \(fileName)")
                            .font(.caption)
                            .foregroundColor(color)
                        Spacer()
                    }
                }
                .padding(.top, 8)
            } else if showSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(uploadMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                Button(action: onPick) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Seleccionar Archivo")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isUploading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), 
                    lineWidth: 1
                )
        )
    }
}

struct MessageView: View {
    var text: String
    var color: Color
    var icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf,
            UTType.text,
            UTType.rtf,
            UTType.spreadsheet,
            UTType.presentation,
            .init("com.microsoft.word.doc")!,
            .init("org.openxmlformats.wordprocessingml.document")!
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .serverError(let code):
            return "Error del servidor: \(code)"
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(SessionManager())
}
