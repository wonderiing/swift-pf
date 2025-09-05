import SwiftUI
import GoogleSignIn

@main
struct proyecto_finalApp: App {
    @StateObject var session = SessionManager()
    
    init() {
        // Configurar Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("No se pudo cargar GoogleService-Info.plist")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

// Maneja sesión de usuario
class SessionManager: ObservableObject {
    @Published var token: String? = TokenManager.shared.currentToken
    @Published var userId: String? = nil // Agregar ID de usuario para forzar reconstrucción

    var isLoggedIn: Bool { token != nil }

    func login(token: String) {
        print("🔑 SessionManager.login called with token: \(token.prefix(20))...")
        self.token = token
        TokenManager.shared.currentToken = token
        // Generar un ID único para cada login para forzar reconstrucción
        self.userId = UUID().uuidString
        print("🔑 Token stored in SessionManager: \(self.token?.prefix(20) ?? "nil")...")
        print("🔑 Token stored in TokenManager: \(TokenManager.shared.currentToken?.prefix(20) ?? "nil")...")
    }

    func logout() {
        print("🚪 SessionManager.logout called")
        print("🚪 Token before logout: \(token?.prefix(20) ?? "nil")...")
        token = nil
        userId = nil
        TokenManager.shared.logout()
        print("🚪 Token after logout: \(token?.prefix(20) ?? "nil")...")
        print("🚪 TokenManager token after logout: \(TokenManager.shared.currentToken?.prefix(20) ?? "nil")...")
    }
}

struct RootView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            if session.isLoggedIn {
                ContentView()
                    .id(session.userId) // Usar userId para forzar reconstrucción completa
            } else {
                LoginView()
            }
        }
    }
}



