//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class ConversationMessageMapping: NSObject {

    // The desired number of the items to load BEFORE the pivot (see below).
    @objc
    public private(set) var desiredLength: UInt
    private let isNoteToSelf: Bool

    private let interactionFinder: InteractionFinder

    // When we enter a conversation, we want to load up to N interactions. This
    // is the "initial load window".
    //
    // We subsequently expand the load window in two directions using two very
    // different behaviors.
    //
    // * We expand the load window "upwards" (backwards in time) only when
    //   loadMore() is called, in "pages".
    // * We auto-expand the load window "downwards" (forward in time) to include
    //   any new interactions created after the initial load.
    //
    // We define the "pivot" as the last item in the initial load window.  This
    // value is only set once.
    //
    // For example, if you enter a conversation with messages, 1..15:
    //
    // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    //
    // We initially load just the last 5 (if 5 is the initial desired length):
    //
    // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    //                      |      pivot ^ | <-- load window
    // pivot: 15, desired length=5.
    //
    // If a few more messages (16..18) are sent or received, we'll always load
    // them immediately (they're after the pivot):
    //
    // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
    //                      |      pivot ^        | <-- load window
    // pivot: 15, desired length=5.
    //
    // To load an additional page of items (perhaps due to user scrolling
    // upward), we extend the desired length and thereby load more items
    // before the pivot.
    //
    // 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
    //           |                 pivot ^        | <-- load window
    // pivot: 15, desired length=10.
    //
    // To reiterate:
    //
    // * The pivot doesn't move.
    // * The desired length applies _before_ the pivot.
    // * Everything after the pivot is auto-loaded.
    //
    // One last  :
    //
    // After an update, we _can sometimes_ move the pivot (for perf
    // reasons), but we also adjust the "desired length" so that this
    // no effect on the load behavior.
    //
    // And note: we use the pivot's sort id, not its uniqueId, which works
    // even if the pivot itself is deleted.
    // 之前使用sortid   现在改用服务器时间戳
    private var pivotSortId: UInt64?

    private var pivotTimestamp: Double?
    @objc
    public var canLoadMore = false
    
    
    private var additionMentionMsgs:[TSInteraction] = [];

    private var serialQueue: DispatchQueue = DispatchQueue.init(label: "fectch_message_queue");
    
    @objc var initialMentions: [TSIncomingMessage] = [];
    let thread: TSThread

    @objc
    public required init(thread: TSThread, desiredLength: UInt, isNoteToSelf: Bool) {
        self.thread = thread
        self.interactionFinder = InteractionFinder(threadUniqueId: thread.uniqueId)
        self.desiredLength = desiredLength
        self.isNoteToSelf = isNoteToSelf
        
    }
    
    @objc public func initializeConversationFinder() {
//        self.serialQueue.async {
            self.allMessage.removeAll();
            kSignalDB.read(block: {  (read) in
                try? self.interactionFinder.enumerateInteractions(transaction: read) { (value, stop) in
                    self.allMessage.append(value);
                    if let incoming = value as? TSIncomingMessage {
                        if incoming.isMentionedMe || incoming.isMentionedAll {
                            self.initialMentions.append(incoming);
                        }
                    }
                }
                self.allMessage.sort { (current, next) -> Bool in
                    return current.compareServerTimestamp(withOther: next);
                }
                var messsages: [TSInteraction] = [];
                for item in self.allMessage {
                    
                    messsages.append(item);
                    if messsages.count == self.desiredLength {
                        break;
                    }
                }
                if self.allMessage.count > self.desiredLength {
                    self.canLoadMore = true;
                }
                let shouldSetPivot = self.pivotSortId == nil
                if shouldSetPivot, let newOldestInteraction = messsages.first {
                    let sortId = newOldestInteraction.sortId;
                    let timestamp = newOldestInteraction.serverTimestamp?.doubleValue ?? Double(newOldestInteraction.timestamp);
                    self.pivotSortId = sortId;
                    self.pivotTimestamp = timestamp
                }
                
                self.pivotSortId = messsages.first?.sortId;
                self.pivotTimestamp = messsages.first?.serverTimestamp?.doubleValue;
                self.loadedInteractions = messsages.reversed();
            })
//        }
     
    }
    @objc public func markAsAllMessagesToLocalRead() {
        
        DispatchQueue.global(qos: .default).async {
            var messages:[TSInteraction] = [];
            kSignalDB.read(block: {  (read) in
                try? self.interactionFinder.enumerateUnseenInteractions(transaction: read) { (value, stop) in

                    messages.append(value);
                }
            })
         
            OWSReadReceiptManager.shared().pg_markAsReadLocally(with: messages, thread: self.thread);
        }
        
        
    }
    @objc public func calculateMentionMessage(id: String) {
        
        var startIndex: Int?
        var endIndex: Int?;
        for (index,item) in self.allMessage.enumerated() {
            
            if item.uniqueId == id {
                startIndex = index;
            }
            if self.loadedUniqueIds.first == item.uniqueId {
                endIndex = index;
            }
            if startIndex != nil && endIndex != nil {
                break;
            }
            
        }
        if let startIndex = startIndex, let endIndex = endIndex {
            self.desiredLength = UInt(endIndex - startIndex + self.loadedUniqueIds.count);
        }
        
    }
    
    private var allMessage: [TSInteraction] = [];

    @objc
    private(set) var loadedInteractions: [TSInteraction] = [] {
        didSet {
//            AssertIsOnMainThread()
            loadedUniqueIds = loadedInteractions.map { $0.uniqueId }
        }
    }

    @objc
    private(set) var loadedUniqueIds: [String] = []

    @objc
    public func contains(uniqueId: String) -> Bool {
        return loadedUniqueIds.contains(uniqueId)
    }

    // This method can be used to extend the desired length
    // and update.
    @objc
    public func update(withDesiredLength desiredLength: UInt, transaction: SDSAnyReadTransaction) throws {
        assert(desiredLength >= self.desiredLength)

        self.desiredLength = desiredLength

        try update(transaction: transaction)
    }

    @objc
    var shouldShowThreadDetails: Bool {
        return !canLoadMore && !isNoteToSelf && FeatureFlags.messageRequest
    }

    // This is the core method of the class. It updates the state to
    // reflect the latest database state & the current desired length.
    @objc
    public func update(transaction: SDSAnyReadTransaction) throws {
//        AssertIsOnMainThread()

        // If we have a "pivot", load all items AFTER the pivot and up to minDesiredLength items BEFORE the pivot.
        // If we do not have a "pivot", load up to minDesiredLength BEFORE the pivot.
        var newInteractions: [TSInteraction] = []
        var canLoadMore = false
        let desiredLength = self.desiredLength
        // Not all items "count" towards the desired length. On an initial load, all items count.  Subsequently,
        // only items above the pivot count.
        var afterPivotCount: UInt = 0
        var beforePivotCount: UInt = 0
        // (void (^)(NSString *collection, NSString *key, id object, NSUInteger index, BOOL *stop))block;
        try interactionFinder.enumerateInteractions(transaction: transaction) { interaction, stopPtr in
            // Load "uncounted" items after the pivot if possible.
            //
            // As an optimization, we can skip this check (which requires
            // deserializing the interaction) if beforePivotCount is non-zero,
            // e.g. after we "pass" the pivot.
//            print("加载消息-------------------\(interaction.serverTimestamp ?? 0)  sortid === \(interaction.sortId)");
            
            if beforePivotCount == 0,
                let pivotTimestamp = self.pivotTimestamp, interaction.interactionType() == .incomingMessage {
                
                let timestamp = interaction.serverTimestamp?.doubleValue ?? Double(interaction.timestamp);
                    let isAfterPivot = timestamp > pivotTimestamp
        
                if isAfterPivot {
                    
                    newInteractions.append(interaction)
                    afterPivotCount += 1
                    return
                  
                }
            }
            if beforePivotCount == 0,
                let pivotSortId = self.pivotSortId, interaction.interactionType() == .outgoingMessage {
                let sortId = interaction.sortId;
                    let isAfterPivot = sortId > pivotSortId
                    if isAfterPivot {
                        newInteractions.append(interaction)
                        afterPivotCount += 1
                        return
                    }
            }

            // Load "counted" items unless the load window overflows.
            if beforePivotCount >= desiredLength {
                // Overflow
                canLoadMore = true
                stopPtr.pointee = true
            } else {
               
                newInteractions.append(interaction)
                beforePivotCount += 1
            }
        }
        self.canLoadMore = canLoadMore

        if self.shouldShowThreadDetails {
            // We only show the thread details if we're at the start of the conversation
            let details = ThreadDetailsInteraction(thread: self.thread,
                                                   timestamp: NSDate.ows_millisecondTimeStamp())

            self.loadedInteractions = [details] + Array(newInteractions.reversed())
        } else {
            // The items need to be reversed, since we load them in reverse order.
            self.loadedInteractions = Array(newInteractions.reversed())
        }
//        self.loadedInteractions = self.loadedInteractions.sorted(by: { (current, next) -> Bool in
////            return current.;
//            return current.serverTimestamp?.doubleValue ?? Double(current.sortId) < next.serverTimestamp?.doubleValue ?? Double(next.sortId);
//        });
        // Establish the pivot, if necessary and possible.
        //
        // Deserializing interactions is expensive. We only need to deserialize
        // interactions that are "after" the pivot.  So there would be performance
        // benefits to moving the pivot after each update to the last loaded item.
        //
        // However, this would undesirable side effects. The desired length for
        // conversations with very short disappearing message durations would
        // continuously grow as messages appeared and disappeared.
        //
        // Therefore, we only move the pivot when we've accumulated N items after
        // the pivot.  This puts an upper bound on the number of interactions we
        // have to deserialize while minimizing "load window size creep".
        let kMaxItemCountAfterPivot = 32
        let shouldSetPivot = (self.pivotSortId == nil ||
            afterPivotCount > kMaxItemCountAfterPivot)

        if shouldSetPivot, let newOldestInteraction = newInteractions.first {
            let sortId = newOldestInteraction.sortId;
            let timestamp = newOldestInteraction.serverTimestamp?.doubleValue ?? Double(newOldestInteraction.timestamp);

            // Update the pivot.
            if self.pivotTimestamp != nil {
                self.desiredLength += afterPivotCount
            }
            self.pivotSortId = sortId;
            self.pivotTimestamp = timestamp
        }
    }

    // Tries to ensure that the load window includes a given item.
    // On success, returns the index path of that item.
    // On failure, returns nil.
    @objc(ensureLoadWindowContainsUniqueId:transaction:error:)
    public func ensureLoadWindowContains(uniqueId: String,
                                         transaction: SDSAnyReadTransaction) throws -> IndexPath {
        if let oldIndex = loadedUniqueIds.firstIndex(of: uniqueId) {
            return IndexPath(row: oldIndex, section: 0)
        }

        guard let index = try interactionFinder.sortIndex(interactionUniqueId: uniqueId, transaction: transaction) else {
            throw assertionError("could not find interaction")
        }

        let threadInteractionCount = interactionFinder.count(transaction: transaction)
        guard index < threadInteractionCount else {
            throw assertionError("invalid index")
        }
        // This math doesn't take into account the number of items loaded _after_ the pivot.
        // That's fine; it's okay to load too many interactions here.
        let desiredWindowSize: UInt = threadInteractionCount - index
        try self.update(withDesiredLength: desiredWindowSize, transaction: transaction)

        guard let newIndex = loadedUniqueIds.firstIndex(of: uniqueId) else {
            throw assertionError("couldn't find new index")
        }
        return IndexPath(row: newIndex, section: 0)
    }

    @objc
    public class ConversationMessageMappingDiff: NSObject {
        @objc
        public let addedItemIds: Set<String>
        @objc
        public let removedItemIds: Set<String>
        @objc
        public let updatedItemIds: Set<String>

        init(addedItemIds: Set<String>, removedItemIds: Set<String>, updatedItemIds: Set<String>) {
            self.addedItemIds = addedItemIds
            self.removedItemIds = removedItemIds
            self.updatedItemIds = updatedItemIds
        }
    }

    // Updates and then calculates which items were inserted, removed or modified.
    @objc
    public func updateAndCalculateDiff(transaction: SDSAnyReadTransaction,
                                       updatedInteractionIds: Set<String>) throws -> ConversationMessageMappingDiff {
        let oldItemIds = Set(self.loadedUniqueIds)
        try self.update(transaction: transaction)
        let newItemIds = Set(self.loadedUniqueIds)

        //把漏掉的离线消息从newItemIds添加到要刷新的set中
//        var newUpdateIds = newItemIds.subtracting(oldItemIds);
//        newUpdateIds = newUpdateIds.filter({ (key) -> Bool in
//            return key.hasSuffix("offline");
//        })
        let removedItemIds = oldItemIds.subtracting(newItemIds);
        let addedItemIds = newItemIds.subtracting(oldItemIds)
        // We only notify for updated items that a) were previously loaded b) weren't also inserted or removed.
        //将更新的合并到要先是的离线消息
//        newUpdateIds.formSymmetricDifference(updatedInteractionIds);

        let exclusivelyUpdatedInteractionIds = updatedInteractionIds.subtracting(addedItemIds)
            .subtracting(removedItemIds)
            .intersection(oldItemIds)

        return ConversationMessageMappingDiff(addedItemIds: addedItemIds,
                                              removedItemIds: removedItemIds,
                                              updatedItemIds: exclusivelyUpdatedInteractionIds)
    }

    // For performance reasons, the database modification notifications are used
    // to determine which items were modified.  If YapDatabase ever changes the
    // structure or semantics of these notifications, we'll need to update this
    // code to reflect that.
    @objc
    public func updatedItemIds(for notifications: [NSNotification]) -> Set<String> {
        // We'll move this into the Yap adapter when addressing updates/observation
        let viewName: String = TSMessageDatabaseViewExtensionName
        let unreadViewName: String = TSUnreadDatabaseViewExtensionName;
        var updatedItemIds = Set<String>()
        var unreadItemIds = Set<String>();
        for notification in notifications {
            // Unpack the YDB notification, looking for row changes.
            guard let userInfo =
                notification.userInfo else {
                    owsFailDebug("Missing userInfo.")
                    continue
            }
            guard let viewChangesets =
                userInfo[YapDatabaseExtensionsKey] as? NSDictionary else {
                    // No changes for any views, skip.
                    continue
            }
            guard let changeset =
                viewChangesets[viewName] as? NSDictionary else {
                    // No changes for this view, skip.
                    continue
            }
            
            // This constant matches a private constant in YDB.
            let changeset_key_changes: String = "changes"
            guard let changesetChanges = changeset[changeset_key_changes] as? [Any] else {
                owsFailDebug("Missing changeset changes.")
                continue
            }
            //如果是消息的已读状态就不需要刷新
            if let unreadChangeset = viewChangesets[unreadViewName] as? NSDictionary {
                if let unreadChangesetChanges = unreadChangeset[changeset_key_changes] as? [Any] {
                    
                    for change in unreadChangesetChanges {
                        
                        if change as? YapDatabaseViewSectionChange != nil {
                            // Ignore.
                        } else if let rowChange = change as? YapDatabaseViewRowChange {
                            //                    if rowChange.collectionKey.key.hasSuffix("offline") {
                            //                        continue;
                            //                    }
                            if rowChange.type == .delete {
                                unreadItemIds.insert(rowChange.collectionKey.key)
                            }
                        } else {
                            owsFailDebug("Invalid change: \(type(of: change)).")
                            continue
                        }
                    }
                    
                }
                
            }
            for change in changesetChanges {
                if change as? YapDatabaseViewSectionChange != nil {
                    // Ignore.
                } else if let rowChange = change as? YapDatabaseViewRowChange {
//                    if rowChange.collectionKey.key.hasSuffix("offline") {
//                        continue;
//                    }
                    if !unreadItemIds.contains(rowChange.collectionKey.key) {
                        updatedItemIds.insert(rowChange.collectionKey.key)
                    }
                } else {
                    owsFailDebug("Invalid change: \(type(of: change)).")
                    continue
                }
            }
        }

        return updatedItemIds
    }

    private func assertionError(_ description: String) -> Error {
        return OWSErrorMakeAssertionError(description)
    }
}
