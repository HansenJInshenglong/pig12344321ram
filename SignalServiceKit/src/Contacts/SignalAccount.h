//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@class Contact;
@class SignalRecipient;
@class SignalServiceAddress;

// This class represents a single valid Signal account.
//
// * Contacts with multiple signal accounts will correspond to
//   multiple instances of SignalAccount.
// * For non-contacts, the contact property will be nil.
@interface SignalAccount : BaseModel

/// An E164 value identifying the signal account.
@property (nullable, nonatomic, readonly) NSString *recipientPhoneNumber;

/// A UUID identifying the signal account.
@property (nullable, nonatomic, readonly) NSString *recipientUUID;

/// An address representing the signal account. This will be
/// the UUID, if defined, otherwise it will be the E164 number.
@property (nonatomic, readonly) SignalServiceAddress *recipientAddress;

// This property is optional and will not be set for
// non-contact account.
@property (nonatomic, nullable) Contact *contact;

@property (nonatomic) BOOL hasMultipleAccountContact;

// For contacts with more than one signal account,
// this is a label for the account.
@property (nonatomic) NSString *multipleAccountLabelText;

- (nullable NSString *)contactFullName;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSignalRecipient:(SignalRecipient *)signalRecipient;

- (instancetype)initWithSignalServiceAddress:(SignalServiceAddress *)address NS_SWIFT_NAME(init(address:));

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
            accountSchemaVersion:(NSUInteger)accountSchemaVersion
                         contact:(nullable Contact *)contact
       hasMultipleAccountContact:(BOOL)hasMultipleAccountContact
        multipleAccountLabelText:(NSString *)multipleAccountLabelText
            recipientPhoneNumber:(nullable NSString *)recipientPhoneNumber
                   recipientUUID:(nullable NSString *)recipientUUID
NS_SWIFT_NAME(init(uniqueId:accountSchemaVersion:contact:hasMultipleAccountContact:multipleAccountLabelText:recipientPhoneNumber:recipientUUID:));

// clang-format on

// --- CODE GENERATION MARKER

@end

NS_ASSUME_NONNULL_END