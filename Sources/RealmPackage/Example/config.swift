import Foundation
import RealmPackage

class DBService {
    static let shared = DBService()
    
    internal var authDB = RealmConfig(baseName: "Auth",
                                      objects: [AuthObject.self],
                                      key: <#Data#>,
                                      deleteIfMigrationNeed: false)
 
    
    internal var profileDB = RealmConfig(baseName: "user_infomation",
                                         objects: [User_PersonInfo.self],
                                         deleteIfMigrationNeed: false)
    
    internal var panDB = RealmConfig(baseName: "Pan",
                                     objects: [PanObject.self],
                                     deleteIfMigrationNeed: true)
    
    internal var mediaDB = RealmConfig(baseName: "Media",
                                       objects: [MediaStorageObject.self],
                                       deleteIfMigrationNeed: true)
    
    
}
