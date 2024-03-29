//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import <SignalMessaging/OWSTextView.h>

NS_ASSUME_NONNULL_BEGIN

@class SignalAttachment;

@protocol ConversationInputTextViewDelegate <NSObject>

- (void)didPasteAttachment:(SignalAttachment *_Nullable)attachment;

- (void)inputTextViewSendMessagePressed;

- (void)textViewDidChange:(UITextView *)textView;

/**
 * 输入了@
 */
- (void)textViewInputMentionText;

/**
 * 编辑删除@
 */
- (void)textViewDeleteMentionText;

@end

#pragma mark -

@protocol ConversationTextViewToolbarDelegate <NSObject>

- (void)textViewDidChange:(UITextView *)textView;

- (void)textViewDidChangeSelection:(UITextView *)textView;

- (void)textViewDidBecomeFirstResponder:(UITextView *)textView;

@end

#pragma mark -

@interface ConversationInputTextView : OWSTextView

@property (weak, nonatomic) id<ConversationInputTextViewDelegate> inputTextViewDelegate;

@property (weak, nonatomic) id<ConversationTextViewToolbarDelegate> textViewToolbarDelegate;

- (NSString *)trimmedText;

@end

NS_ASSUME_NONNULL_END
