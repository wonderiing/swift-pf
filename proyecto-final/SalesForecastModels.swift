import Foundation

// MARK: - Modelos para Predicción de Ventas

struct SalesForecastRequest: Codable {
    let fileId: Int
    let level: String?
    let n_days: Int
    
    init(fileId: Int, level: String? = "weekly", n_days: Int = 7) {
        self.fileId = fileId
        self.level = level
        self.n_days = n_days
    }
}

struct SalesForecastResponse: Codable {
    let status: String
    let message: String
    let summary: ForecastSummary
    let predictions: [Prediction]
}

struct ForecastSummary: Codable {
    let period: String
    let trend: String
    let avg_daily_sales: Double
    let total_predicted_sales: Double
    let best_day: DayPrediction
    let worst_day: DayPrediction
    let key_metrics: [KeyMetric]
}

struct DayPrediction: Codable {
    let date: String
    let predicted_sales: Double
    let day_of_week: String
}

struct KeyMetric: Codable {
    let name: String
    let value: Double
    let unit: String
    let description: String
}

struct Prediction: Codable {
    let date: String
    let day_of_week: String
    let predicted_sales: Double
}

// MARK: - ViewModel para Predicción de Ventas
class SalesForecastViewModel: ObservableObject {
    @Published var forecast: SalesForecastResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchForecast(fileId: Int, n_days: Int = 7) {
        guard let url = URL(string: "http://localhost:3000/api/ai/forecast/") else {
            errorMessage = "URL inválida"
            return
        }
        
        let request = SalesForecastRequest(fileId: fileId, n_days: n_days)
        
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
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error de red: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No se recibieron datos"
                }
                return
            }
            
            do {
                let forecast = try JSONDecoder().decode(SalesForecastResponse.self, from: data)
                DispatchQueue.main.async {
                    self.forecast = forecast
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error decodificando respuesta: \(error.localizedDescription)"
                }
                print("❌ Error decodificando forecast:", error)
                if let raw = String(data: data, encoding: .utf8) {
                    print("📄 Respuesta cruda:", raw)
                }
            }
        }.resume()
    }
}
