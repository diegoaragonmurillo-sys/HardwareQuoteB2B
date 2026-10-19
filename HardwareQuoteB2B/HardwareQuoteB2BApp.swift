import SwiftUI
import SwiftData
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
            LoginViewControllerWrapper()
                .ignoresSafeArea()
                .modelContainer(for: [Cotizacion.self, Componente.self])
        }
    }
}

// Puente UIViewControllerRepresentable para LoginViewController (UIKit)
struct LoginViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LoginViewController {
        return LoginViewController()
    }
    
    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {}
}
