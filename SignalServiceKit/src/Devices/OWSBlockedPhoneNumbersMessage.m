//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSBlockedPhoneNumbersMessage.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSBlockedPhoneNumbersMessage ()

@property (nonatomic, readonly) NSArray<NSString *> *phoneNumbers;
@property (nonatomic, readonly) NSArray<NSString *> *uuids;
@property (nonatomic, readonly) NSArray<NSString *> *groupIds;

@end

@implementation OWSBlockedPhoneNumbersMessage

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (instancetype)initWithThread:(TSThread *)thread
                  phoneNumbers:(NSArray<NSString *> *)phoneNumbers
                         uuids:(NSArray<NSString *> *)uuids
                      groupIds:(NSArray<NSString *> *)groupIds
{
    self = [super initWithThread:thread];
    if (!self) {
        return self;
    }

    _phoneNumbers = [phoneNumbers copy];
    _uuids = [uuids copy];
    _groupIds = [groupIds copy];

    return self;
}

- (nullable SSKProtoSyncMessageBuilder *)syncMessageBuilder
{
    SSKProtoSyncMessageBlockedBuilder *blockedBuilder = [SSKProtoSyncMessageBlocked builder];
    [blockedBuilder setNumbers:_phoneNumbers];
    [blockedBuilder setGroupIds:_groupIds];

    NSError *error;
    SSKProtoSyncMessageBlocked *_Nullable blockedProto = [blockedBuilder buildAndReturnError:&error];
    if (error || !blockedProto) {
        OWSFailDebug(@"could not build protobuf: %@", error);
        return nil;
    }

    SSKProtoSyncMessageBuilder *syncMessageBuilder = [SSKProtoSyncMessage builder];
    [syncMessageBuilder setBlocked:blockedProto];
    return syncMessageBuilder;
}

@end

NS_ASSUME_NONNULL_END
