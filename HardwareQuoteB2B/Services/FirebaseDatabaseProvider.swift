import Foundation
import FirebaseDatabase

/// Punto único de acceso a Realtime Database.
/// El `GoogleService-Info.plist` no trae `DATABASE_URL`, por lo que
/// `Database.database()` sin URL lanza una excepción al guardar.
enum FirebaseDatabaseProvider {
    static let databaseURL = "https://hardwarequoteb2b-default-rtdb.firebaseio.com"

    static var instance: Database {
        Database.database(url: databaseURL)
    }
}
