//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSProvisioningMessage.h"
#import "OWSProvisioningCipher.h"
#import <AxolotlKit/NSData+keyVersionByte.h>
#import <Curve25519Kit/Curve25519.h>
#import <HKDFKit/HKDFKit.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSProvisioningMessage ()

@property (nonatomic, readonly) NSData *myPublicKey;
@property (nonatomic, readonly) NSData *myPrivateKey;
@property (nonatomic, readonly) SignalServiceAddress *accountAddress;
@property (nonatomic, readonly) NSData *theirPublicKey;
@property (nonatomic, readonly) NSData *profileKey;
@property (nonatomic, readonly) BOOL areReadReceiptsEnabled;
@property (nonatomic, readonly) NSString *provisioningCode;

@end

@implementation OWSProvisioningMessage

- (instancetype)initWithMyPublicKey:(NSData *)myPublicKey
                       myPrivateKey:(NSData *)myPrivateKey
                     theirPublicKey:(NSData *)theirPublicKey
                     accountAddress:(SignalServiceAddress *)accountAddress
                         profileKey:(NSData *)profileKey
                readReceiptsEnabled:(BOOL)areReadReceiptsEnabled
                   provisioningCode:(NSString *)provisioningCode
{
    self = [super init];
    if (!self) {
        return self;
    }

    _myPublicKey = myPublicKey;
    _myPrivateKey = myPrivateKey;
    _theirPublicKey = theirPublicKey;
    _accountAddress = accountAddress;
    _profileKey = profileKey;
    _areReadReceiptsEnabled = areReadReceiptsEnabled;
    _provisioningCode = provisioningCode;

    return self;
}

- (nullable NSData *)buildEncryptedMessageBody
{
    
    
    NSString *_Nullable userId = TSAccountManager.localUserId;
    if (!userId) {
        OWSFailDebug(@"phone number unexpectedly missing");
        return nil;
    }
    ProvisioningProtoProvisionMessageBuilder *messageBuilder = [ProvisioningProtoProvisionMessage builderWithUserId:userId provisioningCode:self.provisioningCode userAgent:@"OWI"];

    NSError *error;
    NSData *_Nullable plainTextProvisionMessage = [messageBuilder buildSerializedDataAndReturnError:&error];
    if (!plainTextProvisionMessage || error) {
        OWSFailDebug(@"could not serialize proto: %@.", error);
        return nil;
    }

    OWSProvisioningCipher *cipher = [[OWSProvisioningCipher alloc] initWithTheirPublicKey:self.theirPublicKey];
    NSData *_Nullable encryptedProvisionMessage = [cipher encrypt:plainTextProvisionMessage];
    if (encryptedProvisionMessage == nil) {
        OWSFailDebug(@"Failed to encrypt provision message");
        return nil;
    }

    // Note that this is a one-time-use *cipher* public key, not our Signal *identity* public key
    ProvisioningProtoProvisionEnvelopeBuilder *envelopeBuilder =
        [ProvisioningProtoProvisionEnvelope builderWithPublicKey:[cipher.ourPublicKey prependKeyType]
                                                            body:encryptedProvisionMessage];

    NSData *_Nullable envelopeData = [envelopeBuilder buildSerializedDataAndReturnError:&error];
    if (!envelopeData || error) {
        OWSFailDebug(@"could not serialize proto: %@.", error);
        return nil;
    }

    return envelopeData;
}

@end

NS_ASSUME_NONNULL_END
