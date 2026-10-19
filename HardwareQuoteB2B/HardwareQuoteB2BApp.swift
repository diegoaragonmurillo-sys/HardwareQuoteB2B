import SwiftUI
import FirebaseCore

// Creamos el delegado nativo para arrancar Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct HardwareQuoteB2BApp: App {
    // Conectamos el delegado a la estructura de SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            // 1. REEMPLAZAMOS QuoteBuilderView() POR EL LOGIN
            LoginViewControllerWrapper()
                .ignoresSafeArea() // Hace que el diseño ocupe toda la pantalla de borde a borde
        }
    }
}

// 2. AÑADIMOS EL PUENTE AL FINAL DEL ARCHIVO
// Esta estructura convierte tu LoginViewController (UIKit) en una vista que SwiftUI puede renderizar
struct LoginViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LoginViewController {
        return LoginViewController()
    }
    
    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
        // Se deja vacío porque la vista no necesita actualizarse desde SwiftUI
    }
}
