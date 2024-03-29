//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "TSIncomingMessage.h"
#import "NSNotificationCenter+OWS.h"
#import "OWSDisappearingMessagesConfiguration.h"
#import "OWSDisappearingMessagesJob.h"
#import "OWSReadReceiptManager.h"
#import "TSAttachmentPointer.h"
#import "TSContactThread.h"
#import "TSDatabaseSecondaryIndexes.h"
#import "TSGroupThread.h"
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSIncomingMessage ()

@property (nonatomic, getter=wasRead) BOOL read;

//@property (nonatomic, nullable) NSNumber *serverTimestamp;
@property (nonatomic, readonly) NSUInteger incomingMessageSchemaVersion;

@end

#pragma mark -

const NSUInteger TSIncomingMessageSchemaVersion = 1;

@implementation TSIncomingMessage

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (_incomingMessageSchemaVersion < 1) {
        _authorPhoneNumber = [coder decodeObjectForKey:@"authorId"];
        if (_authorPhoneNumber == nil) {
            _authorPhoneNumber = [TSContactThread legacyContactPhoneNumberFromThreadId:self.uniqueThreadId];
        }
    }

    _incomingMessageSchemaVersion = TSIncomingMessageSchemaVersion;

    return self;
}

- (instancetype)initIncomingMessageWithTimestamp:(uint64_t)timestamp
                                        inThread:(TSThread *)thread
                                   authorAddress:(SignalServiceAddress *)authorAddress
                                  sourceDeviceId:(uint32_t)sourceDeviceId
                                     messageBody:(nullable NSString *)body
                                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                                expiresInSeconds:(uint32_t)expiresInSeconds
                                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
                                    contactShare:(nullable OWSContact *)contactShare
                                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                                  messageSticker:(nullable MessageSticker *)messageSticker
                                 serverTimestamp:(nullable NSNumber *)serverTimestamp
                                 wasReceivedByUD:(BOOL)wasReceivedByUD
                               isViewOnceMessage:(BOOL)isViewOnceMessage
{
    self = [super initMessageWithTimestamp:timestamp
                                  inThread:thread
                               messageBody:body
                             attachmentIds:attachmentIds
                          expiresInSeconds:expiresInSeconds
                           expireStartedAt:0
                             quotedMessage:quotedMessage
                              contactShare:contactShare
                               linkPreview:linkPreview
                            messageSticker:messageSticker
                         isViewOnceMessage:isViewOnceMessage];

    if (!self) {
        return self;
    }
    [self setUniqueId_PG:[NSString stringWithFormat:@"%@-%@",authorAddress.phoneNumber ?: self.uniqueId,serverTimestamp ?: @(timestamp)]];
    _authorPhoneNumber = authorAddress.phoneNumber;
    _authorUUID = authorAddress.uuidString;

    _sourceDeviceId = sourceDeviceId;
    _read = NO;
    self.serverTimestamp = serverTimestamp;
    _wasReceivedByUD = wasReceivedByUD;

    _incomingMessageSchemaVersion = TSIncomingMessageSchemaVersion;

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
                   schemaVersion:(NSUInteger)schemaVersion
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
               authorPhoneNumber:(nullable NSString *)authorPhoneNumber
                      authorUUID:(nullable NSString *)authorUUID
    incomingMessageSchemaVersion:(NSUInteger)incomingMessageSchemaVersion
                            read:(BOOL)read
                 serverTimestamp:(nullable NSNumber *)serverTimestamp
                  sourceDeviceId:(unsigned int)sourceDeviceId
                 wasReceivedByUD:(BOOL)wasReceivedByUD
{
    self = [super initWithUniqueId:uniqueId
               receivedAtTimestamp:receivedAtTimestamp
                            sortId:sortId
                         timestamp:timestamp
                    uniqueThreadId:uniqueThreadId
                     attachmentIds:attachmentIds
                              body:body
                      contactShare:contactShare
                   expireStartedAt:expireStartedAt
                         expiresAt:expiresAt
                  expiresInSeconds:expiresInSeconds
                isViewOnceComplete:isViewOnceComplete
                 isViewOnceMessage:isViewOnceMessage
                       linkPreview:linkPreview
                    messageSticker:messageSticker
                     quotedMessage:quotedMessage
                     schemaVersion:schemaVersion
      storedShouldStartExpireTimer:storedShouldStartExpireTimer];

    if (!self) {
        return self;
    }

    _authorPhoneNumber = authorPhoneNumber;
    _authorUUID = authorUUID;
    _incomingMessageSchemaVersion = incomingMessageSchemaVersion;
    _read = read;
    self.serverTimestamp = serverTimestamp;
    _sourceDeviceId = sourceDeviceId;
    _wasReceivedByUD = wasReceivedByUD;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (OWSInteractionType)interactionType
{
    
    return OWSInteractionType_IncomingMessage;
}

#pragma mark - OWSReadTracking

- (BOOL)shouldAffectUnreadCounts
{
    return YES;
}

- (void)markAsReadNowWithSendReadReceipt:(BOOL)sendReadReceipt transaction:(SDSAnyWriteTransaction *)transaction
{
    [self markAsReadAtTimestamp:[NSDate ows_millisecondTimeStamp]
                sendReadReceipt:sendReadReceipt
                    transaction:transaction];
}

- (void)markAsReadAtTimestamp:(uint64_t)readTimestamp
              sendReadReceipt:(BOOL)sendReadReceipt
                  transaction:(SDSAnyWriteTransaction *)transaction
{
    OWSAssertDebug(transaction);

    if (self.read && readTimestamp >= self.expireStartedAt) {
        return;
    }

    NSTimeInterval secondsAgoRead = ((NSTimeInterval)[NSDate ows_millisecondTimeStamp] - (NSTimeInterval)readTimestamp) / 1000;
    OWSLogDebug(@"marking uniqueId: %@  which has timestamp: %llu as read: %f seconds ago",
        self.uniqueId,
        self.timestamp,
        secondsAgoRead);

    [self anyUpdateIncomingMessageWithTransaction:transaction
                                            block:^(TSIncomingMessage *message) {
                                                message.read = YES;
                                            }];

    [transaction addCompletionWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationNameAsync:kIncomingMessageMarkedAsReadNotification
                                                                 object:self];
    }];

    [[OWSDisappearingMessagesJob sharedJob] startAnyExpirationForMessage:self
                                                     expirationStartedAt:readTimestamp
                                                             transaction:transaction];

    if (sendReadReceipt) {
        [OWSReadReceiptManager.sharedManager messageWasReadLocally:self];
    }
}

- (void)markMentionMessageAsReadWithMessageId:(NSString *)messageId {
    
    if (self.isMentionedMe == false && self.isMentionedAll == false) {
        return;
    }
    
    [SSKEnvironment.shared.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction * _Nonnull write) {
        [self anyUpdateIncomingMessageWithTransaction:write
                                                block:^(TSIncomingMessage *message) {
            message.isMentionedAll = false;
            message.isMentionedMe = false;
        }];
    }];

       
}

- (SignalServiceAddress *)authorAddress
{
    return [[SignalServiceAddress alloc] initWithPhoneNumber:self.authorPhoneNumber];
}

- (NSComparisonResult)compareForSorting:(TSInteraction *)other {

    if (other.interactionType != OWSInteractionType_IncomingMessage) {
        return [super compareForSorting:other];
    }
    OWSAssertDebug(other);
    TSIncomingMessage *otherIncoming = (TSIncomingMessage *)other;
    NSTimeInterval sortId1 = [self.serverTimestamp doubleValue];
    NSTimeInterval sortId2 = otherIncoming.serverTimestamp > 0 ? [otherIncoming.serverTimestamp doubleValue] : otherIncoming.timestamp;

    if (sortId1 > sortId2) {
        return NSOrderedDescending;
    } else if (sortId1 < sortId2) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}


- (TSOutgoingMessage *)convertMessageToNewOutgoingMessageWithThread:(TSThread *)thread {
    
    NSString *messageBody = self.body;
    
    BOOL isVoiceMessage = false;
    __block TSAttachmentStream *attachmentStream = nil;
    if (self.attachmentIds.count > 0) {
        [self.databaseStorage readWithBlock:^(SDSAnyReadTransaction *transaction) {
            attachmentStream =
                [TSAttachmentStream anyFetchAttachmentStreamWithUniqueId:self.attachmentIds.lastObject transaction:transaction];
        }];
        isVoiceMessage = attachmentStream.isVoiceMessage;
    }
    TSOutgoingMessage *message = [[TSOutgoingMessage alloc] initOutgoingMessageWithTimestamp:[NSDate ows_millisecondTimeStamp] inThread:thread messageBody:messageBody attachmentIds:self.attachmentIds.mutableCopy expiresInSeconds:self.expiresInSeconds expireStartedAt:self.expireStartedAt isVoiceMessage:isVoiceMessage groupMetaMessage:TSGroupMetaMessageUnspecified quotedMessage:self.quotedMessage contactShare:nil linkPreview:self.linkPreview messageSticker:self.messageSticker isViewOnceMessage:false];
    message.messageShare = self.messageShare;
    
    return message;
    
}
- (void)setIsOffline:(BOOL)isOffline {
    _isOffline = isOffline;
    if (_isOffline) {
        [self setUniqueId_PG:[NSString stringWithFormat:@"%@.offline",self.uniqueId]];
    }
}
@end

@implementation PGGroupApplyIncomingMessage
 
- (OWSInteractionType)interactionType
{
    
    return OWSInteractionType_GroupJoin;
}

- (BOOL)shouldAffectUnreadCounts {
    return  false;
}
@end

NS_ASSUME_NONNULL_END
