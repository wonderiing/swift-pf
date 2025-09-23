import SwiftUI
import GoogleSignIn

struct RegisterView: View {
    @EnvironmentObject var session: SessionManager
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white, Color.white.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(spacing: 8) {
                                Text("AuditorIA")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                                Text("Crea tu cuenta")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Formulario
                        VStack(spacing: 20) {
                            // Campo de nombre completo
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nombre Completo")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("Tu nombre completo", text: $fullName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .autocapitalization(.words)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                                    
                            }
                            
                            // Campo de email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo Electrónico")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        Text("")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.horizontal, 16)
                                    }
                                    TextField("", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                    
                            }
                            
                            // Campo de contraseña
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contraseña")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                                    
                            }
                            
                            // Recordarme
                            HStack {
                                Button(action: { rememberMe.toggle() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.white)
                                        Text("Recordarme")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
                    .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    // Contenido principal
                    VStack(spacing: 24) {
                        // Botón de registro
                        Button(action: {
                            Task { await register() }
                        }) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18))
                                }
                                
                                Text(isLoading ? "Creando cuenta..." : "Crear Cuenta")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.7 : 1.0)
                        
                        // Mensaje de error
                        if let errorMessage = errorMessage {
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
                        
                        // Mensaje de éxito
                        if showSuccessMessage {
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("¡Usuario registrado exitosamente!")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                
                                Text("Por favor inicia sesión con tus credenciales")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                NavigationLink(destination: LoginView()) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Ir al Login")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            .padding(20)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("o continúa con")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        // Botones sociales
                        VStack(spacing: 12) {
                            Button(action: {
                                Task { await registerWithGoogle() }
                            }) {
                                HStack(spacing: 12) {
                                    Image("google")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Continuar con Google")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            
                            Button(action: {
                                // Acción registro GitHub
                            }) {
                                HStack(spacing: 12) {
                                    Image("github")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Continuar con GitHub")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        // Footer
                        HStack(spacing: 4) {
                            Text("¿Ya tienes una cuenta?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: LoginView()) {
                                Text("Inicia sesión aquí")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                }
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
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showSuccessMessage = false
        }
        
        print("🚀 Iniciando registro...")
        
        guard let url = URL(string: "http://localhost:3000/api/auth/register") else {
            await MainActor.run {
                isLoading = false
                errorMessage = "URL inválida"
            }
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
            await MainActor.run {
                isLoading = false
                errorMessage = "Error creando datos de registro"
            }
            return
        }

        do {
            print("📡 Enviando request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("✅ RegisterView: Status code 201 - User created successfully")
                
                // Debug: Mostrar la respuesta completa del servidor
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Server response: \(responseString)")
                }
                
                // El registro fue exitoso, mostrar mensaje de éxito
                await MainActor.run {
                    errorMessage = nil // Limpiar errores
                    showSuccessMessage = true // Mostrar mensaje de éxito
                    isLoading = false
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                // 🐛 DEBUG: Manejar otros status codes
                print("⚠️ RegisterView: Unexpected status code: \(httpResponse.statusCode)")
                
                // Mostrar mensaje de error del servidor si existe
                if let errorData = String(data: data, encoding: .utf8) {
                    print("💬 Server error message: \(errorData)")
                }
                
                // 🔧 CAMBIO: Usar la nueva función para extraer errores
                let userMessage = extractErrorMessage(from: data, statusCode: httpResponse.statusCode)
                
                await MainActor.run {
                    errorMessage = userMessage
                    isLoading = false
                }
            } else {
                print("❌ RegisterView: No HTTP response received")
                await MainActor.run {
                    errorMessage = "Error: No se recibió respuesta del servidor"
                    isLoading = false
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
                isLoading = false
            }
        }
    }
    
    // MARK: - Google Sign-In Registration
    func registerWithGoogle() async {
        // Verificar que Google Sign-In esté configurado
        guard GIDSignIn.sharedInstance.configuration != nil else {
            await MainActor.run {
                errorMessage = "Google Sign-In no está configurado correctamente"
            }
            return
        }
        
        guard let presentingViewController = await MainActor.run(body: {
            UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController
        }) else {
            await MainActor.run {
                errorMessage = "No se pudo encontrar el controlador de presentación"
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showSuccessMessage = false
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                await MainActor.run {
                    errorMessage = "No se pudo obtener el ID Token de Google"
                    isLoading = false
                }
                return
            }

            print("🔑 Google ID Token obtenido para registro: \(idToken.prefix(20))...")

            guard let url = URL(string: "http://localhost:3000/api/auth/google/mobile") else {
                await MainActor.run {
                    errorMessage = "URL del servidor inválida"
                    isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["idToken": idToken]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("🔍 Respuesta del servidor para registro: \(response)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Datos de respuesta: \(responseString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String {
                    print("🔑 Google registro exitoso, token: \(token.prefix(20))...")
                    await MainActor.run {
                        session.login(token: token)
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Error: respuesta inválida del servidor"
                        isLoading = false
                    }
                }
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                await MainActor.run {
                    errorMessage = "Error en registro con Google (Código: \(statusCode))"
                    isLoading = false
                }
            }
        } catch {
            print("❌ Google Sign-In error: \(error)")
            await MainActor.run {
                errorMessage = "Error de Google Sign-In: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(SessionManager())
}
