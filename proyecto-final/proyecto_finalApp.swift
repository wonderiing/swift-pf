import SwiftUI

@main
struct proyecto_finalApp: App {
    @StateObject var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}

// Maneja sesión de usuario
class SessionManager: ObservableObject {
    @Published var token: String? = TokenManager.shared.currentToken

    var isLoggedIn: Bool { token != nil }

    func login(token: String) {
        self.token = token
        TokenManager.shared.currentToken = token
    }

    func logout() {
        token = nil
        TokenManager.shared.currentToken = nil
    }
}

struct RootView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            if session.isLoggedIn {
                ContentView()
                    .id(session.token) // clave: esto fuerza que SwiftUI lo reconstruya
            } else {
                LoginView()
            }
        }
    }
}



