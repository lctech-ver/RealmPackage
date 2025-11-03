//
//  DBDesign.swift
//  RealmPackage
//
//  Created by Ver on 2025/10/30.
//

import Foundation
import RealmSwift

public protocol RealmMigrationProvider: Sendable {
    var schemaVersion: UInt64 { get }
    func migrate(migration: Migration, oldSchemaVersion: UInt64)
}

public actor RealmConfig {
    private var realm: Realm
    
    private var service: RealmService = RealmService()
    
    public init(
        baseName: String,
        objects: [ObjectBase.Type],
        deleteIfMigrationNeed: Bool,
        migrationProvider: RealmMigrationProvider? = nil
    ) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(baseName)
        
        var configuration = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: migrationProvider?.schemaVersion ?? 0,
            deleteRealmIfMigrationNeeded: deleteIfMigrationNeed,
            objectTypes: objects
        )
        
        if !deleteIfMigrationNeed, let provider = migrationProvider {
            configuration.migrationBlock = { migration, oldSchemaVersion in
                provider.migrate(migration: migration, oldSchemaVersion: oldSchemaVersion)
            }
        }
        
        self.realm = try! Realm(configuration: configuration)
    }
}

// MARK: CRUD Methods
extension RealmConfig {
    @discardableResult
    public func createObjects(data: [Object]) -> Bool {
        let result = service.createObject(database: realm, list: data)
        switch result {
        case .success(let success):
            print("[RealmService] create objects successful, create \(data.count) items")
            return true
        case .failure(let failure):
            print("[RealmService] create objects unsuccessful, error:\(failure)")
            return false
        }
    }
    
    public func loadObjects<T: Object>(objectType: T, predicate: NSPredicate? = nil) -> [T] {
        let result = service.loadList(object: T.self, database: realm, predicate: predicate)
        
        switch result {
        case .success(let objects):
            return objects
        case .failure(let failure):
            print("[RealmService] load objects unsuccessful, error:\(failure)")
            return []
        }
    }
    
    @discardableResult
    public func deleteObjects(type: Object.Type, predicate: NSPredicate? = nil) -> Bool {
        return service.deleteList(database: realm, objectType: type, predicate: predicate)
    }
    
    @discardableResult
    public func updateObject<T: Object>(type: T.Type, primaryKey: Any, _ update: (T) -> Void) -> Bool {
        let result = service.updateObject(
            ofType: type,
            database: realm,
            primaryKey: primaryKey,
            update: update
        )
        switch result {
        case .success:
            return true
        case .failure(let error):
            print("[RealmService] update object unsuccessful, error:\(error)")
            return false
        }
    }
}



