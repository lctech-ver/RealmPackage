//
//  Transform.swift
//  RealmPackage
//
//  Created by Ver on 2025/10/30.
//

import Foundation
import RealmSwift

// Usage Example:
// struct User{
//     var name: String
// }
//
// class UserObject: Object, RealmMappableObject {
//     @Persisted var name: String
//     typealias Model = User
//     static func from(model: User) -> UserObject {
//         let obj = UserObject()
//         obj.name = model.name
//         return obj
//     }
//     func toModel() -> User { User(name: name) }
// }

public protocol RealmMappableObject: AnyObject {
    associatedtype Model
    static func from(model: Model) -> Self
    func toModel() -> Model
}

public enum Transform {
    public static func objectToModel<O: Object & RealmMappableObject>(_ object: O) -> O.Model {
        let frozen = object.freezeSafely()
        return frozen.toModel()
    }

    public static func modelToObject<O: Object & RealmMappableObject>(_ model: O.Model) -> O {
        return O.from(model: model)
    }

    public static func objectsToModels<O: Object & RealmMappableObject>(_ objects: [O]) -> [O.Model] {
        return objects.map { objectToModel($0) }
    }

    public static func modelsToObjects<O: Object & RealmMappableObject>(_ models: [O.Model]) -> [O] {
        return models.map { modelToObject($0) }
    }
}

