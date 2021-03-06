//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_CLOSED_ENUM(NSUInteger, OWSVerificationState) {
    OWSVerificationStateDefault,
    OWSVerificationStateVerified,
    OWSVerificationStateNoLongerVerified,
};

@class SDSAnyWriteTransaction;
@class SSKProtoVerified;
@class SignalServiceAddress;

NSString *OWSVerificationStateToString(OWSVerificationState verificationState);
SSKProtoVerified *_Nullable BuildVerifiedProtoWithAddress(SignalServiceAddress *destinationAddress,
    NSData *identityKey,
    OWSVerificationState verificationState,
    NSUInteger paddingBytesLength);

@interface OWSRecipientIdentity : BaseModel

@property (nonatomic, readonly) NSString *accountId;
@property (nonatomic, readonly) NSData *identityKey;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, readonly) BOOL isFirstKnownKey;

#pragma mark - Verification State

@property (atomic, readonly) OWSVerificationState verificationState;

- (void)updateWithVerificationState:(OWSVerificationState)verificationState
                        transaction:(SDSAnyWriteTransaction *)transaction;

#pragma mark - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithUniqueId:(NSString *)uniqueId NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithAccountId:(NSString *)accountId
                      identityKey:(NSData *)identityKey
                  isFirstKnownKey:(BOOL)isFirstKnownKey
                        createdAt:(NSDate *)createdAt
                verificationState:(OWSVerificationState)verificationState NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                       accountId:(NSString *)accountId
                       createdAt:(NSDate *)createdAt
                     identityKey:(NSData *)identityKey
                 isFirstKnownKey:(BOOL)isFirstKnownKey
  recipientIdentitySchemaVersion:(NSUInteger)recipientIdentitySchemaVersion
               verificationState:(OWSVerificationState)verificationState
NS_SWIFT_NAME(init(uniqueId:accountId:createdAt:identityKey:isFirstKnownKey:recipientIdentitySchemaVersion:verificationState:));

// clang-format on

// --- CODE GENERATION MARKER

#pragma mark - debug

+ (void)printAllIdentities;

@end

NS_ASSUME_NONNULL_END
