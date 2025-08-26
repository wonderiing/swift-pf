import SwiftUI

struct RegisterView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isRegistered: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo y título
                VStack(spacing: 8) {
                    Image("doc2")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                    Text("AuditorIA")
                        .font(.title)
                        .bold()
                    Text("Registro")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)

                TextField("Nombre completo", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)


                TextField("Correo Electrónico", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Contraseña", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Toggle("Recordarme", isOn: $rememberMe)
                        .toggleStyle(CheckboxToggleStyle())
                    Spacer()
                }

                // Botón de registro
                Button("Registrarse") {
                    Task {
                        await register()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                }

                Text("o continúa con")
                    .foregroundColor(.gray)

                // Botones sociales
                Button(action: {
                    // Acción registro Google
                }) {
                    HStack {
                        Image("google")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Continuar con Google")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }

                Button(action: {
                
                }) {
                    HStack {
                        Image("github")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Continuar con GitHub")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $isRegistered) {
                DashboardView()
            }
        }
    }

    // 🔧 FUNCIÓN NUEVA: Extraer errores del servidor
    func extractErrorMessage(from data: Data, statusCode: Int) -> String {
        guard let responseString = String(data: data, encoding: .utf8),
              let jsonData = responseString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return "Error en el registro (Código: \(statusCode))"
        }
        
        // Caso 1: Array de mensajes (tu servidor)
        if let messages = json["message"] as? [String] {
            let errorList = messages.map { "• \($0)" }.joined(separator: "\n")
            return "Errores:\n\(errorList)"
        }
        
        // Caso 2: Mensaje único como string
        if let message = json["message"] as? String {
            return message
        }
        
        // Caso 3: Campo "error"
        if let error = json["error"] as? String {
            return error
        }
        
        // Fallback por código
        switch statusCode {
        case 400: return "Datos inválidos. Verifica los campos."
        case 409: return "El email ya está registrado"
        case 422: return "Datos no válidos. Verifica el formato."
        case 500: return "Error del servidor. Intenta más tarde."
        default: return "Error en el registro (Código: \(statusCode))"
        }
    }

    func register() async {
        print("🚀 Iniciando registro...")
        
        guard let url = URL(string: "http://localhost:3000/api/auth/register") else {
            return
        }
        print("✅ URL creada: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "password": password
        ]
        
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            // 🐛 DEBUG: Mostrar el JSON como string
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("📝 JSON enviado: \(jsonString)")
            }
            
        } catch {
            print("❌ Error creando JSON: \(error)")
            return
        }

        do {
            print("📡 Enviando request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 🐛 DEBUG: Mostrar respuesta completa
            if let httpResponse = response as? HTTPURLResponse {

            }
            
            // 🐛 DEBUG: Mostrar data recibida
            if let responseString = String(data: data, encoding: .utf8) {
            } else {

            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                
                
                // Decodificar JSON de la respuesta
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("✅ JSON parseado: \(json)")
                    await MainActor.run {
                        isRegistered = true
                        errorMessage = nil // Limpiar errores
                    }
                } else {
                    print("❌ Error parseando JSON de respuesta")
                    await MainActor.run {
                        errorMessage = "Error procesando respuesta del servidor"
                    }
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                // 🐛 DEBUG: Manejar otros status codes
                print("⚠️ Status Code inesperado: \(httpResponse.statusCode)")
                
                // Mostrar mensaje de error del servidor si existe
                if let errorData = String(data: data, encoding: .utf8) {
                    print("💬 Mensaje del servidor: \(errorData)")
                }
                
                // 🔧 CAMBIO: Usar la nueva función para extraer errores
                let userMessage = extractErrorMessage(from: data, statusCode: httpResponse.statusCode)
                
                await MainActor.run {
                    errorMessage = userMessage
                }
            }
        } catch {

        
            if let urlError = error as? URLError {
                print("   - Código URLError: \(urlError.code.rawValue)")
                switch urlError.code {
                case .notConnectedToInternet:
                    print("   - Sin conexión a internet")
                case .cannotConnectToHost:
                    print("   - No se puede conectar al servidor")
                case .timedOut:
                    print("   - Timeout de conexión")
                default:
                    print("   - Otro error de URL")
                }
            }
            
            await MainActor.run {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
            }
        }
            }
}

#Preview {
    RegisterView()
}
