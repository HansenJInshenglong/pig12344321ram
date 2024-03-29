//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
protocol MessageActionsDelegate: class {
    func messageActionsShowDetailsForItem(_ conversationViewItem: ConversationViewItem)
    func messageActionsReplyToItem(_ conversationViewItem: ConversationViewItem)
    func messageActionsQRImageToItem(_ conversationViewItem: ConversationViewItem)
    func messageActionsRevokeMessageToItem(_ conversationViewItem: ConversationViewItem)
    func messageActionsTranspondMessageToItem(_ conversationViewItem: ConversationViewItem)

}

struct MessageActionBuilder {
    static func QRImage(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
           return MenuAction(image: #imageLiteral(resourceName: "pigram-nav-qr"),
                             title: kPigramLocalizeString("识别图中二维码", nil),
                             subtitle: nil,
                             accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "QR"),
                             block: { [weak delegate] (_) in
                               delegate?.messageActionsQRImageToItem(conversationViewItem)

           })
       }
    
    static func reply(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "ic_reply"),
                          title: NSLocalizedString("MESSAGE_ACTION_REPLY", comment: "Action sheet button title"),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "reply"),
                          block: { [weak delegate] (_) in
                            delegate?.messageActionsReplyToItem(conversationViewItem)

        })
    }

    static func copyText(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "ic_copy"),
                          title: NSLocalizedString("MESSAGE_ACTION_COPY_TEXT", comment: "Action sheet button title"),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "copy_text"),
                          block: { (_) in
                            conversationViewItem.copyTextAction()
        })
    }

    static func showDetails(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "ic_info"),
                          title: NSLocalizedString("MESSAGE_ACTION_DETAILS", comment: "Action sheet button title"),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "show_details"),
                          block: { [weak delegate] (_) in
                            delegate?.messageActionsShowDetailsForItem(conversationViewItem)
        })
    }

    static func deleteMessage(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "ic_trash"),
                          title: NSLocalizedString("MESSAGE_ACTION_DELETE_MESSAGE", comment: "Action sheet button title"),
                          subtitle: NSLocalizedString("MESSAGE_ACTION_DELETE_MESSAGE_SUBTITLE", comment: "Action sheet button subtitle"),
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "delete_message"),
                          block: { (_) in
                            conversationViewItem.deleteAction()
        })
    }

    static func copyMedia(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "image_editor_rotate"),
                          title: NSLocalizedString("MESSAGE_ACTION_COPY_MEDIA", comment: "Action sheet button title"),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "copy_media"),
                          block: { (_) in
                            conversationViewItem.copyMediaAction()
        })
    }

    static func saveMedia(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "download-filled-24.png"),
                          title: NSLocalizedString("MESSAGE_ACTION_SAVE_MEDIA", comment: "Action sheet button title"),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "save_media"),
                          block: { (_) in
                            conversationViewItem.saveMediaAction()
        })
    }
    
    static func revokeMessage(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "ic_switch_camera"),
                          title: kPigramLocalizeString("撤回消息", nil),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "btnRefresh--white"),
                          block: { [weak delegate] (_) in
                            delegate?.messageActionsRevokeMessageToItem(conversationViewItem)

        })
    }
    static func transpondMessage(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction {
        return MenuAction(image: #imageLiteral(resourceName: "reply-filled-24"),
                          title: kPigramLocalizeString("转发消息", nil),
                          subtitle: nil,
                          accessibilityIdentifier: UIView.accessibilityIdentifier(containerName: "message_action", name: "btnRefresh--white"),
                          block: { [weak delegate] (_) in
                            delegate?.messageActionsTranspondMessageToItem(conversationViewItem)

        })
    }
}

@objc
class ConversationViewItemActions: NSObject {

    @objc
    class func textActions(conversationViewItem: ConversationViewItem, shouldAllowReply: Bool, delegate: MessageActionsDelegate) -> [MenuAction] {
        var actions: [MenuAction] = []

        if shouldAllowReply {
            let replyAction = MessageActionBuilder.reply(conversationViewItem: conversationViewItem, delegate: delegate)
            actions.append(replyAction)
        }

        if conversationViewItem.hasBodyTextActionContent {
            let copyTextAction = MessageActionBuilder.copyText(conversationViewItem: conversationViewItem, delegate: delegate)
            actions.append(copyTextAction)
        }

        let deleteAction = MessageActionBuilder.deleteMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(deleteAction)

        let showDetailsAction = MessageActionBuilder.showDetails(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(showDetailsAction)
        
        if let revokeAction = self.createRevokeAction(conversationViewItem: conversationViewItem, delegate: delegate) {
            actions.append(revokeAction);
        }
        let transpond = MessageActionBuilder.transpondMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(transpond)
        
        return actions
    }

    @objc
    class func mediaActions(conversationViewItem: ConversationViewItem, shouldAllowReply: Bool, delegate: MessageActionsDelegate) -> [MenuAction] {
        var actions: [MenuAction] = []

        if shouldAllowReply {
            let replyAction = MessageActionBuilder.reply(conversationViewItem: conversationViewItem, delegate: delegate)
            actions.append(replyAction)
        }

        if conversationViewItem.hasMediaActionContent {
            if conversationViewItem.canCopyMedia() {
                let copyMediaAction = MessageActionBuilder.copyMedia(conversationViewItem: conversationViewItem, delegate: delegate)
                actions.append(copyMediaAction)
            }
            if conversationViewItem.canSaveMedia() {
                let saveMediaAction = MessageActionBuilder.saveMedia(conversationViewItem: conversationViewItem, delegate: delegate)
                actions.append(saveMediaAction)
            }
            let action = MessageActionBuilder.QRImage(conversationViewItem: conversationViewItem, delegate: delegate);
            actions.append(action);
        }

        let deleteAction = MessageActionBuilder.deleteMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(deleteAction)

        let showDetailsAction = MessageActionBuilder.showDetails(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(showDetailsAction)
        
        if let revokeAction = self.createRevokeAction(conversationViewItem: conversationViewItem, delegate: delegate) {
            actions.append(revokeAction);
        }
        let transpond = MessageActionBuilder.transpondMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(transpond);
        
        return actions
    }

    @objc
    class func quotedMessageActions(conversationViewItem: ConversationViewItem, shouldAllowReply: Bool, delegate: MessageActionsDelegate) -> [MenuAction] {
        var actions: [MenuAction] = []

        if shouldAllowReply {
            let replyAction = MessageActionBuilder.reply(conversationViewItem: conversationViewItem, delegate: delegate)
            actions.append(replyAction)
        }

        let deleteAction = MessageActionBuilder.deleteMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(deleteAction)

        let showDetailsAction = MessageActionBuilder.showDetails(conversationViewItem: conversationViewItem, delegate: delegate)
        actions.append(showDetailsAction)
        
        if let revokeAction = self.createRevokeAction(conversationViewItem: conversationViewItem, delegate: delegate) {
            actions.append(revokeAction);
        }

        return actions
    }

    @objc
    class func infoMessageActions(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> [MenuAction] {
        let deleteAction = MessageActionBuilder.deleteMessage(conversationViewItem: conversationViewItem, delegate: delegate)
        return [deleteAction ]
    }
   
    
    private class func createRevokeAction(conversationViewItem: ConversationViewItem, delegate: MessageActionsDelegate) -> MenuAction? {
        
        var canRevoke = false;
        if conversationViewItem.thread.isGroupThread() {
            canRevoke = true;
        } else {
            if conversationViewItem.interaction.interactionType() == .outgoingMessage {
                canRevoke = true;
            }
        }
        if canRevoke {
            return MessageActionBuilder.revokeMessage(conversationViewItem: conversationViewItem, delegate: delegate);
        }

        return nil;
        
    }
}
