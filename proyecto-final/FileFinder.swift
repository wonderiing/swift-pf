import SwiftUI

// MARK: - Modelo
struct Archivo: Identifiable, Decodable {
    let id: Int
    let nombre: String
    let tipo: String
    let subidoPor: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre = "filename"
        case tipo = "type"
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
        let userContainer = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        subidoPor = try userContainer.decode(String.self, forKey: .fullName)
    }
}

// MARK: - ViewModel
class ArchivoViewModel: ObservableObject {
    @Published var archivos: [Archivo] = []
    
    func fetchArchivos() {
        guard let url = URL(string: "http://localhost:3000/api/files/user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No se encontró token en Keychain")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error en fetchArchivos:", error)
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode([Archivo].self, from: data)
                DispatchQueue.main.async { self.archivos = decoded }
            } catch {
                print("❌ Error al decodificar archivos:", error)
                if let raw = String(data: data, encoding: .utf8) { print("📄 Respuesta cruda:", raw) }
            }
        }.resume()
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
                // Header con gradiente
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
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
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16))
                        
                        TextField("Buscar archivos...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accentColor(.white)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                    
                    // Filtro moderno
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tipos, id: \.self) { tipo in
                                Button(action: { selectedTipo = tipo }) {
                                    Text(tipo)
                                        .font(.subheadline.bold())
                                        .foregroundColor(selectedTipo == tipo ? .blue : .white.opacity(0.8))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTipo == tipo ? 
                                            Color.white : Color.white.opacity(0.2)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Lista de Archivos
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredArchivos.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(filteredArchivos) { archivo in
                                ArchivoCard(archivo: archivo)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.05),
                            Color.blue.opacity(0.02),
                            Color.purple.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .onAppear { viewModel.fetchArchivos() }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No hay archivos")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Sube tu primer archivo desde el Dashboard" : 
                     "No se encontraron archivos con '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Card de archivo
struct ArchivoCard: View {
    let archivo: Archivo
    
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
        NavigationLink(destination: FileDetail(archivo: archivo)) {
            HStack(spacing: 16) {
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
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Información del archivo
                VStack(alignment: .leading, spacing: 6) {
                    Text(archivo.nombre)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(archivo.subidoPor)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        
                        Text(archivo.tipo.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(color)
                    }
                }
                
                Spacer()
                
                // Indicador de acción
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text("Ver")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
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
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
#Preview {
    FileFinder()
}

