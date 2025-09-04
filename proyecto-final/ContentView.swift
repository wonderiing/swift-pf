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
                    Text("Inicia Sesión")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)

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
                    Button("¿Olvidaste tu contraseña?") {
                        // Lógica extra
                    }
                    .font(.footnote)
                }

                // Botón de login
                Button("Iniciar Sesión") {
                    Task { await login() }
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
                }

                Text("o continúa con")
                    .foregroundColor(.gray)

                Button(action: {
                    Task { await loginWithGoogle() }
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
                    // Acción login GitHub
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

                // Footer
                NavigationLink(destination: RegisterView()) {
                    Text("¿No tienes una cuenta? Regístrate aquí")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    // MARK: - Funciones de login
    func login() async {
        guard let url = URL(string: "http://localhost:3000/api/auth/login") else { return }

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
                    print("🔑 LoginView received token: \(token.prefix(20))...")
                    print("🔑 LoginView email: \(email)")
                    await MainActor.run { session.login(token: token) }
                } else {
                    print("❌ LoginView: Invalid response format")
                    await MainActor.run { errorMessage = "Error: respuesta inválida del servidor" }
                }
            } else {
                print("❌ LoginView: Invalid status code: \(response)")
                await MainActor.run { errorMessage = "Credenciales inválidas" }
            }
        } catch {
            print("❌ LoginView error: \(error)")
            await MainActor.run { errorMessage = "Error de conexión: \(error.localizedDescription)" }
        }
    }

    func loginWithGoogle() async {
        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else { return }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                await MainActor.run { errorMessage = "No se pudo obtener el ID Token de Google" }
                return
            }

            guard let url = URL(string: "http://localhost:3000/api/auth/google/mobile") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["idToken": idToken]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String {
                    await MainActor.run { session.login(token: token) }
                } else {
                    await MainActor.run { errorMessage = "Error: respuesta inválida del servidor" }
                }
            } else {
                await MainActor.run { errorMessage = "Error en login con Google" }
            }
        } catch {
            await MainActor.run { errorMessage = "Error de Google Sign-In: \(error.localizedDescription)" }
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

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(SessionManager())
}

