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

public final class RealmConfig {
    private var service: RealmService = RealmService()
    
    private var config: Realm.Configuration
    
    public init(baseName: String,
                objects: [ObjectBase.Type],
                deleteIfMigrationNeed: Bool,
                migrationProvider: RealmMigrationProvider? = nil) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(baseName)
        
        self.config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: migrationProvider?.schemaVersion ?? 0,
            deleteRealmIfMigrationNeeded: deleteIfMigrationNeed,
            objectTypes: objects
        )
        
        if !deleteIfMigrationNeed, let provider = migrationProvider {
            config.migrationBlock = { migration, oldSchemaVersion in
                provider.migrate(migration: migration, oldSchemaVersion: oldSchemaVersion)
            }
        }
    }
    
    private func createRealm() -> Realm {
        return try! Realm(configuration: config)
    }
}

// MARK: CRUD Methods
extension RealmConfig {
    @discardableResult
    public func createObjects(data: [Object]) -> Bool {
        let realm = self.createRealm()
        
        let result = service.createObject(database: realm, list: data)
        switch result {
        case .success:
            print("[RealmService] create objects successful, create \(data.count) items")
            return true
        case .failure(let failure):
            print("[RealmService] create objects unsuccessful, error:\(failure)")
            return false
        }
    }
    
    public func loadObjects<T: Object>(objectType: T.Type, predicate: NSPredicate? = nil) -> [T] {
        let realm = self.createRealm()
        
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
    public func deleteObjects(type: Object.Type, predicate: String? = nil) -> Bool {
        let realm = self.createRealm()
        return service.deleteList(database: realm, objectType: type, predicate: predicate)
    }
    
    @discardableResult
    public func updateObject<T: Object>(type: T.Type, primaryKey: Any, _ update: (T) -> Void) -> Bool {
        let realm = self.createRealm()
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



