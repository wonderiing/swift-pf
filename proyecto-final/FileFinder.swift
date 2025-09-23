import SwiftUI

// MARK: - Modelo
struct Archivo: Identifiable, Decodable {
    let id: Int
    let nombre: String
    let tipo: String
    let subidoPor: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre = "filename"
        case tipo = "type"
        case isActive = "is_active"
        case user
    }
    
    enum UserKeys: String, CodingKey {
        case fullName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        nombre = try container.decode(String.self, forKey: .nombre)
        tipo = try container.decode(String.self, forKey: .tipo)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        let userContainer = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        subidoPor = try userContainer.decode(String.self, forKey: .fullName)
    }
}

// MARK: - ViewModel
class ArchivoViewModel: ObservableObject {
    @Published var archivos: [Archivo] = []
    @Published var isLoading = false
    @Published var hasMoreFiles = true
    @Published var currentOffset = 0
    private let pageSize = 10
    
    func fetchArchivos(reset: Bool = false) {
        if reset {
            currentOffset = 0
            archivos = []
            hasMoreFiles = true
        }
        
        guard !isLoading && hasMoreFiles else { return }
        
        isLoading = true
        print("🔄 FileFinder: Iniciando fetchArchivos offset \(currentOffset)...")
        
        // Construir URL con parámetros condicionales
        var urlString = "http://localhost:3000/api/files/user?limit=\(pageSize)"
        if currentOffset > 0 {
            urlString += "&offset=\(currentOffset)"
        }
        
        guard let url = URL(string: urlString) else { 
            print("❌ FileFinder: URL inválida")
            isLoading = false
            return 
        }
        print("🔍 FileFinder: URL de consulta: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 FileFinder: Token encontrado: \(token.prefix(10))...")
        } else {
            print("⚠️ FileFinder: No se encontró token en Keychain")
            isLoading = false
            return
        }
        
        print("📡 FileFinder: Enviando request a: \(url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("❌ FileFinder: Error en fetchArchivos:", error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 FileFinder: Status code: \(httpResponse.statusCode)")
                
                // Manejar errores del servidor
                if !(200...299).contains(httpResponse.statusCode) {
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("❌ FileFinder: Error del servidor: \(errorMessage)")
                    }
                    return
                }
            }
            
            guard let data = data else { 
                print("❌ FileFinder: No se recibieron datos")
                return 
            }
            
            print("📄 FileFinder: Datos recibidos (\(data.count) bytes)")
            if let raw = String(data: data, encoding: .utf8) { 
                print("📄 FileFinder: Respuesta cruda: \(raw)")
            }
            
            do {
                let decoded = try JSONDecoder().decode([Archivo].self, from: data)
                print("✅ FileFinder: Decodificación exitosa. Archivos encontrados en offset \(self.currentOffset): \(decoded.count)")
                
                // Filtrar solo archivos activos
                let activeFiles = decoded.filter { $0.isActive }
                print("✅ FileFinder: Archivos activos en offset \(self.currentOffset): \(activeFiles.count) de \(decoded.count)")
                
                DispatchQueue.main.async { 
                    if self.currentOffset == 0 {
                        // Primera carga: reemplazar lista
                        self.archivos = activeFiles
                    } else {
                        // Cargas siguientes: agregar a la lista
                        self.archivos.append(contentsOf: activeFiles)
                    }
                    
                    // Verificar si hay más archivos
                    self.hasMoreFiles = decoded.count == self.pageSize
                    self.currentOffset += self.pageSize
                    self.isLoading = false
                    
                    print("🔄 FileFinder: Lista actualizada en UI con \(self.archivos.count) archivos activos totales")
                    print("🔄 FileFinder: ¿Hay más archivos?: \(self.hasMoreFiles)")
                    print("🔄 FileFinder: Próximo offset: \(self.currentOffset)")
                }
            } catch {
                print("❌ FileFinder: Error al decodificar archivos:", error)
                if let raw = String(data: data, encoding: .utf8) { 
                    print("📄 FileFinder: Respuesta cruda para debug:", raw) 
                }
            }
        }.resume()
    }
    
    func loadMoreFiles() {
        fetchArchivos()
    }
}

// MARK: - Vista
struct FileFinder: View {
    @StateObject private var viewModel = ArchivoViewModel()
    @State private var searchText = ""
    @State private var selectedTipo = "Todos los tipos"
    
    let tipos = ["Todos los tipos", ".csv", ".xlsx", ".pdf"]
    
    var filteredArchivos: [Archivo] {
        viewModel.archivos.filter {
            (selectedTipo == "Todos los tipos" || $0.tipo.lowercased() == selectedTipo.lowercased())
            && (searchText.isEmpty || $0.nombre.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con gradiente - Más grande
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("📂 Archivos")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text("Gestiona tus archivos y documentos")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "folder.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Buscador moderno
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 14))
                        
                        TextField("Buscar archivos...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .font(.subheadline)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    
                    // Filtro moderno
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tipos, id: \.self) { tipo in
                                Button(action: { selectedTipo = tipo }) {
                                    Text(tipo)
                                        .font(.caption.bold())
                                        .foregroundColor(selectedTipo == tipo ? .blue : .white.opacity(0.8))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedTipo == tipo ? 
                                            Color.white : Color.white.opacity(0.2)
                                        )
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Lista de Archivos
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredArchivos.isEmpty && !viewModel.isLoading {
                            emptyStateView
                        } else {
                            ForEach(filteredArchivos) { archivo in
                                ArchivoCard(archivo: archivo, viewModel: viewModel)
                                    .onAppear {
                                        // Cargar más archivos cuando se acerca al final
                                        if archivo.id == filteredArchivos.last?.id && viewModel.hasMoreFiles && !viewModel.isLoading {
                                            print("🔄 FileFinder: Cargando más archivos...")
                                            viewModel.loadMoreFiles()
                                        }
                                    }
                            }
                            
                            // Indicador de carga al final
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Cargando más archivos...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                            }
                            
                            // Mensaje cuando no hay más archivos
                            if !viewModel.hasMoreFiles && !filteredArchivos.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Todos los archivos cargados")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
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
            }
            .onAppear { 
                print("🔄 FileFinder: Vista apareció. Archivos actuales: \(viewModel.archivos.count)")
                viewModel.fetchArchivos(reset: true) 
            }
            .onReceive(NotificationCenter.default.publisher(for: .fileUploaded)) { _ in
                print("📢 FileFinder: Notificación de archivo subido recibida")
                viewModel.fetchArchivos(reset: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .fileDeleted)) { _ in
                print("📢 FileFinder: Notificación de archivo borrado recibida")
                viewModel.fetchArchivos(reset: true)
            }
            .refreshable {
                print("🔄 FileFinder: Pull to refresh activado")
                viewModel.fetchArchivos(reset: true)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 6) {
                Text("No hay archivos")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Sube tu primer archivo desde el Dashboard" : 
                     "No se encontraron archivos con '\(searchText)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Card de archivo
struct ArchivoCard: View {
    let archivo: Archivo
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @ObservedObject var viewModel: ArchivoViewModel
    
    var color: Color {
        switch archivo.tipo.lowercased() {
        case let t where t.contains("csv") || t.contains("xlsx"):
            return .green
        case let t where t.contains("pdf"):
            return .red
        case let t where t.contains("doc") || t.contains("txt"):
            return .blue
        default:
            return .purple
        }
    }
    
    var icon: String {
        switch archivo.tipo.lowercased() {
        case let t where t.contains("csv") || t.contains("xlsx"):
            return "tablecells.fill"
        case let t where t.contains("pdf"):
            return "doc.richtext.fill"
        case let t where t.contains("doc") || t.contains("txt"):
            return "doc.text.fill"
        default:
            return "doc.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Navegación al detalle
            NavigationLink(destination: FileDetail(archivo: archivo)) {
                HStack(spacing: 12) {
                    // Icono con gradiente
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Información del archivo
                    VStack(alignment: .leading, spacing: 4) {
                        Text(archivo.nombre)
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(archivo.subidoPor)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                            
                            Text(archivo.tipo.uppercased())
                                .font(.caption2.bold())
                                .foregroundColor(color)
                        }
                    }
                    
                    Spacer()
                    
                    // Indicador de acción
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Botón de borrar
            Button(action: { showingDeleteAlert = true }) {
                VStack(spacing: 2) {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Text("Borrar")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDeleting)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.2), color.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .alert("¿Borrar archivo?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Borrar", role: .destructive) {
                deleteFile()
            }
        } message: {
            Text("¿Estás seguro de que quieres borrar '\(archivo.nombre)'? Esta acción no se puede deshacer.")
        }
    }
    
    private func deleteFile() {
        isDeleting = true
        
        guard let url = URL(string: "http://localhost:3000/api/files/\(archivo.id)") else {
            isDeleting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                self.isDeleting = false
                
                if let error = error {
                    print("❌ Error borrando archivo:", error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                        // Éxito - recargar la lista de archivos
                        print("🔄 FileFinder: Recargando lista de archivos después del borrado...")
                        self.viewModel.fetchArchivos()
                        
                        // Notificar que se borró un archivo para actualizar Dashboard
                        print("📢 FileFinder: Enviando notificación de archivo borrado...")
                        NotificationCenter.default.post(name: .fileDeleted, object: nil)
                        print("📢 FileFinder: Notificación enviada exitosamente")
                    } else {
                        print("❌ Error del servidor: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
}


// MARK: - Preview
#Preview {
    FileFinder()
}

