//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@class SDSAnyReadTransaction;
@class TSThread;

typedef NS_ENUM(NSInteger, OWSInteractionType) {
    OWSInteractionType_Unknown,
    OWSInteractionType_IncomingMessage,
    OWSInteractionType_OutgoingMessage,
    OWSInteractionType_Error,
    OWSInteractionType_Call,
    OWSInteractionType_Info,
    OWSInteractionType_TypingIndicator,
    OWSInteractionType_ThreadDetails,
    OWSInteractionType_Offer,
    ///好友邀请
    OWSInteractionType_pigramContact,
    ///名片分享
    OWSInteractionType_pigramShare,
    ///申请入群
    OWSInteractionType_GroupJoin,
    ///同意入群
    OWSInteractionType_GroupJoinHandled,
};


NSString *NSStringFromOWSInteractionType(OWSInteractionType value);

@protocol OWSPreviewText <NSObject>

- (NSString *)previewTextWithTransaction:(SDSAnyReadTransaction *)transaction;

@end

#pragma mark -

@interface TSInteraction : BaseModel

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithUniqueId:(NSString *)uniqueId timestamp:(uint64_t)timestamp inThread:(TSThread *)thread;

- (instancetype)initInteractionWithTimestamp:(uint64_t)timestamp inThread:(TSThread *)thread;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
NS_SWIFT_NAME(init(uniqueId:receivedAtTimestamp:sortId:timestamp:uniqueThreadId:));

// clang-format on

// --- CODE GENERATION MARKER

@property (nonatomic, readonly) NSString *uniqueThreadId;

@property (nonatomic, readonly) uint64_t timestamp;
@property (nonatomic, readonly) uint64_t sortId;
@property (nonatomic, readonly) uint64_t receivedAtTimestamp;

/**
 * 为了排序使用 signal只有在incoming message 才会有
 */
@property (nonatomic, nullable) NSNumber * serverTimestamp;

// This property is used to flag interactions that
// require special handling in the conversation view.
@property (nonatomic, readonly) BOOL isSpecialMessage;

- (NSDate *)receivedAtDate;

- (OWSInteractionType)interactionType;

@property (nonatomic, readonly) TSThread *threadWithSneakyTransaction;

- (TSThread *)threadWithTransaction:(SDSAnyReadTransaction *)transaction NS_SWIFT_NAME(thread(transaction:));

/**
 * When an interaction is updated, it often affects the UI for it's containing thread. Touching it's thread will notify
 * any observers so they can redraw any related UI.
 */
- (void)touchThreadWithTransaction:(SDSAnyWriteTransaction *)transaction;

#pragma mark Utility Method

// POST GRDB TODO: Remove this method.
+ (NSArray<TSInteraction *> *)ydb_interactionsWithTimestamp:(uint64_t)timestamp
                                                    ofClass:(Class)clazz
                                            withTransaction:(YapDatabaseReadTransaction *)transaction;


// POST GRDB TODO: Remove this method.
+ (NSArray<TSInteraction *> *)ydb_interactionsWithTimestamp:(uint64_t)timestamp
                                                     filter:(BOOL (^_Nonnull)(TSInteraction *))filter
                                            withTransaction:(YapDatabaseReadTransaction *)transaction;

- (uint64_t)timestampForLegacySorting;
- (NSComparisonResult)compareForSorting:(TSInteraction *)other;

// "Dynamic" interactions are not messages or static events (like
// info messages, error messages, etc.).  They are interactions
// created, updated and deleted by the views.
//
// These include block offers, "add to contact" offers,
// unseen message indicators, etc.
- (BOOL)isDynamicInteraction;

// NOTE: This is only for use by a legacy migration.
- (void)ydb_saveNextSortIdWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
    NS_SWIFT_NAME(ydb_saveNextSortId(transaction:));

/**
 * 比较t两条消息的时间戳  大于 返回true
 */
- (BOOL)compareServerTimestampWithOther:(TSInteraction *)other;

- (BOOL)isOfflineIncomingMessage;

@end

NS_ASSUME_NONNULL_END
