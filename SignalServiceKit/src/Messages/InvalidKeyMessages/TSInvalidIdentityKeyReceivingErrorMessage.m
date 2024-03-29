//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "TSInvalidIdentityKeyReceivingErrorMessage.h"
#import "OWSFingerprint.h"
#import "OWSIdentityManager.h"
#import "OWSMessageManager.h"
#import "OWSMessageReceiver.h"
#import "SSKEnvironment.h"
#import "SSKSessionStore.h"
#import "TSContactThread.h"
#import "TSErrorMessage_privateConstructor.h"
#import <AxolotlKit/NSData+keyVersionByte.h>
#import <AxolotlKit/PreKeyWhisperMessage.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((deprecated)) @interface TSInvalidIdentityKeyReceivingErrorMessage()

@property (nonatomic, readonly, copy) NSString *authorId;

@property (atomic, nullable) NSData *envelopeData;

@end

#pragma mark -

@implementation TSInvalidIdentityKeyReceivingErrorMessage {
    // Not using a property declaration in order to exclude from DB serialization
    SSKProtoEnvelope *_Nullable _envelope;
}

#ifdef DEBUG
// We no longer create these messages, but they might exist on legacy clients so it's useful to be able to
// create them with the debug UI
+ (nullable instancetype)untrustedKeyWithEnvelope:(SSKProtoEnvelope *)envelope
                                  withTransaction:(SDSAnyWriteTransaction *)transaction
{
    TSContactThread *contactThread =
        [TSContactThread getOrCreateThreadWithContactAddress:envelope.sourceAddress transaction:transaction];

    // Legit usage of senderTimestamp, references message which failed to decrypt
    TSInvalidIdentityKeyReceivingErrorMessage *errorMessage =
        [[self alloc] initForUnknownIdentityKeyWithTimestamp:envelope.timestamp
                                                    inThread:contactThread
                                            incomingEnvelope:envelope];
    return errorMessage;
}

- (nullable instancetype)initForUnknownIdentityKeyWithTimestamp:(uint64_t)timestamp
                                                       inThread:(TSThread *)thread
                                               incomingEnvelope:(SSKProtoEnvelope *)envelope
{
    self = [self initWithTimestamp:timestamp inThread:thread failedMessageType:TSErrorMessageWrongTrustedIdentityKey];
    if (!self) {
        return self;
    }
    
    NSError *error;
    _envelopeData = [envelope serializedDataAndReturnError:&error];
    if (!_envelopeData || error != nil) {
        OWSFailDebug(@"failure: envelope data failed with error: %@", error);
        return nil;
    }

    _authorId = envelope.sourceId;

    return self;
}
#endif

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
       errorMessageSchemaVersion:(NSUInteger)errorMessageSchemaVersion
                       errorType:(TSErrorMessageType)errorType
                            read:(BOOL)read
                recipientAddress:(nullable SignalServiceAddress *)recipientAddress
                        authorId:(NSString *)authorId
                    envelopeData:(nullable NSData *)envelopeData
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
      storedShouldStartExpireTimer:storedShouldStartExpireTimer
         errorMessageSchemaVersion:errorMessageSchemaVersion
                         errorType:errorType
                              read:read
                  recipientAddress:recipientAddress];

    if (!self) {
        return self;
    }

    _authorId = authorId;
    _envelopeData = envelopeData;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (nullable SSKProtoEnvelope *)envelope
{
    if (!_envelope) {
        NSError *error;
        SSKProtoEnvelope *_Nullable envelope = [SSKProtoEnvelope parseData:self.envelopeData error:&error];
        if (error || envelope == nil) {
            OWSFailDebug(@"Could not parse proto: %@", error);
        } else {
            _envelope = envelope;
        }
    }
    return _envelope;
}

- (void)throws_acceptNewIdentityKey
{
    OWSAssertIsOnMainThread();

    if (self.errorType != TSErrorMessageWrongTrustedIdentityKey) {
        OWSLogError(@"Refusing to accept identity key for anything but a Key error.");
        return;
    }

    NSData *_Nullable newKey = [self throws_newIdentityKey];
    if (!newKey) {
        OWSFailDebug(@"Couldn't extract identity key to accept");
        return;
    }

    [[OWSIdentityManager sharedManager] saveRemoteIdentity:newKey address:self.envelope.sourceAddress];

    // Decrypt this and any old messages for the newly accepted key
    NSArray<TSInvalidIdentityKeyReceivingErrorMessage *> *messagesToDecrypt =
        [self.threadWithSneakyTransaction receivedMessagesForInvalidKey:newKey];

    for (TSInvalidIdentityKeyReceivingErrorMessage *errorMessage in messagesToDecrypt) {
        [SSKEnvironment.shared.messageReceiver handleReceivedEnvelopeData:errorMessage.envelopeData];

        // Here we remove the existing error message because handleReceivedEnvelope will either
        //  1.) succeed and create a new successful message in the thread or...
        //  2.) fail and create a new identical error message in the thread.
        [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
            [errorMessage anyRemoveWithTransaction:transaction];
        }];
    }
}

- (nullable NSData *)throws_newIdentityKey
{
    if (!self.envelope) {
        OWSLogError(@"Error message had no envelope data to extract key from");
        return nil;
    }
    if (!self.envelope.hasType) {
        OWSLogError(@"Error message envelope is missing type.");
        return nil;
    }
    NSData *pkwmData = self.envelope.content;
    if (!pkwmData) {
        OWSLogError(@"Ignoring acceptNewIdentityKey for empty message");
        return nil;
    }

    PreKeyWhisperMessage *message = [[PreKeyWhisperMessage alloc] init_throws_withData:pkwmData];
    return [message.identityKey throws_removeKeyType];
}

- (NSString *)theirSignalId
{
    if (self.authorId) {
        return self.authorId;
    } else {
        // for existing messages before we were storing author id.
        return self.envelope.sourceId;
    }
}

@end

NS_ASSUME_NONNULL_END
