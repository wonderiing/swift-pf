import SwiftUI
import QuickLook

// MARK: - Modelo
struct ArchivoDetalle: Decodable {
    let id: Int
    let textExtraction: Int
    let aiResponse: String
    let analyzedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case textExtraction = "text_extraction"
        case aiResponse = "ai_response"
        case analyzedAt = "analyzed_at"
    }
}

// MARK: - ViewModel
class FileDetailViewModel: ObservableObject {
    @Published var detalle: ArchivoDetalle?
    @Published var previewContent: String? = nil
    @Published var tableData: [[String]] = []
    @Published var pdfURL: URL? = nil
    @Published var isLoading = false
    
    func fetchDetalle(for id: Int) {
        guard let url = URL(string: "http://localhost:3000/api/ai/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        isLoading = true
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async { self.isLoading = false }
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(ArchivoDetalle.self, from: data)
                    DispatchQueue.main.async { self.detalle = decoded }
                } catch { print("❌ Error decodificando detalle:", error) }
            }
        }.resume()
    }
    
    func fetchPreview(for archivo: Archivo) {
        guard let url = URL(string: "http://localhost:3000/api/files/see-file/\(archivo.nombre)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    switch archivo.tipo.lowercased() {
                    case let t where t.contains("csv") || t.contains("xlsx"):
                        if let text = String(data: data, encoding: .utf8) {
                            self.previewContent = text
                            self.tableData = text.components(separatedBy: "\n")
                                .map { $0.components(separatedBy: ",") }
                        }
                    case let t where t.contains("pdf"):
                        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(archivo.nombre)
                        try? data.write(to: tmpURL)
                        self.pdfURL = tmpURL
                    default:
                        self.previewContent = String(data: data, encoding: .utf8) ?? "No se pudo cargar preview."
                    }
                }
            } else {
                DispatchQueue.main.async { self.previewContent = "No se pudo cargar vista previa." }
            }
        }.resume()
    }
}

// MARK: - Vista
struct FileDetail: View {
    let archivo: Archivo
    @StateObject private var viewModel = FileDetailViewModel()
    @State private var selectedTab = "Vista Previa"
    
    var body: some View {
        VStack {
            // Encabezado
            HStack {
                Image(systemName: archivo.tipo.lowercased().contains("csv") ? "doc.text.fill" :
                        archivo.tipo.lowercased().contains("pdf") ? "doc.richtext.fill" : "doc.plaintext.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                
                VStack(alignment: .leading) {
                    Text(archivo.nombre)
                        .font(.title3)
                        .bold()
                    Text("Subido por \(archivo.subidoPor)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Tabs
            Picker("", selection: $selectedTab) {
                Text("Vista Previa").tag("Vista Previa")
                Text("Análisis IA").tag("Análisis IA")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Divider()
            
            if selectedTab == "Vista Previa" {
                previewView()
            } else {
                analysisView()
            }
            
            Spacer()
        }
        .navigationTitle("Detalles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchDetalle(for: archivo.id)
            viewModel.fetchPreview(for: archivo)
        }
    }
    
    // MARK: - Vista previa
    @ViewBuilder
    private func previewView() -> some View {
        ScrollView([.vertical]) {
            switch archivo.tipo.lowercased() {
            case let t where t.contains("csv") || t.contains("xlsx"):
                VStack(alignment: .leading, spacing: 8) {
                    let maxColumns = 6
                    let visibleColumns = min(viewModel.tableData.first?.count ?? 1, maxColumns)
                    
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: visibleColumns),
                        spacing: 4
                    ) {
                        ForEach(0..<viewModel.tableData.count, id: \.self) { rowIndex in
                            ForEach(0..<visibleColumns, id: \.self) { colIndex in
                                if colIndex < viewModel.tableData[rowIndex].count {
                                    Text(viewModel.tableData[rowIndex][colIndex])
                                        .font(.system(.footnote, design: .monospaced))
                                        .padding(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    if let total = viewModel.tableData.first?.count, total > maxColumns {
                        Text("⚠️ Mostrando solo las primeras \(maxColumns) de \(total) columnas")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
                
            case let t where t.contains("pdf"):
                if let url = viewModel.pdfURL {
                    PDFQuickLookView(url: url)
                        .frame(height: 400)
                        .cornerRadius(12)
                        .padding()
                } else {
                    ProgressView("Cargando PDF...")
                        .padding()
                }
                
            default:
                if let preview = viewModel.previewContent {
                    Text(preview)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                } else {
                    ProgressView("Cargando preview...")
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Análisis IA
    @ViewBuilder
    private func analysisView() -> some View {
        if viewModel.isLoading {
            ProgressView("Cargando análisis de IA...")
                .padding()
        } else if let detalleValue = viewModel.detalle {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("📊 Análisis de IA")
                        .font(.title2)
                        .bold()
                    
                    Text(detalleValue.aiResponse)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(4)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Text("⏱ Analizado el \(formatDate(detalleValue.analyzedAt))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        } else {
            Text("No se encontró información del análisis.")
                .foregroundColor(.gray)
                .padding()
        }
    }
    
    // Formatear fecha ISO
    private func formatDate(_ isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: isoDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return isoDate
    }
}

// MARK: - QuickLook PDF
struct PDFQuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: PDFQuickLookView
        init(_ parent: PDFQuickLookView) { self.parent = parent }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.url as QLPreviewItem
        }
    }
}

