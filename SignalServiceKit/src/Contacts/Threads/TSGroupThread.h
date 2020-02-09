//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "TSGroupModel.h"
#import "TSThread.h"

NS_ASSUME_NONNULL_BEGIN

@class SDSAnyReadTransaction;
@class SDSAnyWriteTransaction;
@class TSAttachmentStream;

extern NSString *const TSGroupThreadAvatarChangedNotification;
extern NSString *const TSGroupThread_NotificationKey_UniqueId;

@interface TSGroupThread : TSThread

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                    archivalDate:(nullable NSDate *)archivalDate
       archivedAsOfMessageSortId:(nullable NSNumber *)archivedAsOfMessageSortId
           conversationColorName:(ConversationColorName)conversationColorName
                    creationDate:(nullable NSDate *)creationDate
isArchivedByLegacyTimestampForSorting:(BOOL)isArchivedByLegacyTimestampForSorting
                 lastMessageDate:(nullable NSDate *)lastMessageDate
                    messageDraft:(nullable NSString *)messageDraft
                  mutedUntilDate:(nullable NSDate *)mutedUntilDate
                           rowId:(int64_t)rowId
           shouldThreadBeVisible:(BOOL)shouldThreadBeVisible
                      groupModel:(TSGroupModel *)groupModel
NS_SWIFT_NAME(init(uniqueId:archivalDate:archivedAsOfMessageSortId:conversationColorName:creationDate:isArchivedByLegacyTimestampForSorting:lastMessageDate:messageDraft:mutedUntilDate:rowId:shouldThreadBeVisible:groupModel:));

// clang-format on

// --- CODE GENERATION MARKER

@property (nonatomic, strong) TSGroupModel *groupModel;

// TODO: We might want to make this initializer private once we
//       convert getOrCreateThreadWithContactId to take "any" transaction.
- (instancetype)initWithGroupModel:(TSGroupModel *)groupModel;

+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel;
+ (instancetype)getOrCreateThreadWithGroupModel:(TSGroupModel *)groupModel
                                    transaction:(SDSAnyWriteTransaction *)transaction;

+ (instancetype)getOrCreateThreadWithGroupId:(NSString *)groupId;
+ (instancetype)getOrCreateThreadWithGroupId:(NSString *)groupId transaction:(SDSAnyWriteTransaction *)transaction;

+ (nullable instancetype)threadWithGroupId:(NSString *)groupId transaction:(SDSAnyReadTransaction *)transaction;

+ (NSString *)threadIdFromGroupId:(NSString *)groupId;

@property (nonatomic, readonly) NSString *groupNameOrDefault;
@property (class, nonatomic, readonly) NSString *defaultGroupName;

- (BOOL)isLocalUserInGroup;

// all group threads containing recipient as a member
+ (NSArray<TSGroupThread *> *)groupThreadsWithAddress:(SignalServiceAddress *)address
                                          transaction:(SDSAnyReadTransaction *)transaction;

- (void)leaveGroupWithSneakyTransaction;
- (void)leaveGroupWithTransaction:(SDSAnyWriteTransaction *)transaction;

#pragma mark - Avatar

- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream;
- (void)updateAvatarWithAttachmentStream:(TSAttachmentStream *)attachmentStream
                             transaction:(SDSAnyWriteTransaction *)transaction;

- (void)fireAvatarChangedNotification;

+ (ConversationColorName)defaultConversationColorNameForGroupId:(NSString *)groupId;

/**
 * 是否被禁言
 */
- (BOOL)isBlockedMessage;
@end

NS_ASSUME_NONNULL_END
