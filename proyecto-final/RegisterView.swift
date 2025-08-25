
import SwiftUI

struct RegisterView: View {
    @State private var name: String = ""
    @State private var username: String = ""
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

                TextField("Nombre completo", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)

                TextField("Nombre de usuario", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

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

    // Función de registro con POST
    func register() async {
        guard let url = URL(string: "https://tu-api.com/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": name,
            "username": username,
            "email": email,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Decodificar JSON de la respuesta
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("Registro correcto: \(json)")
                    await MainActor.run {
                        isRegistered = true
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Error en el registro"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    RegisterView()
}
