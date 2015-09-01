//
//  YSGInviteService.m
//  YesGraphSDK
//
//  Created by Dal Rupnik on 18/08/15.
//  Copyright © 2015 YesGraph. All rights reserved.
//

@import MessageUI;

#import "YSGInviteService.h"
#import "YSGShareSheetController.h"
#import "YSGAddressBookViewController.h"
#import "YSGContactSource.h"
#import "YSGContact.h"
#import "YSGLocalContactSource.h"
#import "YSGCacheContactSource.h"
#import "YSGOnlineContactSource.h"

NSString *_Nonnull const YSGInvitePhoneContactsKey = @"YSGInvitePhoneContactsKey";
NSString *_Nonnull const YSGInviteEmailContactsKey = @"YSGInviteEmailContactsKey";
NSString *_Nonnull const YSGInviteEmailIsHTMLKey = @"YSGInviteEmailIsHTMLKey";

@interface YSGInviteService () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong, readwrite) id<YSGContactSource> contactSource;

@property (nonatomic, weak) YSGShareSheetController *viewController;
@property (nonatomic, weak) UINavigationController *addressBookNavigationController;

/*!
 *  This property stores email entries, if both should be handled
 */
@property (nonatomic, copy) NSArray <YSGContact *> *emailContacts;

@end

@implementation YSGInviteService

- (NSString *)name
{
    return @"Contacts";
}

- (instancetype)init
{
    YSGOnlineContactSource *source = [[YSGOnlineContactSource alloc] initWithClient:[YSGClient shared] localSource:[YSGLocalContactSource new] cacheSource: [YSGCacheContactSource new]];
    return [self initWithContactSource:source];
}

- (instancetype)initWithContactSource:(id<YSGContactSource>)contactSource
{
    self = [super init];
    
    if (self)
    {
        self.contactSource = contactSource;
        
        self.allowSearch = YES;
        
        self.nativeMessageSheet = YES;
        self.nativeEmailSheet = YES;
    }
    
    return self;
}

- (void)triggerServiceWithViewController:(nonnull YSGShareSheetController *)viewController
{
    [self.contactSource requestContactPermission:^(BOOL granted, NSError *error)
    {
        if (granted)
        {
            [self openInviteControllerWithController:viewController];
        }
        else if (error)
        {
            [[[UIAlertView alloc] initWithTitle:@"YesGraph" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }];
}

- (void)openInviteControllerWithController:(nonnull YSGShareSheetController *)viewController
{
    YSGAddressBookViewController *addressBookViewController = [[YSGAddressBookViewController alloc] init];
    
    addressBookViewController.service = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addressBookViewController];
    
    self.viewController = viewController;
    self.addressBookNavigationController = navigationController;
    
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)triggerInviteFlowWithContacts:(NSArray<YSGContact *> *)entries
{
    //
    // Separate email and phone entries
    //
    
    self.emailContacts = nil;
    
    NSMutableArray <YSGContact *>* phoneContacts = [NSMutableArray array];
    NSMutableArray <YSGContact *>* emailContacts = [NSMutableArray array];
    
    for (YSGContact *contact in entries)
    {
        if (contact.phones.count)
        {
            [phoneContacts addObject:contact];
        }
        else if (contact.emails.count)
        {
            [emailContacts addObject:contact];
        }
    }

    if (phoneContacts.count)
    {
        self.emailContacts = emailContacts.copy;
        
        [self triggerMessageWithContacts:phoneContacts.copy];
    }
    else if (emailContacts.count)
    {
        [self triggerEmailWithContacts:emailContacts.copy];
    }
}

- (void)triggerMessageWithContacts:(NSArray<YSGContact *> *)entries
{
    //
    // Trigger delegate
    //
    
    //
    // Check for native message sheet
    //
    
    if (!self.nativeMessageSheet || ![MFMessageComposeViewController canSendText])
    {
        if ([self.viewController.delegate respondsToSelector:@selector(shareSheetController:didShareToService:userInfo:error:)])
        {
            //
            // TODO: Add error and user info
            //
            [self.viewController.delegate shareSheetController:self.viewController didShareToService:self userInfo:nil error:nil];
        }
        
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    
    //
    // Set message
    //
    
    NSMutableArray<NSString *> * recipients = [NSMutableArray array];
    
    for (YSGContact *contact in entries
            )
    {
        [recipients addObject:contact.phones.firstObject];
    }
    
    NSDictionary *data = [self shareDataForUserInfo:@{ YSGInvitePhoneContactsKey : entries }];
    
    messageController.body = data[YSGShareSheetMessageKey];
    messageController.recipients = recipients.copy;
    
    [self.addressBookNavigationController presentViewController:messageController animated:YES completion:nil];
}

- (void)triggerEmailWithContacts:(NSArray<YSGContact *> *)entries
{
    //
    // Check for native message sheet
    //
    
    if (!self.nativeEmailSheet || ![MFMailComposeViewController canSendMail])
    {
        if ([self.viewController.delegate respondsToSelector:@selector(shareSheetController:didShareToService:userInfo:error:)])
        {
            //
            // TODO: Add error and user info
            //
            [self.viewController.delegate shareSheetController:self.viewController didShareToService:self userInfo:nil error:nil];
        }
        
        return;
    }
    
    MFMailComposeViewController *messageController = [[MFMailComposeViewController alloc] init];
    messageController.mailComposeDelegate = self;
    
    NSMutableArray<NSString *> * recipients = [NSMutableArray array];
    
    for (YSGContact *contact in entries
            )
    {
        [recipients addObject:contact.emails.firstObject];
    }
    
    NSDictionary *data = [self shareDataForUserInfo:@{ YSGInviteEmailContactsKey : entries }];
    
    [messageController setMessageBody:data[YSGShareSheetMessageKey] isHTML:[data[YSGInviteEmailIsHTMLKey] boolValue]];
    [messageController setToRecipients:recipients];
    
    [self.addressBookNavigationController presentViewController:messageController animated:YES completion:nil];
}

- (NSDictionary *)shareDataForUserInfo:(NSDictionary *)userInfo
{
    NSDictionary *data = nil;
    
    if (self.shareDataBlock)
    {
        data = self.shareDataBlock(self, userInfo);
    }
    else if ([self.viewController.delegate respondsToSelector:@selector(shareSheetController:messageForService:userInfo:)])
    {
        data = [self.viewController.delegate shareSheetController:self.viewController messageForService:self userInfo:userInfo];
    }

    return data;
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result != MessageComposeResultSent)
    {
        [controller dismissViewControllerAnimated:YES completion:nil];
        
        return;
    }
    
    [controller dismissViewControllerAnimated:NO completion:^
    {
        if (self.emailContacts.count)
        {
            [self triggerEmailWithContacts:self.emailContacts];
        }
        else
        {
            [self.addressBookNavigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result != MFMailComposeResultSaved && result != MFMailComposeResultSent)
    {
        [controller dismissViewControllerAnimated:YES completion:nil];
        
        return;
    }
    
    [controller dismissViewControllerAnimated:NO completion:^
    {
        [self.addressBookNavigationController dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
