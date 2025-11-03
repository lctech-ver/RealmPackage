//
//  RealmService.swift
//  RealmPackage
//
//  Created by Ver on 2025/10/30.
//

import Combine
import RealmSwift
import Foundation

final class RealmService {
    // MARK: GET
    public func loadData(object: Object.Type, database: Realm, primaryKey: Any?) -> Result<Object, RealmError> {
        let loadedData = database.object(ofType: object, forPrimaryKey: primaryKey)
        guard let loadedData = loadedData else {
            return Result.failure(.empty)
        }
        return Result.success(loadedData.freeze())
    }
    
    public func loadList<T: Object>(object: T.Type, database: Realm, predicate: NSPredicate? = nil) -> Result<[T], RealmError> {
        var loadedData = database.objects(object)
        if let predicate = predicate {
          loadedData = loadedData.filter(predicate)
        }

        let frozenArray = Array(loadedData)
        
        guard !loadedData.isEmpty else {
            return Result.failure(.empty)
        }
        return .success(frozenArray)
    }

    // MARK: CREATE
    @discardableResult
    public func createObject<T: Object>(database: Realm, list: [T]) -> Result<[T], RealmError> {
        do {
            try database.write {
                database.add(list)
            }
            
            return Result.success(list)
        } catch {
            print("[RealmService] add data unsuccessful")
            return Result.failure(.databaseFail)
        }
    }
    
    
    // MARK: DELETE
    @discardableResult
    public func deleteData<T: Object>(database: Realm, object: T) -> Bool {
        do {
            try database.write {
                database.delete(object)
            }
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func deleteList(database: Realm, objectType: Object.Type, predicate: NSPredicate? = nil) -> Bool {
        do {
            try database.write {
                var list = database.objects(objectType)
                if let predicate = predicate {
                    list = list.filter(predicate)
                }
                database.delete(list)
            }
            return true
        } catch {
            return false
        }
    }
    
    // MARK: Update
    /*
     Usage:
        let result = updateObject(ofType: User.self, database: realm, primaryKey: "123") { user in
            user.name = "John"
            user.email = "john@example.com"
            user.age = 30
        }
    */
    public func updateObject<T: Object>(
        ofType type: T.Type,
        database: Realm,
        primaryKey: Any?,
        update: (T) -> Void
    ) -> Result<Void, RealmError> {
        guard let object = database.object(ofType: type, forPrimaryKey: primaryKey) else {
            return .failure(.empty)
        }
        
        do {
            try database.write {
                update(object)
            }
            return .success(())
        } catch {
            return .failure(.writedFailed)
        }
    }
}

extension RealmService {
    enum RealmError: Error {
        case empty ///抓不到資料
        case databaseFail ///操作資料庫時出現錯誤
        case writedFailed
    }
    
    enum KeyError: Error {
        case keyGenerationFailed
        case keychainStoreFailed
        case keyNotFound
    }
    
    func getEncryptedConfiguration(name: String) throws -> Realm.Configuration {
        let key: Data
        
        do {
            key = try KeychainManager.retrieveKey()
        } catch {
            key = try KeychainManager.generateKey()
            try KeychainManager.storeKey(key)
        }
        
        return Realm.Configuration(fileURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name),
            encryptionKey: key,
            schemaVersion: 1
        )
    }
}

extension Object {
    public func freezeSafely() -> Self {
        return self.isFrozen ? self : self.freeze()
    }
}
