import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
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
    }
}

struct DashboardView: View {
    // Estados
    @State private var totalFiles = 0
    @State private var completedAudits = 0
    @State private var pendingFiles = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Upload states
    @State private var showingDocumentPicker = false
    @State private var isUploading = false
    @State private var uploadProgress = 0.0
    @State private var selectedFileName = ""
    @State private var showUploadSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // HEADER con gradiente
                    ZStack(alignment: .leading) {
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                            .frame(height: 180)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bienvenido 👋")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Tu Dashboard")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    
                    // STATS en tarjetas verticales (DINÁMICAS)
                    if isLoading {
                        VStack(spacing: 20) {
                            ForEach(0..<3, id: \.self) { _ in
                                LoadingStatCard()
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 20) {
                            StatVerticalCard(title: "Archivos Totales",
                                             value: "\(totalFiles)",
                                             color: .blue,
                                             icon: "doc.on.doc")
                            
                            StatVerticalCard(title: "Auditorías Completadas",
                                             value: "\(completedAudits)",
                                             color: .green,
                                             icon: "checkmark.circle")
                            
                            StatVerticalCard(title: "Pendientes de Revisión",
                                             value: "\(pendingFiles)",
                                             color: .yellow,
                                             icon: "clock")
                        }
                        .padding(.horizontal)
                    }
                    
                    
                    // SECCIÓN DE UPLOAD
                    VStack(spacing: 16) {
                        Text("Subir Documento")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.05))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 12) {
                                    if isUploading {
                                        // Estado de subida
                                        VStack(spacing: 16) {
                                            ProgressView()
                                                .scaleEffect(1.5)
                                            Text("Subiendo: \(selectedFileName)")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                            ProgressView(value: uploadProgress, total: 1.0)
                                                .progressViewStyle(LinearProgressViewStyle())
                                                .padding(.horizontal, 40)
                                        }
                                    } else {
                                        // Estado normal
                                        Image(systemName: "arrow.up.doc.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 8)
                                        
                                        Text("Haz clic para seleccionar tu archivo")
                                            .font(.subheadline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 20)
                                        
                                        Button(action: {
                                            showingDocumentPicker = true
                                        }) {
                                            Text("Seleccionar Archivo")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(Color.blue)
                                                .cornerRadius(12)
                                                .shadow(radius: 3)
                                        }
                                        .padding(.horizontal, 40)
                                        .disabled(isUploading)
                                    }
                                }
                            )
                            .padding(.horizontal)
                    }
                    
                    // Mensaje de error
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Mensaje de éxito
                    if showUploadSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("¡Archivo subido exitosamente!")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    uploadFile(from: url)
                }
            }
            .onAppear {
                loadDashboardData()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Funciones
    
    func loadDashboardData() {
        Task {
            await fetchStats()
        }
    }
    
    @MainActor
    func refreshData() async {
        isLoading = true
        await fetchStats()
    }
    
    func fetchStats() async {
        isLoading = true
        errorMessage = nil
        
        guard let token = TokenManager.shared.currentToken else {
            await MainActor.run {
                errorMessage = "No hay token de autenticación"
                isLoading = false
            }
            return
        }
        
        do {
            // ✅ Aquí deben ir con try await
            try await fetchFiles(token: token)
            try await fetchAudits(token: token)
            
            await MainActor.run {
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Error cargando datos: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    
    func fetchFiles(token: String) async throws {
        guard let url = URL(string: "http://localhost:3000/api/files?limit=10") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError(0)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            await MainActor.run {
                totalFiles = json.count
                pendingFiles = totalFiles - completedAudits
            }
        }
    }
    
    func fetchAudits(token: String) async throws {
        guard let url = URL(string: "http://localhost:3000/api/audit-record/user?limit=5") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError(0)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            await MainActor.run {
                completedAudits = json.count
                pendingFiles = totalFiles - completedAudits
            }
        }
    }
    
    func uploadFile(from url: URL) {
        guard let token = TokenManager.shared.currentToken else {
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
                // Simular progreso
                for i in 1...3 {
                    await MainActor.run {
                        uploadProgress = Double(i) / 4.0
                    }
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                }
                
                try await performUpload(fileURL: url, token: token)
                
                await MainActor.run {
                    uploadProgress = 1.0
                    isUploading = false
                    showUploadSuccess = true
                    
                    // Ocultar mensaje de éxito después de 3 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showUploadSuccess = false
                    }
                }
                
                // Recargar stats
                await fetchStats()
                
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Error subiendo archivo: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func performUpload(fileURL: URL, token: String) async throws {
        guard let uploadURL = URL(string: "http://localhost:3000/api/processing-pipeline-module") else {
            throw APIError.invalidURL
        }
        
        // Leer el archivo
        let fileData = try Data(contentsOf: fileURL)
        
        // Crear multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Agregar archivo
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
    }
}

// MARK: - Loading State Card
struct LoadingStatCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 24)
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
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

/// Tarjeta vertical para stats
struct StatVerticalCard: View {
    var title: String
    var value: String
    var color: Color
    var icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
    }
}

// MARK: - Error Types
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

// Suponiendo que FileFinder está definido en otro archivo del proyecto
// Si quieres un placeholder para pruebas, aquí tienes uno simple:
// struct FileFinder: View {
//     var body: some View {
//         Text("FileFinder View")
//             .font(.largeTitle)
//             .padding()
//     }
// }

#Preview {
    ContentView()
}

