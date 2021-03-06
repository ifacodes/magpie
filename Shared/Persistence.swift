//
//  Persistence.swift
//  Shared
//
//  Created by Aoife Bradley on 2022-02-25.
//

import CoreData
import CloudKit
import SwiftUI
import Foundation

// MARK: - UIColorValueTransformer

@objc(UIColorValueTransformer)
final class UIColorValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: UIColorValueTransformer.self))
    
    override static var allowedTopLevelClasses: [AnyClass] {
        return [UIColor.self]
    }
    
    public static func register() {
        let transformer = UIColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
}

// MARK: - UIImageValueTransformer

@objc(UIImageValueTransformer)
final class UIImageValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: UIImageValueTransformer.self))
    
    override static var allowedTopLevelClasses: [AnyClass] {
        return [UIImage.self]
    }
    
    public static func register() {
        let transformer = UIImageValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
}

struct PersistenceController {
    // Makes a Singleton
    static let shared = PersistenceController()
    
    // Test Config for SwiftUI Previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let cache = Cache(context: viewContext)
        cache.name = "Public Storage"
        cache.iconString = "symbol:house.circle.fill"
        cache.uiColor = UIColor(Color.orange)
        for i in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.createdTimestamp = Date()
            newItem.name = "Test \(i)"
            cache.addToItems(newItem)
        }
        let newBox = Box(context: viewContext)
        newBox.name = "A"
        let newItem = Item(context: viewContext)
        newItem.createdTimestamp = Date()
        newItem.name = "Test With Box"
        newBox.addToItems(newItem)
        cache.addToItems(newItem)
        cache.addToBoxes(newBox)
        
        for i in 0..<10 {
            let newTag = Tag(context: viewContext)
            newTag.uuid = UUID()
            if i % 4 == 0 {
                newTag.name = "Test \(i) Longer word!!"
                newTag.color = UIColor(Color.red)
            } else if i % 6 == 0 {
                newTag.name = "Test \(i) REALLLLLLLLLLLY Long"
                newTag.color = UIColor(Color.green)
            } else {
                newTag.name = "Test \(i)"
                newTag.color = UIColor(Color.blue)
            }
            newItem.addToTags(newTag)
        }
//        let newTag = Tag(context: viewContext)
//        newTag.uuid = UUID()
//        newTag.name = "TES"
//        newTag.color = UIColor(.gray)
//        newItem.addToTags(newTag)
        result.save()
        return result
    }()
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func purgeUserData() async throws {
        
        let ckContainer = CKContainer.default()
        let database = ckContainer.privateCloudDatabase
        
        try await database.deleteRecordZone(withID: .init(zoneName: "com.apple.coredata.cloudkit.zone"))
    }
    
    // Stores CoreData so it can sync with ICloud
    var container: NSPersistentCloudKitContainer
    
    //let sharedPersistentStore: NSPersistentStore
    
    // initialiser for CoreData, optionally let it use in-memory storage
    init(inMemory: Bool = false) {
        
        UIColorValueTransformer.register()
        UIImageValueTransformer.register()
        
        container = NSPersistentCloudKitContainer(name: "cache")
        //try! container.persistentStoreCoordinator.destroyPersistentStore(at: container.persistentStoreDescriptions.first!.url!, type: .sqlite)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        /// Default (Private) configuration description.
        guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
            fatalError("###(#function): Unable to get a persistent store description")
        }
        
        /// Get the base url of persistent store locations.
        //let baseURL = privateStoreDescription.url!.deletingLastPathComponent()
        
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        privateStoreDescription.shouldInferMappingModelAutomatically = false
        
        if !NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync") {
            privateStoreDescription.cloudKitContainerOptions = nil
        }
        
        //        let sharedStoreURL = baseURL.appendingPathComponent("shared.sqlite")
        //        let sharedStoreDescription = privateStoreDescription.copy() as! NSPersistentStoreDescription
        //        sharedStoreDescription.url = sharedStoreURL
        
        //        let identifier = privateStoreDescription.cloudKitContainerOptions!.containerIdentifier
        //        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: identifier)
        //        sharedStoreOptions.databaseScope = .shared
        //        sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        //        container.persistentStoreDescriptions.append(sharedStoreDescription)
        
        
        
        // Enable remote notifications
        //        guard let description = container.persistentStoreDescriptions.first else {
        //            fatalError("###\(#function): Failed to retreive a persistant store description.")
        //        }
        //        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        //        #if DEBUG
        //        do {
        //            try container.initializeCloudKitSchema(options: [])
        //        } catch { error in
        //            fatalError("###\(#function): Failed to initialize CloudKit scheme.")
        //        }
        //        #endif
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        //NotificationCenter.default.addObserver(self, selector: #(self.), name: <#T##NSNotification.Name?#>, object: <#T##Any?#>)
        
    }
    
}

extension PersistenceController {
    
    func createCache(name: String, icon: CacheIcon, color: Color?) {
        let context = container.viewContext
        
        context.perform{
            
            let cache = Cache(context: context)
            cache.name = name
            cache.icon = icon
            cache.uiColor = UIColor(color!)
            
            self.save()
        
        }
        
    }
    
    func createItem(name: String, description: String?, image: UIImage?, dimensions: [Decimal]?, weight: Decimal?, cache: Cache, box: Box?) {
        let context = container.viewContext
        
        context.perform {
            let item = Item(context: context)
            
            item.name = name
            item.itemDescription = description
            item.image = image
            item.createdTimestamp = Date()
            item.uuid = UUID()
            
            if let dimensions = dimensions {
                item.dimensions = dimensions
            }
            if let weight = weight {
                item.g = weight
            }
            
            cache.addToItems(item)
            
            if let box = box {
                box.addToItems(item)
            }
            
            self.save()
        }
    }
    
    func createBox(name: String, cache: Cache) {
        let context = container.viewContext
        
        context.perform {
            let box = Box(context: context)
            
            box.name = name
            box.timestamp = Date()
            
            cache.addToBoxes(box)
            
            self.save()
        }
    }
    
    func deleteBox(box: Box) {
        let context = container.viewContext
        
        context.perform {
            context.delete(box)
            self.save()
        }
    }
    
    func createTag(name: String, color: Color) {
        let context = container.viewContext
        
        context.perform {
            let tag = Tag(context: context)
            
            tag.name = name
            tag.color = UIColor(color)
            
            self.save()
        }
    }
    
}
