import SwiftUI
import Charts

struct SalesForecastView: View {
    let fileId: Int
    @StateObject private var viewModel = SalesForecastViewModel()
    @State private var selectedDays = 7
    @State private var showingDaysPicker = false
    
    let daysOptions = [3, 7, 14, 30]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con gradiente
                    headerView
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if let forecast = viewModel.forecast {
                        forecastContentView(forecast)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.05),
                        Color.green.opacity(0.03),
                        Color.orange.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Predicción de Ventas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generar") {
                        viewModel.fetchForecast(fileId: fileId, n_days: selectedDays)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔮 Predicción de Ventas")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Análisis predictivo basado en datos históricos")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Selector de días
            HStack {
                Text("Días a predecir:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Button(action: { showingDaysPicker = true }) {
                    HStack(spacing: 8) {
                        Text("\(selectedDays) días")
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showingDaysPicker) {
            daysPickerSheet
        }
    }
    
    // MARK: - Days Picker Sheet
    private var daysPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Selecciona el número de días a predecir")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(daysOptions, id: \.self) { days in
                    Button(action: {
                        selectedDays = days
                        showingDaysPicker = false
                    }) {
                        HStack {
                            Text("\(days) días")
                                .font(.subheadline)
                            Spacer()
                            if selectedDays == days {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedDays == days ? Color.green.opacity(0.1) : Color.clear)
                        .cornerRadius(10)
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Días de Predicción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showingDaysPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generando predicción...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2.bold())
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Genera una Predicción")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("Toca el botón 'Generar' para crear una predicción de ventas basada en los datos del archivo")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Forecast Content View
    private func forecastContentView(_ forecast: SalesForecastResponse) -> some View {
        VStack(spacing: 24) {
            // Resumen principal
            summaryCard(forecast.summary)
            
            // Métricas clave
            keyMetricsGrid(forecast.summary.key_metrics)
            
            // Gráfico de predicciones
            predictionsChart(forecast.predictions)
            
            // Lista detallada de predicciones
            predictionsList(forecast.predictions)
        }
    }
    
    // MARK: - Summary Card
    private func summaryCard(_ summary: ForecastSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 Resumen")
                    .font(.title2.bold())
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Período")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(summary.period)
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tendencia")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(summary.trend)
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ventas Promedio Diarias")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(Int(summary.avg_daily_sales).formatted())")
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Predicho")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(Int(summary.total_predicted_sales).formatted())")
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Key Metrics Grid
    private func keyMetricsGrid(_ metrics: [KeyMetric]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("📈 Métricas Clave")
                    .font(.title2.bold())
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(metrics, id: \.name) { metric in
                    metricCard(metric)
                }
            }
        }
    }
    
    // MARK: - Metric Card
    private func metricCard(_ metric: KeyMetric) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(metric.name)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(metric.value))")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                Text(metric.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(metric.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Predictions Chart
    private func predictionsChart(_ predictions: [Prediction]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 Gráfico de Predicciones")
                    .font(.title2.bold())
                Spacer()
            }
            
            // Gráfico simple con barras
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(predictions, id: \.date) { prediction in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(width: 30, height: max(20, CGFloat(prediction.predicted_sales / 1000)))
                                .cornerRadius(4)
                            
                            Text(prediction.day_of_week.prefix(3))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .padding()
                
                Text("Ventas Predichas por Día")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Predictions List
    private func predictionsList(_ predictions: [Prediction]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("📅 Predicciones Detalladas")
                    .font(.title2.bold())
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(predictions, id: \.date) { prediction in
                    predictionRow(prediction)
                }
            }
        }
    }
    
    // MARK: - Prediction Row
    private func predictionRow(_ prediction: Prediction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.day_of_week)
                    .font(.subheadline.bold())
                Text(formatDate(prediction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(prediction.predicted_sales).formatted())")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
                Text("ventas")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    SalesForecastView(fileId: 112)
}
