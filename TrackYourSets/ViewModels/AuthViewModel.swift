//
//  AuthViewModel.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-02.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import AuthenticationServices
import CryptoKit
import GoogleSignIn


@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var currentUser: UserModel? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentNonce: String? = nil
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // MARK: - Email/Password
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Crea el doc del usuario en Firestore
            let newUser = UserModel(
                id: result.user.uid,
                email: result.user.email ?? "",
                displayName: displayName,
                createdAt: Date()
            )
            
            try db.collection("users").document(result.user.uid).setData(from: newUser)
            try await fetchUser(uid: result.user.uid)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String)  async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await fetchUser(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firestore User
    
    func fetchUser(uid: String) async throws {
        let ref = db.collection("users").document(uid)
        let doc = try await ref.getDocument()

        guard doc.exists else {
            // Documento aún no existe: deja currentUser en nil sin error
            self.currentUser = nil
            return
        }

        do {
            self.currentUser = try doc.data(as: UserModel.self)
        } catch {
            self.errorMessage = "Perfil con formato inválido. Intentando repararlo…"
            throw error
        }
    }
    
    func loadCurrentUser() async {
        guard let uid = auth.currentUser?.uid else { return }
        try? await fetchUser(uid: uid)
    }
    
    // MARK: - Apple Sign in (con Firebase)
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess { fatalError("No se pudo generar bytes aleatorios: \(status)") }
            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Llamar desde el botón de Apple en la View (request block)
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce) // Apple recibe el hash del nonce
    }

    /// Llamar desde el botón de Apple en la View (completion block)
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = "Apple Sign-In cancelado o falló."
                self.isLoading = false
            }
            print("Apple error:", error.localizedDescription)

        case .success(let authResult):
            guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                await MainActor.run { self.errorMessage = "Credencial inválida de Apple." }
                return
            }

            guard let idTokenData = appleIDCredential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8) else {
                await MainActor.run { self.errorMessage = "No se pudo leer el identityToken." }
                return
            }

            guard let nonce = currentNonce else {
                await MainActor.run { self.errorMessage = "Nonce no encontrado." }
                return
            }

            isLoading = true
            defer { isLoading = false }

            do {
                // Credencial específica de Apple (Firebase iOS SDK moderno)
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                
                // 1) Autenticar en Firebase
                let fbResult = try await auth.signIn(with: credential)
                let uid = fbResult.user.uid

                // 2) Marca sesión iniciada primero (UI no rebota aunque Firestore tarde)
                // (Tu UI ya depende de currentUser != nil, pero si la usas en el futuro, aquí quedaría lista)
                // self.isAuthenticated = true // <- no la usas, pero lo dejo anotado

                // 3) Intentar cargar el perfil
                try await self.fetchUser(uid: uid)

                // 4) Si no existe, crear documento y recargar
                if self.currentUser == nil {
                    let name: String = {
                        let fullName = appleIDCredential.fullName
                        let composed = [fullName?.givenName, fullName?.familyName]
                            .compactMap { $0 }.joined(separator: " ")
                        return composed.isEmpty ? (fbResult.user.displayName ?? "User") : composed
                    }()

                    let newUser = UserModel(
                        id: uid,
                        email: fbResult.user.email ?? "", // Apple puede no dar email en logins posteriores
                        displayName: name,
                        createdAt: Date()
                    )

                    try db.collection("users").document(uid).setData(from: newUser)
                    try await self.fetchUser(uid: uid)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "No se pudo iniciar sesión con Apple."
                }
                print("Firebase Apple error:", error.localizedDescription)
            }
        }
    }
    


    

        /// Login con Google → Firebase → crear/leer usuario en Firestore
        func signInWithGoogle() async {
            errorMessage = nil
            isLoading = true
            defer { isLoading = false }

            guard let presentingVC = topViewController() else {
                self.errorMessage = "No se pudo abrir Google Sign-In."
                return
            }

            do {
                // 1) Abrir Google Sign-In
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

                // 2) Tomar tokens de Google
                guard let idToken = signInResult.user.idToken?.tokenString else {
                    self.errorMessage = "No se pudo obtener idToken de Google."
                    return
                }
                let accessToken = signInResult.user.accessToken.tokenString

                // 3) Crear credencial de Firebase con tokens de Google
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

                // 4) Entrar a Firebase
                let authResult = try await Auth.auth().signIn(with: credential)
                let uid = authResult.user.uid

                // 5) Cargar perfil; si no existe, crearlo
                try await self.fetchUser(uid: uid)

                if self.currentUser == nil {
                    let newUser = UserModel(
                        id: uid,
                        email: authResult.user.email ?? "",
                        displayName: authResult.user.displayName ?? "User",
                        createdAt: Date()
                    )
                    try db.collection("users").document(uid).setData(from: newUser)
                    try await self.fetchUser(uid: uid)
                }

            } catch {
                self.errorMessage = "No se pudo iniciar sesión con Google."
                print("Google Sign-In error:", error.localizedDescription)
            }
        }
    }

extension AuthViewModel {
    /// Encuentra el view controller de arriba para presentar Google Sign-In
    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.keyWindow,
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }

}




