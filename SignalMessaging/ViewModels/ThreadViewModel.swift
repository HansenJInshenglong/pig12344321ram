//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class ThreadViewModel: NSObject {
    @objc public let hasUnreadMessages: Bool
    @objc public let lastMessageDate: Date?
    @objc public let isGroupThread: Bool
    @objc public let threadRecord: TSThread
    @objc public let unreadCount: UInt
    @objc public let contactAddress: SignalServiceAddress?
    @objc public let name: String
    @objc public let isMuted: Bool
    @objc public let hasPendingMessageRequest: Bool
    
//    @objc public let message: PigramContactMessage?
    /**1 == 申请  2 == 同意  3 == 拒绝 4 == ack*/
    @objc public var inviteAction: Int
    ///好友请是否是我发送的
    @objc public var inviteActionIsSentByMe: Bool;
    
    var isContactThread: Bool {
        return !isGroupThread
    }

    @objc public var lastMessageText: String?
    @objc public let lastMessageForInbox: TSInteraction?

    @objc
    public init(thread: TSThread, transaction: SDSAnyReadTransaction) {
        
        self.threadRecord = thread
        self.isGroupThread = thread.isGroupThread()
        self.name = Environment.shared.contactsManager.displayName(for: thread, transaction: transaction)
        //是否静音
        self.isMuted = thread.isMuted
        self.lastMessageText = thread.lastMessageText(transaction: transaction)
        let lastInteraction = thread.lastInteractionForInbox(transaction: transaction)
        self.lastMessageForInbox = lastInteraction
        self.lastMessageDate = lastInteraction?.receivedAtDate()
        self.inviteAction = 0;
        self.inviteActionIsSentByMe = false;
        if let contactThread = thread as? TSContactThread {
            self.contactAddress = contactThread.contactAddress
            
        } else {
            self.contactAddress = nil
        }
        
        self.unreadCount = InteractionFinder(threadUniqueId: thread.uniqueId).unreadCount(transaction: transaction)
        self.hasUnreadMessages = unreadCount > 0
        self.hasPendingMessageRequest = ThreadUtil.hasPendingMessageRequest(thread, transaction: transaction)
        
       
    }
    
    
    
    @objc
    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherThread = object as? ThreadViewModel else {
            return super.isEqual(object)
        }

        return threadRecord.isEqual(otherThread.threadRecord)
    }
}
