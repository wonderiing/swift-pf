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
            VStack(alignment: .leading, spacing: 16) {
                Text("📂 Archivos Recientes")
                    .font(.largeTitle)
                    .bold()
                
                // Buscador
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Buscar archivos...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filtro
                Picker("Tipo", selection: $selectedTipo) {
                    ForEach(tipos, id: \.self) { tipo in Text(tipo).tag(tipo) }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Lista de Archivos
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredArchivos) { archivo in
                            ArchivoCard(archivo: archivo)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear { viewModel.fetchArchivos() }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Card de archivo
struct ArchivoCard: View {
    let archivo: Archivo
    
    var color: Color {
        archivo.tipo.lowercased().contains("csv") || archivo.tipo.lowercased().contains("xlsx") ? .green : .blue
    }
    
    var icon: String {
        archivo.tipo.lowercased().contains("csv") || archivo.tipo.lowercased().contains("xlsx") ? "doc.text.fill" : "doc.richtext.fill"
    }
    
    var body: some View {
        NavigationLink(destination: FileDetail(archivo: archivo)) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
                    .background(color)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(archivo.nombre)
                        .font(.headline)
                    Text("Subido por \(archivo.subidoPor)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(archivo.tipo.uppercased())
                    .font(.caption)
                    .bold()
                    .padding(8)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    FileFinder()
}

