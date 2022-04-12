//
//  Persistence.swift
//  Shared
//
//  Created by Aoife Bradley on 2022-02-25.
//

import CoreData
import CloudKit

struct PersistenceController {
    // Makes a Singleton
    static let shared = PersistenceController()
    
    // Test Config for SwiftUI Previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.name = "Test \(i)"
        }
        let newBox = Box(context: viewContext)
        newBox.name = "A"
        newBox.status = 0
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()
        newItem.name = "Test With Box"
        newItem.box = newBox
        let newCategory = Category(context: viewContext)
        newCategory.name = "Clothing"
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
    
    // Stores CoreData so it can sync with ICloud
    let container: NSPersistentCloudKitContainer
    
    //let sharedPersistentStore: NSPersistentStore
    
    // initialiser for CoreData, optionally let it use in-memory storage
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "cache")
        
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
