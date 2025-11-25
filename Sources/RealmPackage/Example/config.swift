import Foundation
import RealmPackage

actor DBService {
    static let shared = DBService()
    
    internal var DB = RealmConfig(baseName: "Auth",
                                      objects: [AuthObject.self],
                                      deleteIfMigrationNeed: false)   
}
