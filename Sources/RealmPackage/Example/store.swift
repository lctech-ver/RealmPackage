import Foundation

actor AuthStore {
    static let shared = AuthStore()
    
    private var tokens: Auth = Auth(huid: "", authToken: "", accessToken: "", talkToken: "")
    private var isInitialized = false
    private var initializationTask: Task<Void, Never>?
    
    init() {
        initializationTask = Task {
            self.loadAuthTokens()
            await self.setInitialized()
        }
    }
    
    /// 確保初始化完成後再使用
    internal func ensureInitialized() async {
        if let task = initializationTask {
            await task.value
        }
    }
    
    private func setInitialized() {
        isInitialized = true
    }
    
    internal func getAuthTokens() -> Auth {
        return tokens
    }
    
    internal func createAuth(auth: Auth) {
        let object: AuthObject = Transform.modelToObject(auth)
        DBService.shared.authDB.createObjects(data: [object])
        loadAuthTokens()
    }
    
    internal func loadAuthTokens() {
        let authObjects = DBService.shared.authDB.loadObjects(objectType: AuthObject.self)
        let auths = authObjects.map { $0.toModel() }
        
        if !auths.isEmpty {
            self.tokens = auths[0]
        }
    }
    
    internal func updateAuth(authToken: String? = nil, accessToken: String? = nil, talkToken: String? = nil) {
        let success = DBService.shared.authDB.updateObject(type: AuthObject.self,
                                                            primaryKey: self.tokens.huid)
        { object in
            if let accessToken = accessToken {
                object.accessToken = accessToken
            }
            
            if let authToken = authToken {
                object.authToken = authToken
            }
            
            if let talkToken = talkToken {
                object.talkToken = talkToken
            }
        }
        
        if success {
            if let accessToken = accessToken {
                self.tokens.accessToken = accessToken
            }
            
            if let authToken = authToken {
                self.tokens.authToken = authToken
            }
            
            if let talkToken = talkToken {
                self.tokens.talkToken = talkToken
            }
        }
    }

    internal func deleteAuth() {
        DBService.shared.authDB.deleteObjects(type: AuthObject.self)
    }
}
