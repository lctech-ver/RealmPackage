# RealmPackage

輕量封裝的 Realm 服務層，提供安全且一致的資料庫操作（CRUD）、模型轉換工具，以及可選的資料庫加密與遷移支援。

## 功能概要
- 資料庫 CRUD：建立、查詢、更新、刪除皆以統一 API 進行。
- 泛型更新：以 primaryKey 鎖定單筆資料，使用閉包安全更新欄位。
- 結構互轉：`Object` 與純 Swift `struct` 透過協定與工具雙向轉換，並確保執行緒安全。
- 遷移支援：自訂 `RealmMigrationProvider` 控制版本與遷移邏輯。
- 加密支援：內建金鑰產生/保存，配置 `Realm.Configuration` 的 `encryptionKey`。

## 架構與檔案
- Core
  - `Core/DBConfig.swift`：資料庫初始化與公開 CRUD API（`RealmConfig`）。
  - `Core/RealmService.swift`：實際對 Realm 的操作細節（內部使用）。
- Helper
  - `Helper/Transform.swift`：`Object` ↔ `Model` 雙向轉換工具與協定。
  - `Helper/KeychainManager.swift`：資料庫加密金鑰管理。

## 安裝與相依
- 以 Swift Package 形式引入（此專案已內嵌於工作區）。
- 需要 `RealmSwift`，並指定版本 v20.0.3。

## 初始化與設定
```swift
// 自訂遷移流程（選用）
struct UserMigration: RealmMigrationProvider {
    var schemaVersion: UInt64 = 3
    func migrate(migration: Migration, oldSchemaVersion: UInt64) {
        if oldSchemaVersion < 1 {
            migration.enumerateObjects(ofType: User.className()) { _, newObject in
                newObject?["email"] = "unknown@example.com"
            }
        }
    }
}

// 產生或取得加密金鑰（使用 KeychainManager 或自訂）
let encryptionKey: Data
do {
    encryptionKey = try KeychainManager.retrieveKey()
} catch {
    encryptionKey = try KeychainManager.generateKey()
    try KeychainManager.storeKey(encryptionKey)
}

// 建立資料庫設定實例（RealmConfig 為 actor）
let db = RealmConfig(
    baseName: "example.realm",
    objects: [User.self],
    key: encryptionKey,
    deleteIfMigrationNeed: false,
    migrationProvider: UserMigration()
)
```

參數說明：
- `baseName`：資料庫檔名（會存於 Documents 目錄）。
- `objects`：要註冊進資料庫的 `Object` 類型陣列。
- `key`：64 位元組的加密金鑰（`Data` 類型）。可使用 `KeychainManager` 產生與管理。
- `deleteIfMigrationNeed`：若為 `true`，版本不相容時直接刪庫重建；若為 `false`，請提供 `migrationProvider` 並在其中處理遷移。
- `migrationProvider`：自訂遷移提供者，定義 `schemaVersion` 與遷移邏輯。

## 基本用法（CRUD）
```swift
// 建立多筆資料
let created = await db.createObjects(data: [userObj1, userObj2])

// 讀取清單（可選 predicate 條件）
let users: [UserObject] = await db.loadObjects(objectType: UserObject(), predicate: NSPredicate(value: true))

// 刪除（可選 predicate 條件）
let deleted = await db.deleteObjects(type: UserObject.self, predicate: nil)

// 更新（使用 primaryKey + 閉包更新）
let ok = await db.updateObject(type: UserObject.self, primaryKey: "123") { user in
    user.name = "John"
}
```

操作行為與錯誤：
- `createObjects`：建立成功回傳 `true`，失敗回傳 `false`。返回的物件已加入 Realm 資料庫。
- `loadObjects`：查詢成功回傳凍結的物件陣列（可安全跨執行緒使用），查無資料回傳空陣列。
- `deleteObjects`：刪除成功回傳 `true`，失敗回傳 `false`。
- `updateObject`：若找不到指定 primaryKey 的物件，會回傳 `false` 並列印錯誤。內部以 `Realm.write { ... }` 包裝更新閉包，寫入失敗同樣回傳 `false`。

## 模型轉換（Object ↔ Model）
為了在 UI/業務層使用純 Swift 結構（值型別），我們提供 `RealmMappableObject` 協定與 `Transform` 工具：

```swift
// 1) 讓 Object 實作協定，描述與 Model 的對應
struct User { var name: String }

final class UserObject: Object, RealmMappableObject {
    @Persisted var name: String
    typealias Model = User
    static func from(model: User) -> UserObject {
        let o = UserObject()
        o.name = model.name
        return o
    }
    func toModel() -> User { User(name: name) }
}

// 2) 使用 Transform 工具（執行緒安全）
let model: User = Transform.objectToModel(userObject)        // Object -> Model（使用 frozen）
let object: UserObject = Transform.modelToObject(model)      // Model -> unmanaged Object
let models: [User] = Transform.objectsToModels(objectArray)
let objects: [UserObject] = Transform.modelsToObjects(models)
```

執行緒安全說明：
- Object 轉 Model 時會先 `freezeSafely()`，避免跨執行緒限制。
- Model 轉 Object 回傳的是「未受管」物件，請在 `Realm.write { add(...) }` 內保存。

## 執行緒與安全性
- `RealmConfig` 是 `actor`，建議以 `await` 呼叫其方法以確保協同安全。
- `RealmService` 內部使用 Realm 的寫入交易管理；讀取操作（`loadObject`、`loadObjects`）會自動 freeze 物件，確保執行緒安全。
- 所有從 `loadObjects` 回傳的物件都是凍結（frozen）狀態，可安全地跨執行緒使用。
- `createObject` 不返回 managed objects，避免執行緒安全問題。

## 限制與注意事項
- 更新 API 目前以 primaryKey 精準鎖定單筆資料；若需「批次條件更新」，可加一個以 `NSPredicate` 篩選後迭代更新的版本。
- `objects: [ObjectBase.Type]` 必須包含所有欲儲存的 `Object` 類型。
- 若設定 `deleteIfMigrationNeed = true`，版本不相容將直接刪庫；請僅在可接受資料重置的情境使用。
- 加密金鑰必須為 64 位元組的 `Data`。建議使用 `KeychainManager` 產生與管理金鑰，確保金鑰安全存儲。若 App 重裝或 Keychain 清空，需能接受無法解密舊資料的風險（或自行備援）。
- 所有資料庫操作都需要 `key` 參數，即使不使用加密也必須提供（可傳入空的 64 位元組 `Data`）。

## 錯誤處理
- `RealmService.RealmError`：
  - `.empty`：查無資料
  - `.databaseFail`：資料庫操作失敗
  - `.writedFailed`：寫入交易失敗

## 範例：整合流程
```swift
// 1) 準備 Object 與 Model 的對映（見上節）

// 2) 產生或取得加密金鑰
let encryptionKey: Data
do {
    encryptionKey = try KeychainManager.retrieveKey()
} catch {
    encryptionKey = try KeychainManager.generateKey()
    try KeychainManager.storeKey(encryptionKey)
}

// 3) 初始化資料庫
let db = RealmConfig(
    baseName: "example.realm",
    objects: [UserObject.self],
    key: encryptionKey,
    deleteIfMigrationNeed: false,
    migrationProvider: UserMigration()
)

// 4) 寫入：Model -> Object -> add
let m = User(name: "Alice")
let o: UserObject = Transform.modelToObject(m)
let created = await db.createObjects(data: [o])

// 5) 查詢 + 轉 Model
let list: [UserObject] = await db.loadObjects(objectType: UserObject(), predicate: NSPredicate(value: true))
let models: [User] = Transform.objectsToModels(list)

// 6) 更新（以 primaryKey 鎖定）
let success = await db.updateObject(type: UserObject.self, primaryKey: "alice-id") { user in
    user.name = "Alice Chen"
}
```

## 常見問題
- 如何批次更新？
  - 建議先以 `loadObjects` 取得目標清單，再在單一 `write` 交易中逐筆更新；或新增一個 `update(objectsWhere:predicate:_:)` 的 API。
- 如何避免跨執行緒存取錯誤？
  - 本套件的 `loadObjects` 已自動 freeze 所有返回的物件，可安全跨執行緒使用。讀取物件時請使用本套件回傳的陣列，這些物件都是凍結狀態。
- 如何產生加密金鑰？
  - 使用 `KeychainManager.generateKey()` 產生 64 位元組的金鑰，並以 `KeychainManager.storeKey(_:)` 存儲到 Keychain。之後可用 `KeychainManager.retrieveKey()` 取回。
- 是否必須使用加密？
  - 必須提供 `key` 參數，但可以傳入空的 64 位元組 `Data` 來關閉加密（不建議用於生產環境）。

