//
//  DKAppDelegate.h
//  Live Host
//
//  Created by Dmitry Klimkin on 14/10/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OBMenuBarWindow.h"

@interface DKAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate,
                                     NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet OBMenuBarWindow *window;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *hostField;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *okButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSButton *deleteButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSOutlineView *tableView;

- (IBAction) okButtonClicked:(id)sender;
- (IBAction) deleteButtonClicked:(id)sender;

@end
