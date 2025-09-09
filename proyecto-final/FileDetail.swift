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
    @StateObject private var notesViewModel = FileNotesViewModel()
    @State private var selectedTab = "Vista Previa"
    
    var body: some View {
        VStack(spacing: 0) {
            // Encabezado moderno con gradiente - Reducido el espaciado
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: archivo.tipo.lowercased().contains("csv") ? "doc.text.fill" :
                                archivo.tipo.lowercased().contains("pdf") ? "doc.richtext.fill" : "doc.plaintext.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                
                    VStack(alignment: .leading, spacing: 3) {
                        Text(archivo.nombre)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Text("Subido por \(archivo.subidoPor)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text(archivo.tipo.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Tabs modernos
                HStack(spacing: 0) {
                    ForEach(["Vista Previa", "Análisis IA", "Predicción", "Notas"], id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            VStack(spacing: 6) {
                                Text(tab)
                                    .font(.caption.bold())
                                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.white : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Contenido principal con padding
            ScrollView {
                VStack(spacing: 0) {
                    if selectedTab == "Vista Previa" {
                        previewView()
                    } else if selectedTab == "Análisis IA" {
                        analysisView()
                    } else if selectedTab == "Predicción" {
                        predictionView()
                    } else {
                        notesView()
                    }
                }
                .padding(.top, 16)
            }
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
        .navigationTitle("Detalles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchDetalle(for: archivo.id)
            viewModel.fetchPreview(for: archivo)
            notesViewModel.fetchAuditRecords(fileId: archivo.id)
            notesViewModel.loadExistingNotes(for: archivo.id)
        }
    }
    
    // MARK: - Vista previa
    @ViewBuilder
    private func previewView() -> some View {
        VStack(spacing: 20) {
            // Header de vista previa
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👁 Vista Previa")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text("Contenido del archivo \(archivo.tipo.uppercased())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Contenido según tipo de archivo
            switch archivo.tipo.lowercased() {
            case let t where t.contains("csv") || t.contains("xlsx"):
                csvPreviewView()
                
            case let t where t.contains("pdf"):
                pdfPreviewView()
                
            default:
                textPreviewView()
            }
        }
    }
    
    @ViewBuilder
    private func csvPreviewView() -> some View {
        VStack(spacing: 16) {
            if viewModel.tableData.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando datos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    let maxColumns = 6
                    let visibleColumns = min(viewModel.tableData.first?.count ?? 1, maxColumns)
                    
                    ScrollView([.horizontal, .vertical]) {
                    LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: visibleColumns),
                            spacing: 2
                    ) {
                        ForEach(0..<viewModel.tableData.count, id: \.self) { rowIndex in
                            ForEach(0..<visibleColumns, id: \.self) { colIndex in
                                if colIndex < viewModel.tableData[rowIndex].count {
                                    Text(viewModel.tableData[rowIndex][colIndex])
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(rowIndex == 0 ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    if let total = viewModel.tableData.first?.count, total > maxColumns {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Mostrando solo las primeras \(maxColumns) de \(total) columnas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private func pdfPreviewView() -> some View {
        VStack(spacing: 16) {
                if let url = viewModel.pdfURL {
                    PDFQuickLookView(url: url)
                    .frame(height: 500)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando PDF...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
    }
    
    @ViewBuilder
    private func textPreviewView() -> some View {
        VStack(spacing: 16) {
                if let preview = viewModel.previewContent {
                ScrollView {
                    Text(preview)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando preview...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
    }
    
    // MARK: - Análisis IA
    @ViewBuilder
    private func analysisView() -> some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Cargando análisis de IA...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else if let detalleValue = viewModel.detalle {
            VStack(alignment: .leading, spacing: 20) {
                // Header del análisis
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🤖 Análisis de IA")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Text("Analizado el \(formatDate(detalleValue.analyzedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Contenido del análisis
                VStack(alignment: .leading, spacing: 16) {
                    Text(detalleValue.aiResponse)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.horizontal, 20)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("No se encontró información del análisis")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        }
    }
    
    // MARK: - Predicción de Ventas
    @ViewBuilder
    private func predictionView() -> some View {
        VStack(spacing: 0) {
            // Botón para generar predicción
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔮 Predicción de Ventas")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Text("Genera predicciones basadas en datos históricos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                NavigationLink(destination: SalesForecastView(fileId: archivo.id)) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                        Text("Generar Predicción")
                            .font(.headline.bold())
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Notas y Estado
    @ViewBuilder
    private func notesView() -> some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📝 Notas y Estado")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text("Agrega notas y cambia el estado del archivo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Formulario de notas
            VStack(spacing: 20) {
                // Campo de notas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notas")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if notesViewModel.isLoadingNotes {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Cargando notas existentes...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(minHeight: 100)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        TextEditor(text: $notesViewModel.currentNotes)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Selector de estado
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estado")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(FileStatus.allCases, id: \.self) { status in
                            Button(action: { notesViewModel.selectedStatus = status }) {
                                HStack(spacing: 8) {
                                    Image(systemName: status.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(notesViewModel.selectedStatus == status ? .white : Color(status.color))
                                    
                                    Text(status.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundColor(notesViewModel.selectedStatus == status ? .white : .primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    notesViewModel.selectedStatus == status ?
                                    Color(status.color) : Color(.systemGray6)
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            notesViewModel.selectedStatus == status ?
                                            Color.clear : Color(status.color).opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Botón de envío
                Button(action: { notesViewModel.submitNotes(fileId: archivo.id) }) {
                    HStack(spacing: 12) {
                        if notesViewModel.isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                        }
                        
                        Text(notesViewModel.isSubmitting ? "Enviando..." : "Guardar Notas")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(notesViewModel.isSubmitting || notesViewModel.currentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(notesViewModel.isSubmitting || notesViewModel.currentNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                
                // Mensajes de estado
                if let errorMessage = notesViewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                if notesViewModel.showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notas guardadas exitosamente")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            notesViewModel.showSuccess = false
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            
            // Historial de notas
            if !notesViewModel.auditRecords.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("📋 Historial de Notas")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(notesViewModel.auditRecords) { record in
                            auditRecordCard(record)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Audit Record Card
    @ViewBuilder
    private func auditRecordCard(_ record: AuditRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: FileStatus(rawValue: record.status)?.icon ?? "circle.fill")
                        .foregroundColor(Color(FileStatus(rawValue: record.status)?.color ?? "gray"))
                    
                    Text(FileStatus(rawValue: record.status)?.displayName ?? record.status)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(formatDate(record.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Información del archivo
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(record.file.filename)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(record.file.type.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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


