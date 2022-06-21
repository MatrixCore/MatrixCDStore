
import MatrixCore
import MatrixClient
import CoreData
import os.log

@available(swift, introduced: 5.6)
@available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public actor MatrixCDStore {
    internal var inMemory: Bool
    
    public static let logger = Logger(subsystem: "dev.matrixcore", category: "MatrixCDStore")
    private var notificationToken: NSObjectProtocol?
    /// A peristent history token used for fetching transactions from the store.
        private var lastToken: NSPersistentHistoryToken?
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    lazy var backgroundContext: NSManagedObjectContext = {
        var context = self.newTaskContext()
        context.name = "MatrixCDStore"
        return context
    }()
    
    lazy var container: NSPersistentContainer = {
        guard let url = Bundle.module.url(forResource: "MatrixCDStore", withExtension: "momd")
        else { fatalError("Could not get URL for CD model MatrixCDStore") }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else { fatalError("Could not load CD model") }
        
        let container = NSPersistentContainer(name: "MatrixCDStore", managedObjectModel: model)
       
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent tore description")
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                                      forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                                      forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // TODO: needed for profile settings?
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true

        #if DEBUG
            if inMemory {
                //try! MatrixStore.createPreviewData(context: container.viewContext)
            }
        #endif
        
        return container
    }()
    
    #if DEBUG
    public static let preview = MatrixCDStore(inMemory: true)
    #endif
    public static let shared = MatrixCDStore()
    
    private init(inMemory: Bool = false) {
        self.inMemory = inMemory
        
        Task {
            await self.startNotificationOberver()
        }
    }
    
    private func startNotificationOberver() async {
        self.notificationToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: nil
        ) {_ in
            Self.logger.debug("Received a persistent store remote change notification")
            Task {
                do {
                    try await self.fetchPersistentHistory()
                } catch {
                    Self.logger.warning("Error updating: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Creates and configures a private queue context.
    internal func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    func fetchPersistentHistory() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryChange"
        
        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty
            {
                self.mergePersistentHistoryChanges(from: history)
                return
            }
            
            Self.logger.debug("No persistent history transactions found.")
            throw MatrixCoreError.persistentHistoryChangeError
        }
    }
    
    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        Self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = container.viewContext
        viewContext.perform {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }
}



/*
    public func saveAccountInfo(account: Account) async throws {
        fatalError()
    }
    
    public func getAccountInfos() async throws -> [Account] {
        fatalError()
    }
    
    public func deleteAccountInfo(account: Account) async throws {
        fatalError()
    }
    
    public typealias AccountInfo = Account
    
    public typealias RoomState = ()
    
*/
