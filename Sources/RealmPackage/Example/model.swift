import RealmSwift
import Foundation

struct Auth: Codable {
    var huid: String
    
    var authToken: String
    
    var accessToken: String
    
    var talkToken: String
}

final class AuthObject: Object, RealmMappableObject {
    typealias Model = Auth
    
    @Persisted(primaryKey: true) var huid: String
    
    @Persisted var authToken: String
    
    @Persisted var accessToken: String
    
    @Persisted var talkToken: String
    
    static func from(model: Auth) -> AuthObject {
        let object = AuthObject()
        object.huid = model.huid
        object.accessToken = model.accessToken
        object.authToken = model.authToken
        object.talkToken = model.talkToken
        return object
    }
    
    func toModel() -> Auth {
        return Auth(huid: huid, authToken: authToken, accessToken: accessToken, talkToken: talkToken)
    }
}

