//
//  LoginView.swift
//  proyecto-final
//
//  Created by Carlos on 25/08/25.
//

import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header con gradiente
                    VStack(spacing: 24) {
                        // Logo y título
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
                                Text("Inicia Sesión")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Formulario
                        VStack(spacing: 20) {
                            // Campo de email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo Electrónico")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        Text("tu@email.com")
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.horizontal, 16)
                                    }
                                    TextField("", text: $email)
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
                                
                                SecureField("", text: $password, prompt: Text("••••••••").foregroundColor(.white.opacity(0.7)))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                            }
                            
                            // Recordarme y olvidé contraseña
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
                                
                                Button("¿Olvidaste tu contraseña?") {
                                    // Lógica extra
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
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
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    // Contenido principal
                    VStack(spacing: 24) {
                        // Botón de login
                        Button(action: {
                            Task { await login() }
                        }) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                }
                                
                                Text(isLoading ? "Iniciando sesión..." : "Iniciar Sesión")
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
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
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
                                Task { await loginWithGoogle() }
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
                            .disabled(isLoading)
                            
                            Button(action: {
                                // Acción login GitHub
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
                            Text("¿No tienes una cuenta?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: RegisterView()) {
                                Text("Regístrate aquí")
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

    // MARK: - Funciones de login
    func login() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: "http://localhost:3000/api/auth/login") else {
            await MainActor.run {
                isLoading = false
                errorMessage = "URL inválida"
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
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
                await MainActor.run {
                    errorMessage = "Credenciales inválidas"
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loginWithGoogle() async {
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
            
            if let responseString = String(data: data, encoding: .utf8) {
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String {
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
                    errorMessage = "Error en login con Google (Código: \(statusCode))"
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error de Google Sign-In: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}


// MARK: - Toggle personalizado
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                configuration.label
            }
        }
        .foregroundColor(.blue)
    }
}


