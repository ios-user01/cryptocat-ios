//
//  TBLoginViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 21/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//
//  This file is part of Cryptocat for iOS.
//
//  Cryptocat for iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Cryptocat for iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Cryptocat for iOS.  If not, see <http://www.gnu.org/licenses/>.
//

#import "TBLoginViewController.h"
#import "TBChatViewController.h"
#import "NSString+Cryptocat.h"
#import "NSError+Cryptocat.h"
#import "UIColor+Cryptocat.h"
#import "TBButtonCell.h"
#import "TBTextFieldCell.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBLoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *conversationNameField;
@property (strong, nonatomic) UITextField *nicknameField;
@property (weak, nonatomic) IBOutlet UILabel *legendLabel;
@property (strong, nonatomic) TBButtonCell *buttonCell;
@property (weak, nonatomic) IBOutlet UIView *bottomToolbarView;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIButton *serverButton;

- (void)connect;
- (NSError *)errorForConversationName:(NSString *)conversationName nickname:(NSString *)nickname;
- (BOOL)shouldConnectButtonBeEnabled;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBLoginViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  
  // -- check for login info in defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSString *conversationName = [defaults objectForKey:@"roomName"];
  NSString *nickname = [defaults objectForKey:@"nickname"];
  if (conversationName!=nil && nickname!=nil &&
      [self.conversationNameField.text isEqualToString:@""] &&
      [self.nicknameField.text isEqualToString:@""]) {
    self.conversationNameField.text = conversationName;
    self.nicknameField.text = nickname;
  }
  
  // -- configure cells
  self.conversationNameField.textColor = [UIColor tb_tableViewCellTextColor];
  self.conversationNameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.conversationNameField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.nicknameField.textColor = [UIColor tb_tableViewCellTextColor];
  self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.nicknameField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.buttonCell.titleColor = [UIColor tb_buttonTitleColor];
  self.buttonCell.enabled = [self shouldConnectButtonBeEnabled];

  // -- configure tableview
  self.tableView.contentInset = UIEdgeInsetsMake(-35.0, 0.0, 0.0, 0.0);
  self.tableView.scrollEnabled = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self.navigationController setNavigationBarHidden:YES animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];

  [self.conversationNameField resignFirstResponder];
  [self.nicknameField resignFirstResponder];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // -- colors
  self.view.backgroundColor = [UIColor tb_backgroundColor];
  self.tableView.backgroundColor = [UIColor tb_backgroundColor];
  self.tableView.tableHeaderView.backgroundColor = [UIColor tb_backgroundColor];
  self.legendLabel.textColor = [UIColor tb_tableViewSectionTitleColor];

  // -- labels
  self.title = @"Cryptocat";
  self.legendLabel.text = NSLocalizedString(
                @"Enter a name for your conversation.\nShare it with people you'd like to talk to.",
                @"Login Screen Legend");

  
  // -- buttons
  [self.serverButton setTitle:NSLocalizedString(@"Server", @"Server Button Title")
                     forState:UIControlStateNormal];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showError:(NSError *)error {
  NSString *title = NSLocalizedString(@"Error", @"Connection Error Alert Title");
  NSString *cancelTitle = NSLocalizedString(@"Ok", @"Alert View Ok Button");
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                               message:[error tb_message]
                                              delegate:self
                                     cancelButtonTitle:cancelTitle
                                     otherButtonTitles:nil];
  [av show];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connect {
  NSString *conversationName = [[self.conversationNameField.text tb_trim] lowercaseString];
  NSString *nickname = [[self.nicknameField.text tb_trim] lowercaseString];
  self.conversationNameField.text = conversationName;
  self.nicknameField.text = nickname;
  
  NSError *error = [self errorForConversationName:conversationName nickname:nickname];
  if (error!=nil) {
    [self showError:error];
  }
  else {
    if ([self.delegate
         respondsToSelector:@selector(loginController:didAskToConnectWithRoomName:nickname:)]) {
      [self.delegate loginController:self
         didAskToConnectWithRoomName:conversationName
                            nickname:nickname];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSError *)errorForConversationName:(NSString *)conversationName nickname:(NSString *)nickname {
  NSCharacterSet *alphaNumericCharSet = [NSCharacterSet alphanumericCharacterSet];

  // -- check that conversationname is not empty
  if ([conversationName isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Please enter a conversation name.",
                                          @"Please enter a conversation name. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  // -- check that conversation name is 1..20 alphanumeric
  if (![[conversationName
         stringByTrimmingCharactersInSet:alphaNumericCharSet] isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Conversation name must be alphanumeric.",
                                          @"Conversation name must be alphanumeric. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  // -- check that nickname is not empty
  if ([nickname isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Please enter a nickname.",
                                          @"Please enter a nickname. Error Message");
    return [NSError tb_errorWithMessage:message];
  }

  // -- check that conversation name is 1..16 alphanumeric
  if (![[nickname
         stringByTrimmingCharactersInSet:alphaNumericCharSet] isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Nickname must be alphanumeric.",
                                          @"Nickname must be alphanumeric. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldConnectButtonBeEnabled {
  return ![self.conversationNameField.text isEqualToString:@""] &&
         ![self.nicknameField.text isEqualToString:@""];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField==self.conversationNameField) {
    [self.nicknameField becomeFirstResponder];
    return YES;
  }
  else if (textField==self.nicknameField) {
    if ([self shouldConnectButtonBeEnabled]) {
      [self connect];
      return YES;
    }
    else {
      return NO;
    }
  }
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  NSUInteger newLength = textField.text.length + string.length - range.length;

  NSUInteger maxLength = 0;
  if (textField==self.conversationNameField) {
    self.buttonCell.enabled = newLength > 0 && self.nicknameField.text.length > 0;
    maxLength = 20;
  }
  else if (textField==self.nicknameField) {
    self.buttonCell.enabled = newLength > 0 && self.conversationNameField.text.length > 0;
    maxLength = 16;
  }
  
  return (newLength > maxLength) ? NO : YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return section==0 ? 2 : 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- textField cells
  if (indexPath.section==0) {
    static NSString *TextFieldCellID = @"TextFieldCellID";
    TBTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellID
                                                            forIndexPath:indexPath];
    cell.textField.delegate = self;
    
    // conversation name
    if (indexPath.row==0) {
      self.conversationNameField = cell.textField;
      self.conversationNameField.placeholder = NSLocalizedString(@"conversation name",
                                                                 @"conversation name Field Placeholder");
    }
    // nickname
    else {
      self.nicknameField = cell.textField;
      self.nicknameField.placeholder = NSLocalizedString(@"your nickname",
                                                         @"your nickname Field Placeholder");
    }
    
    return cell;
  }
  
  // -- button cell
  else {
    static NSString *ButtonCellID = @"ButtonCellID";
    TBButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellID
                                                         forIndexPath:indexPath];
    self.buttonCell = cell;
    self.buttonCell.title = NSLocalizedString(@"Connect", @"Connect Button Title");
    return cell;
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    return YES;
  }
  
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    return [self shouldConnectButtonBeEnabled] ? indexPath : nil;;
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    [self connect];
    
    // deselect the cell
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillShow:(NSNotification *)notification {
  if (self.logoView.alpha==0.0) return;
  
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat keyboardHeight = isPortrait ? keyboardSize.height : keyboardSize.width;
  
  // get the animation info
  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];
  
  CGRect tvFrame = self.tableView.frame;
  tvFrame.origin.y-=keyboardHeight;
  
  CGRect bottomToolbarFrame = self.bottomToolbarView.frame;
  bottomToolbarFrame.origin.y-=keyboardHeight;

  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  self.tableView.frame = tvFrame;
  self.bottomToolbarView.frame = bottomToolbarFrame;
  self.logoView.alpha = 0.0;
  
  [UIView commitAnimations];
  // end animation
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillHide:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat keyboardHeight = isPortrait ? keyboardSize.height : keyboardSize.width;
  
  // get the animation info
  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];
  
  CGRect tvFrame = self.tableView.frame;
  tvFrame.origin.y+=keyboardHeight;
  
  CGRect bottomToolbarFrame = self.bottomToolbarView.frame;
  bottomToolbarFrame.origin.y+=keyboardHeight;
  
  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  self.tableView.frame = tvFrame;
  self.bottomToolbarView.frame = bottomToolbarFrame;
  self.logoView.alpha = 1.0;
  
  [UIView commitAnimations];
  // end animation
  TBLOGMARK;
}

@end
