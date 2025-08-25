//
//  ContentView.swift
//  proyecto-final
//
//  Created by Carlos on 25/08/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo y título - quitar esto
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
                        // Aquí lógica extra
                    }
                    .font(.footnote)
                }

                // Botón de login
                Button("Iniciar Sesión") {
                    Task {
                        await login()
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
                }

                Text("o continúa con")
                    .foregroundColor(.gray)

                // Botones sociales
                Button(action: {
                    // Acción login Google
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
                // Footer
                NavigationLink(destination: RegisterView()) {
                    Text("¿No tienes una cuenta? Regístrate aquí")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }

            }
            .padding()
            .navigationDestination(isPresented: $isLoggedIn) {
                DashboardView()
            }
        }
    }

    // Función de login con POST
    func login() async {
        guard let url = URL(string: "https://tu-api.com/login") else { return }

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
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Decodificar JSON de la respuesta
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("Login correcto: \(json)")
                    await MainActor.run {
                        isLoggedIn = true
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Credenciales inválidas"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
            }
        }
    }
}

struct DashboardView: View {
    var body: some View {
        Text("Bienvenido al Dashboard 🎉")
            .font(.largeTitle)
            .padding()
    }
}

// Estilo de checkbox
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


#Preview {
    LoginView()
}
