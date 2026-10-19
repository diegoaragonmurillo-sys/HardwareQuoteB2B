//
//  LoginViewController.swift
//  HardwareQuoteB2B
//
//  Created as part of the B2B Hardware Quoting Platform.
//  Specialist: iOS Architecture & UIKit-SwiftUI Interoperability.
//

import UIKit
import SwiftUI
import SwiftData

#if canImport(FirebaseAuth)
import FirebaseAuth
#else
// MARK: - Firebase Auth Stub (Fallback de compilación antes de vincular SPM)
/// Permite compilar y ejecutar pruebas de interfaz incluso si Firebase todavía no ha sido enlazado vía SPM.
public enum AuthErrorCode {
    public static let wrongPassword = 17009
    public static let userNotFound = 17011
    public static let invalidEmail = 17008
    public static let emailAlreadyInUse = 17007
    public static let weakPassword = 17026
}

public final class User {
    public let uid: String = UUID().uuidString
    public let email: String?
    init(email: String?) { self.email = email }
}

public final class AuthDataResult {
    public let user: User
    init(user: User) { self.user = user }
}

public final class Auth {
    public static let shared = Auth()
    public static func auth() -> Auth { shared }

    public func signIn(
        withEmail email: String,
        password: String,
        completion: @escaping (AuthDataResult?, Error?) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if email.contains("@") && password.count >= 6 {
                completion(AuthDataResult(user: User(email: email)), nil)
            } else {
                let error = NSError(
                    domain: "FIRAuthErrorDomain",
                    code: 17009,
                    userInfo: [NSLocalizedDescriptionKey: "Credenciales inválidas. Verifica tu correo y contraseña."]
                )
                completion(nil, error)
            }
        }
    }

    public func createUser(
        withEmail email: String,
        password: String,
        completion: @escaping (AuthDataResult?, Error?) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if !email.contains("@") {
                let error = NSError(
                    domain: "FIRAuthErrorDomain",
                    code: 17008,
                    userInfo: [NSLocalizedDescriptionKey: "El formato del correo electrónico es inválido."]
                )
                completion(nil, error)
            } else if password.count < 6 {
                let error = NSError(
                    domain: "FIRAuthErrorDomain",
                    code: 17026,
                    userInfo: [NSLocalizedDescriptionKey: "La contraseña es muy débil. Debe tener al menos 6 caracteres."]
                )
                completion(nil, error)
            } else {
                completion(AuthDataResult(user: User(email: email)), nil)
            }
        }
    }
}
#endif

final class LoginViewController: UIViewController {

    // MARK: - Variable de Estado del Modo de Autenticación
    /// Controla si la vista se encuentra en modo Iniciar Sesión (true) o Registro (false)
    var isLoginMode: Bool = true

    // MARK: - IBOutlets requeridos
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    // MARK: - IBOutlets complementarios (Opcionales con fallback programático)
    @IBOutlet weak var loginButton: UIButton?
    @IBOutlet weak var registerButton: UIButton?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?

    // MARK: - UI Components Programáticos
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "HardwareQuote B2B"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Acceso exclusivo para técnicos y ensambladores"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// Campo de texto programático para confirmar contraseña durante el registro
    lazy var confirmPasswordTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Confirmar Contraseña"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.returnKeyType = .done
        field.isHidden = true // En modo Login inicia oculto
        field.delegate = self
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return field
    }()

    private lazy var fallbackContainerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var fallbackSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismissal()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Configuración de Interfaz
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Si los outlets no vinieron enlazados de un Storyboard, se inicializan programáticamente
        if emailTextField == nil || passwordTextField == nil {
            setupProgrammaticLayout()
        }

        configurarCamposDeTexto()
        configurarBotones()
        actualizarModoInterfaz(animado: false)
    }

    private func configurarCamposDeTexto() {
        emailTextField.placeholder = "Correo del Ensamblador (ej: tecnico@hardware.b2b)"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .next
        emailTextField.delegate = self

        passwordTextField.placeholder = "Contraseña"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = isLoginMode ? .done : .next
        passwordTextField.delegate = self
    }

    private func configurarBotones() {
        loginButton?.layer.cornerRadius = 12
        loginButton?.clipsToBounds = true

        registerButton?.addTarget(self, action: #selector(toggleAuthModeTapped(_:)), for: .touchUpInside)
    }

    // MARK: - Fallback de AutoLayout programático
    private func setupProgrammaticLayout() {
        let emailField = UITextField()
        emailField.borderStyle = .roundedRect
        self.emailTextField = emailField

        let passField = UITextField()
        passField.borderStyle = .roundedRect
        self.passwordTextField = passField

        // Botón principal (Iniciar Sesión / Crear Cuenta)
        let btn = UIButton(type: .system)
        btn.setTitle("Iniciar Sesión", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.20, green: 0.34, blue: 0.55, alpha: 1.0)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.addTarget(self, action: #selector(loginTapped(_:)), for: .touchUpInside)
        self.loginButton = btn

        // Botón secundario interruptor (texto azul sin fondo)
        let toggleBtn = UIButton(type: .system)
        toggleBtn.setTitle("¿No tienes cuenta? Regístrate", for: .normal)
        toggleBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        toggleBtn.setTitleColor(UIColor(red: 0.20, green: 0.34, blue: 0.55, alpha: 1.0), for: .normal)
        toggleBtn.backgroundColor = .clear
        toggleBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        toggleBtn.addTarget(self, action: #selector(toggleAuthModeTapped(_:)), for: .touchUpInside)
        self.registerButton = toggleBtn

        fallbackContainerStack.addArrangedSubview(titleLabel)
        fallbackContainerStack.addArrangedSubview(subtitleLabel)
        fallbackContainerStack.setCustomSpacing(32, after: subtitleLabel)
        fallbackContainerStack.addArrangedSubview(emailField)
        fallbackContainerStack.addArrangedSubview(passField)
        fallbackContainerStack.addArrangedSubview(confirmPasswordTextField) // Campo condicional de confirmación
        fallbackContainerStack.setCustomSpacing(24, after: confirmPasswordTextField)
        fallbackContainerStack.addArrangedSubview(btn)
        fallbackContainerStack.setCustomSpacing(10, after: btn)
        fallbackContainerStack.addArrangedSubview(toggleBtn)

        view.addSubview(fallbackContainerStack)
        btn.addSubview(fallbackSpinner)

        NSLayoutConstraint.activate([
            fallbackContainerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            fallbackContainerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            fallbackContainerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            emailField.heightAnchor.constraint(equalToConstant: 48),
            passField.heightAnchor.constraint(equalToConstant: 48),

            fallbackSpinner.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            fallbackSpinner.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Alternancia Dinámica entre Login y Registro
    @objc func toggleAuthModeTapped(_ sender: UIButton) {
        view.endEditing(true)
        isLoginMode.toggle()
        actualizarModoInterfaz(animado: true)
    }

    /// Actualiza títulos, botones y visibilidad de campos con animación fluida en el StackView
    private func actualizarModoInterfaz(animado: Bool) {
        let bloqueActualizacion = {
            if self.isLoginMode {
                // Modo Login (true)
                self.titleLabel.text = "HardwareQuote B2B"
                self.subtitleLabel.text = "Acceso exclusivo para técnicos y ensambladores"
                self.loginButton?.setTitle("Iniciar Sesión", for: .normal)
                self.registerButton?.setTitle("¿No tienes cuenta? Regístrate", for: .normal)
                self.confirmPasswordTextField.isHidden = true
                self.passwordTextField.returnKeyType = .done
            } else {
                // Modo Registro (false)
                self.titleLabel.text = "Registro de Ensamblador"
                self.subtitleLabel.text = "Crea tu cuenta de técnico para gestionar y emitir cotizaciones"
                self.loginButton?.setTitle("Crear Cuenta", for: .normal)
                self.registerButton?.setTitle("¿Ya tienes cuenta? Inicia sesión", for: .normal)
                self.confirmPasswordTextField.isHidden = false
                self.passwordTextField.returnKeyType = .next
            }
            self.fallbackContainerStack.layoutIfNeeded()
        }

        if animado {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.5,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: bloqueActualizacion,
                completion: nil
            )
        } else {
            bloqueActualizacion()
        }
    }

    // MARK: - IBAction Principal: Evalúa isLoginMode
    @IBAction func loginTapped(_ sender: UIButton) {
        // 1. Validar correo corporativo
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            mostrarAlertaError(mensaje: "Por favor, ingresa tu correo electrónico corporativo.")
            emailTextField.becomeFirstResponder()
            return
        }

        // 2. Validar contraseña base
        guard let password = passwordTextField.text, !password.isEmpty else {
            mostrarAlertaError(mensaje: "Por favor, ingresa tu contraseña de acceso.")
            passwordTextField.becomeFirstResponder()
            return
        }

        guard password.count >= 6 else {
            mostrarAlertaError(mensaje: "La contraseña debe tener al menos 6 caracteres.")
            passwordTextField.becomeFirstResponder()
            return
        }

        // 3. Ramificación según el modo de autenticación
        if isLoginMode {
            ejecutarInicioSesion(email: email, password: password)
        } else {
            ejecutarRegistro(email: email, password: password)
        }
    }

    // MARK: - Flujo 1: Inicio de Sesión
    private func ejecutarInicioSesion(email: String, password: String) {
        actualizarEstadoCarga(estaCargando: true, textoCarga: "Verificando credenciales...")

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.actualizarEstadoCarga(estaCargando: false)

                if let error = error {
                    let mensajeAmigable = self.mapearErrorAutenticacion(error)
                    self.mostrarAlertaError(mensaje: mensajeAmigable)
                    return
                }

                guard authResult?.user != nil else {
                    self.mostrarAlertaError(mensaje: "No se pudo recuperar la información del usuario.")
                    return
                }

                self.navegarAVistaPrincipalSwiftUI()
            }
        }
    }

    // MARK: - Flujo 2: Registro de Usuario
    private func ejecutarRegistro(email: String, password: String) {
        // Validación estricta de igualdad de contraseñas
        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            mostrarAlertaError(mensaje: "Por favor, confirma tu contraseña en el campo correspondiente.")
            confirmPasswordTextField.becomeFirstResponder()
            return
        }

        guard password == confirmPassword else {
            mostrarAlertaError(mensaje: "Las contraseñas no coinciden. Por favor, asegúrate de que ambos campos sean idénticos.")
            confirmPasswordTextField.becomeFirstResponder()
            return
        }

        actualizarEstadoCarga(estaCargando: true, textoCarga: "Creando cuenta...")

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.actualizarEstadoCarga(estaCargando: false)

                if let error = error {
                    let mensajeAmigable = self.mapearErrorAutenticacion(error)
                    self.mostrarAlertaError(mensaje: mensajeAmigable)
                    return
                }

                guard authResult?.user != nil else {
                    self.mostrarAlertaError(mensaje: "No se pudo completar el registro del nuevo ensamblador.")
                    return
                }

                self.navegarAVistaPrincipalSwiftUI()
            }
        }
    }

    // MARK: - Control del Estado de Carga
    private func actualizarEstadoCarga(estaCargando: Bool, textoCarga: String? = nil) {
        view.isUserInteractionEnabled = !estaCargando
        emailTextField.isEnabled = !estaCargando
        passwordTextField.isEnabled = !estaCargando
        confirmPasswordTextField.isEnabled = !estaCargando
        loginButton?.isEnabled = !estaCargando
        registerButton?.isEnabled = !estaCargando

        if let indicator = activityIndicator {
            if estaCargando {
                indicator.startAnimating()
            } else {
                indicator.stopAnimating()
            }
        } else {
            if estaCargando {
                fallbackSpinner.startAnimating()
                loginButton?.setTitle(textoCarga ?? "Procesando...", for: .normal)
            } else {
                fallbackSpinner.stopAnimating()
                let tituloBoton = isLoginMode ? "Iniciar Sesión" : "Crear Cuenta"
                loginButton?.setTitle(tituloBoton, for: .normal)
            }
        }
    }

    // MARK: - Transición a SwiftUI (UIHostingController)
    private func navegarAVistaPrincipalSwiftUI() {
        let mainSwiftUIView = QuoteBuilderView()
            .modelContainer(for: [Cotizacion.self, Componente.self])
        let hostingController = UIHostingController(rootView: mainSwiftUIView)

        if let window = view.window {
            UIView.transition(
                with: window,
                duration: 0.4,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = hostingController
                },
                completion: nil
            )
        } else if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.setViewControllers([hostingController], animated: true)
        } else {
            hostingController.modalPresentationStyle = .fullScreen
            hostingController.modalTransitionStyle = .flipHorizontal
            present(hostingController, animated: true, completion: nil)
        }
    }

    // MARK: - Manejo de Errores con UIAlertController
    private func mostrarAlertaError(mensaje: String) {
        let alerta = UIAlertController(
            title: isLoginMode ? "Error de Inicio de Sesión" : "Error en Registro",
            message: mensaje,
            preferredStyle: .alert
        )

        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if !self.isLoginMode && self.passwordTextField.text != self.confirmPasswordTextField.text {
                self.confirmPasswordTextField.becomeFirstResponder()
            } else {
                self.passwordTextField.becomeFirstResponder()
            }
        }

        alerta.addAction(accionAceptar)
        present(alerta, animated: true, completion: nil)
    }

    private func mapearErrorAutenticacion(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
            return "Este correo ya está registrado con otra cuenta. Inicia sesión o utiliza un correo distinto."
        case 17008: // FIRAuthErrorCodeInvalidEmail
            return "El formato del correo electrónico es inválido. Verifica la dirección ingresada."
        case 17009: // FIRAuthErrorCodeWrongPassword
            return "La contraseña ingresada es incorrecta. Por favor, verifica tus datos."
        case 17011: // FIRAuthErrorCodeUserNotFound
            return "No existe una cuenta de ensamblador registrada con este correo."
        case 17020: // FIRAuthErrorCodeNetworkError
            return "Error de conexión con los servidores de Firebase. Verifica tu conexión a internet."
        case 17026: // FIRAuthErrorCodeWeakPassword
            return "La contraseña es demasiado débil. Ingresa al menos 6 caracteres con números o símbolos."
        case 17010: // FIRAuthErrorCodeTooManyRequests
            return "Demasiados intentos fallidos. Tu acceso ha sido bloqueado temporalmente por seguridad."
        default:
            return error.localizedDescription
        }
    }

    // MARK: - Gestión de Teclado
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(descartarTeclado))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func descartarTeclado() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            if isLoginMode {
                textField.resignFirstResponder()
                if let button = loginButton {
                    loginTapped(button)
                }
            } else {
                confirmPasswordTextField.becomeFirstResponder()
            }
        } else if textField == confirmPasswordTextField {
            textField.resignFirstResponder()
            if let button = loginButton {
                loginTapped(button)
            }
        }
        return true
    }
}
