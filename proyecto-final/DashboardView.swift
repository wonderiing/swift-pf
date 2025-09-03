import SwiftUI
import UniformTypeIdentifiers

// ContentView.swift
struct ContentView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            TabView {
                DashboardView()
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        session.logout()
                    }
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
}


struct DashboardView: View {
    @EnvironmentObject var session: SessionManager

    // Estados del dashboard
    @State private var totalFiles = 0
    @State private var completedAudits = 0
    @State private var pendingFiles = 0
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Upload states
    enum PickerType: Identifiable {
        case document, contract
        var id: Int { hashValue }
    }
    @State private var activePicker: PickerType? = nil
    @State private var isUploading = false
    @State private var uploadProgress = 0.0
    @State private var selectedFileName = ""
    @State private var showUploadSuccess = false
    @State private var uploadMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // HEADER
                VStack(alignment: .leading, spacing: 8) {
                    Text("👋 Bienvenido")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tu Dashboard")
                        .font(.largeTitle.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // STATS
                if isLoading {
                    ProgressView("Cargando estadísticas…")
                        .padding()
                } else {
                    HStack(spacing: 16) {
                        StatMiniCard(title: "Totales", value: "\(totalFiles)", color: .blue, icon: "doc.on.doc")
                        StatMiniCard(title: "Completadas", value: "\(completedAudits)", color: .green, icon: "checkmark.circle")
                        StatMiniCard(title: "Pendientes", value: "\(pendingFiles)", color: .orange, icon: "clock")
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
                        isUploading: $isUploading,
                        progress: $uploadProgress,
                        fileName: $selectedFileName,
                        showSuccess: $showUploadSuccess,
                        uploadMessage: $uploadMessage,
                        onPick: { activePicker = .document }
                    )

                    UploadCard(
                        title: "Subir Contrato",
                        subtitle: "Envía documentos legales al sistema",
                        color: .purple,
                        icon: "doc.text.fill",
                        isUploading: $isUploading,
                        progress: $uploadProgress,
                        fileName: $selectedFileName,
                        showSuccess: $showUploadSuccess,
                        uploadMessage: $uploadMessage,
                        onPick: { activePicker = .contract }
                    )
                }
                .padding(.horizontal)

                // MENSAJES
                if let errorMessage = errorMessage {
                    MessageView(text: errorMessage, color: .red, icon: "exclamationmark.triangle.fill")
                }

                if showUploadSuccess {
                    MessageView(text: uploadMessage, color: .green, icon: "checkmark.circle.fill")
                }

                Spacer()
            }
            .padding(.top)
        }
        // iOS 17 style onChange
        .onChange(of: session.token) { oldValue, newValue in
            if newValue == nil {
                resetDashboardState()
            } else {
                Task { await fetchStats() }
            }
        }
        .refreshable { await fetchStats() }
        // Sheet único para uploads
        .sheet(item: $activePicker) { picker in
            DocumentPicker { url in
                switch picker {
                case .document:
                    uploadFile(from: url, to: "http://127.0.0.1:3000/api/processing-pipeline-module/data")
                case .contract:
                    uploadFile(from: url, to: "http://127.0.0.1:3000/api/processing-pipeline-module/contract")
                }
            }
        }
    }

    // MARK: - Funciones de datos
    func fetchStats() async {
        guard let token = session.token else {
            isLoading = false
            resetDashboardState()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await fetchFiles(token: token)
            try await fetchAudits(token: token)
            isLoading = false
        } catch {
            isLoading = false
            print("Error fetchStats: \(error)")  // <-- print en consola
            errorMessage = "Error cargando datos: \(error.localizedDescription)"
        }
    }

    func fetchFiles(token: String) async throws {
        guard let url = URL(string: "http://127.0.0.1:3000/api/files?limit=10") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let respBody = String(data: data, encoding: .utf8) ?? "No body"
            print("Error fetchFiles statusCode: \(httpResponse.statusCode), body: \(respBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            await MainActor.run {
                totalFiles = json.count
                updatePendingFiles()
            }
        }
    }

    func fetchAudits(token: String) async throws {
        guard let url = URL(string: "http://127.0.0.1:3000/api/audit-record/user?limit=5") else { return }
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
                completedAudits = json.count
                updatePendingFiles()
            }
        }
    }

    func updatePendingFiles() {
        pendingFiles = max(totalFiles - completedAudits, 0)
    }

    func resetDashboardState() {
        totalFiles = 0
        completedAudits = 0
        pendingFiles = 0
        isUploading = false
        uploadProgress = 0
        selectedFileName = ""
        showUploadSuccess = false
        uploadMessage = ""
        errorMessage = nil
    }

    // MARK: - Upload
    func uploadFile(from url: URL, to endpoint: String) {
        guard let token = session.token else {
            errorMessage = "No hay token de autenticación"
            return
        }

        selectedFileName = url.lastPathComponent
        isUploading = true
        showUploadSuccess = false
        errorMessage = nil
        uploadProgress = 0.0

        Task {
            do {
                for i in 1...3 {
                    await MainActor.run { uploadProgress = Double(i)/4.0 }
                    try await Task.sleep(nanoseconds: 500_000_000)
                }

                try await performUpload(fileURL: url, token: token, endpoint: endpoint)

                await MainActor.run {
                    uploadProgress = 1.0
                    isUploading = false
                    showUploadSuccess = true
                    uploadMessage = "¡Archivo '\(selectedFileName)' subido exitosamente!"
                }

                await fetchStats()
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Error subiendo archivo: \(error.localizedDescription)"
                }
                print("Upload error: \(error)")
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

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...201).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}// MARK: - COMPONENTES UI
struct StatMiniCard: View {
    var title: String
    var value: String
    var color: Color
    var icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("Subiendo: \(fileName)")
                        .font(.caption)
                        .foregroundColor(color)
                }
                .padding(.top, 8)
            } else {
                Button(action: onPick) {
                    Text("Seleccionar Archivo")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(color)
                        .cornerRadius(10)
                }
                .disabled(isUploading)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
    }
}

struct MessageView: View {
    var text: String
    var color: Color
    var icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(10)
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
