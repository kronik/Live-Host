//
//  DKAppDelegate.m
//  Live Host
//
//  Created by Dmitry Klimkin on 14/10/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import "DKAppDelegate.h"
#import "DKHostCellView.h"

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+OSX.h"
#import "MKNetworkKit.h"

#define HOST_ADDRESS_LIST @"HOST_ADDRESS_LIST_FOR_TRACKING"
#define CHEKC_FREQUECY 5.0

@interface DKAppDelegate () {
    
    __unsafe_unretained NSButton *_okButton;
    __unsafe_unretained NSButton *_deleteButton;
    __unsafe_unretained NSOutlineView *_tableView;
    __unsafe_unretained NSTextField *_hostField;
}

@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NIKFontAwesomeIconFactory *factory;
@property (nonatomic, strong) MKNetworkEngine *netManager;
@property (nonatomic, strong) NSDate *lastUpdateTime;
@property (nonatomic, strong) NSMutableDictionary *hosts;

@end

@implementation DKAppDelegate

@synthesize netManager = _netManager;
@synthesize lastUpdateTime = _lastUpdateTime;
@synthesize hosts = _hosts;
@synthesize hostField = _hostField;
@synthesize okButton = _okButton;
@synthesize deleteButton = _deleteButton;
@synthesize tableView = _tableView;
@synthesize updateTimer = _updateTimer;
@synthesize factory = _factory;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    _factory = [NIKFontAwesomeIconFactory toolbarItemIconFactory];
    
    _factory.colors = @[[NSColor blackColor]];
    _factory.strokeColor = [NSColor whiteColor];
    _factory.strokeWidth = 1.0;

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    self.lastUpdateTime = [NSDate dateWithTimeIntervalSince1970: 0];
    
    self.netManager = [[MKNetworkEngine alloc] initWithHostName:@"http://google.com"];

//    [[NSUserDefaults standardUserDefaults] setValue:[NSMutableDictionary new] forKey:HOST_ADDRESS_LIST];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    self.hosts = [[[NSUserDefaults standardUserDefaults] objectForKey:HOST_ADDRESS_LIST] mutableCopy];
    
//    DKHostStatusViewController *contentViewController = [[DKHostStatusViewController alloc] initWithNibName:@"DKHostStatusViewController" bundle:nil];
//    
//    contentViewController.delegate = self;
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTableView) userInfo:nil repeats:YES];
    
    // init the status item popup
    NSImage *image = [_factory createImageForIcon:NIKFontAwesomeIconOkSign];
    NSImage *alternateImage = [_factory createImageForIcon:NIKFontAwesomeIconDownload];
    
    self.window.menuBarIcon = image;
    self.window.highlightedMenuBarIcon = alternateImage;
    self.window.hasMenuBarIcon = YES;
    self.window.attachedToMenuBar = YES;
    self.window.isDetachable = YES;

//    _statusItemPopup = [[AXStatusItemPopup alloc] initWithViewController:contentViewController image:image alternateImage:alternateImage];
//    
//    // globally set animation state (optional, defaults to YES)
//    //_statusItemPopup.animated = NO;
//    
//    //
//    // --------------
//    
//    // optionally set the popover to the contentview to e.g. hide it from there
//    contentViewController.statusItemPopup = _statusItemPopup;
}

- (NSMutableDictionary *)hosts {
    if (_hosts == nil) {
        
        _hosts = [[[NSUserDefaults standardUserDefaults] objectForKey:HOST_ADDRESS_LIST] mutableCopy];

        if (_hosts == nil) {
            _hosts = [NSMutableDictionary new];
            _hosts [@"http://www.google.com"] = @NO;
            
            [[NSUserDefaults standardUserDefaults] setValue:_hosts forKey:HOST_ADDRESS_LIST];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    return _hosts;
}

- (void)setHosts:(NSMutableDictionary *)hosts {
    @synchronized (self) {
        _hosts = hosts;
        
//        __block ApplicationDelegate *selfRef = self;
//        
//        self.netManager.reachabilityChangedHandler = ^(NetworkStatus ns) {
//            if (ns == NotReachable) {
//                selfRef.menubarController.statusItemView.image = [NSImage imageNamed:@"no"];
//
//                @synchronized (selfRef) {
//                    for (NSString *host in selfRef.hosts) {
//                        selfRef.hosts [host] = @NO;
//                    }
//                }
//            } else {
//
//                [selfRef tryToDownloadSomething];
//            }
//        };
        
        [self tryToDownloadSomething];
        
        [[NSUserDefaults standardUserDefaults] setValue:_hosts forKey:HOST_ADDRESS_LIST];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)tryToDownloadSomething {
    // Wait until table will be reloaded
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate: self.lastUpdateTime];
    
    if (interval > 3) {
        self.lastUpdateTime = [NSDate date];
    } else {
        return;
    }
    
    __block DKAppDelegate *selfRef = self;
    @synchronized (self) {
        for (NSString *host in self.hosts) {
            
            MKNetworkOperation *operationToExecute = [[MKNetworkOperation alloc] initWithURLString:host params:nil httpMethod:@"GET"];
            
            operationToExecute.shouldCacheResponseEvenIfProtocolIsHTTPS = NO;
            operationToExecute.shouldNotCacheResponse = YES;
            
            [operationToExecute addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                
                if (selfRef.hosts [completedOperation.url] == nil) {
                    return ;
                }
                
                selfRef.hosts [completedOperation.url] = @YES;
                BOOL isAllAlive = YES;
                
                for (NSString *checkHost in self.hosts) {
                    if ([selfRef.hosts[checkHost] boolValue] == NO) {
                        isAllAlive = NO;
                        break;
                    }
                }
                
                self.factory.colors = @[[NSColor blackColor]];

                if (isAllAlive == NO) {
                    self.window.menuBarIcon = [self.factory createImageForIcon:NIKFontAwesomeIconExclamationSign];
                } else {
                    self.window.menuBarIcon = [self.factory createImageForIcon:NIKFontAwesomeIconOkSign];
                }
                
                [self performSelector:@selector(tryToDownloadSomething) withObject:nil afterDelay:CHEKC_FREQUECY];
            } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                
                if (selfRef.hosts [completedOperation.url] == nil) {
                    return ;
                }
                
                if ([selfRef.hosts [completedOperation.url] boolValue]) {
                    [self showNotification: @"down again!" forHost:completedOperation.url];
                }
                selfRef.hosts [completedOperation.url] = @NO;
                
                self.factory.colors = @[[NSColor blackColor]];
                self.window.menuBarIcon = [self.factory createImageForIcon:NIKFontAwesomeIconExclamationSign];
                
                [self performSelector:@selector(tryToDownloadSomething) withObject:nil afterDelay:CHEKC_FREQUECY];
            }];
            
            [self.netManager enqueueOperation:operationToExecute forceReload:YES];
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)showNotification:(NSString*)status forHost: (NSString *)host {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    
    notification.title = @"Server status changed.";
    notification.subtitle = [NSString stringWithFormat: @"Server %@ %@", host, status];
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Explicitly remove the icon from the menu bar
//    self.menubarController = nil;
    return NSTerminateNow;
}

- (void)hostAddressListChanged: (NSMutableDictionary *)newHostAddressList {
    
    self.hosts = newHostAddressList;
    
    //[self togglePanel:nil];
}

- (IBAction)okButtonClicked:(id)sender {
    [self saveAndUpdate];
}

- (IBAction)deleteButtonClicked:(id)sender {
    
    NSInteger rowIndex = [self.tableView rowForView:sender];
    
    if (rowIndex != -1) {
        @synchronized (self) {
            int index = 0;
            NSString *keyForCell = @"";
            
            for (NSString *host in self.hosts) {
                if (index == rowIndex) {
                    keyForCell = host;
                    break;
                } else {
                    index++;
                }
            }
            
            if (keyForCell.length > 0) {
                [self.hosts removeObjectForKey:keyForCell];
            }
            
            [self updateTableView];
        }
    }
}

- (void)saveAndUpdate {
    NSString *host = self.hostField.stringValue;
    
    self.hostField.stringValue = @"";
    
    if (host.length > 0) {
        if ([host rangeOfString:@"http"].location == NSNotFound) {
            host = [NSString stringWithFormat:@"http://%@", host];
        }
        self.hosts [host] = @NO;
    }
    
    [self.tableView reloadData];
}

- (void)updateTableView {
    [self tryToDownloadSomething];
    [self.tableView reloadData];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.hosts.count;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)rowIndex ofItem:(id)item {
    if (item == nil) {
        
        int index = 0;
        NSString *keyForCell = @"";
        
        for (NSString *host in self.hosts) {
            if (index == rowIndex) {
                keyForCell = host;
                break;
            } else {
                index++;
            }
        }

        return keyForCell;
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    
    if ([result isKindOfClass:[DKHostCellView class]]) {
        DKHostCellView *cellView = (DKHostCellView *)result;
        
        self.factory.colors = @[[NSColor blueColor]];

        NSImage *imageYes = [self.factory createImageForIcon:NIKFontAwesomeIconOkCircle];
        
        self.factory.colors = @[[NSColor redColor]];

        NSImage *imageNo = [self.factory createImageForIcon:NIKFontAwesomeIconExclamationSign];
        
        cellView.textField.stringValue = item;
        cellView.imageView.image = [self.hosts[item] boolValue] ? imageYes : imageNo;
    }
    return result;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return self.hosts.count;
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    int index = 0;
    NSString *keyForCell = @"";
    
    for (NSString *host in self.hosts) {
        if (index == rowIndex) {
            keyForCell = host;
            break;
        } else {
            index++;
        }
    }
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    
    NSImage *imageYes = [self.factory createImageForIcon:NIKFontAwesomeIconOkCircle];
    NSImage *imageNo = [self.factory createImageForIcon:NIKFontAwesomeIconExclamationSign];
    
    if ( [tableColumn.identifier isEqualToString:@"StatusColumn"] ) {
        
        //        keyForCell = [keyForCell stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        //        keyForCell = [keyForCell stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        
        cellView.textField.stringValue = keyForCell;
        
        return cellView;
    } else if ([tableColumn.identifier isEqualToString:@"ActionColumn"]) {
        
    } else if ([tableColumn.identifier isEqualToString:@"ImageColumn"]) {
        cellView.imageView.image = [self.hosts[keyForCell] boolValue] ? imageYes : imageNo;
    }
    
    return cellView;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
}

- (NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return nil;
}

-(void)reachabilityChanged:(NSNotification*)note {
//    Reachability * reach = [note object];
//    
//    if ([reach isReachable]) {
//        self.menubarController.statusItemView.image = [NSImage imageNamed:@"yes"];
//    } else {
//        self.menubarController.statusItemView.image = [NSImage imageNamed:@"no"];
//    }
}

-(void)controlTextDidEndEditing:(NSNotification *)notification {
    // See if it was due to a return
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement ) {
        [self saveAndUpdate];
    }
}

//- (IBAction) TestReachability:(id)sender
//{
//    bool success = false;
//    const char *host_name = [ipAddressText.textcStringUsingEncoding:NSASCIIStringEncoding];
//    NSString *imageConnectionSuccess = @"Connected.png";
//    NSString *imageConnectionFailed = @"NotConnected.png";
//    
//    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL,
//    																			host_name);
//    SCNetworkReachabilityFlags flags;
//    success = SCNetworkReachabilityGetFlags(reachability, &flags);
//    bool isAvailable = success && (flags & kSCNetworkFlagsReachable) &&
//    !(flags & kSCNetworkFlagsConnectionRequired);
//    if (isAvailable)
//    {
//    	NSLog([NSString stringWithFormat: @"'%s' is reachable, flags: %x", host_name, flags]);
//    	[imageView setImage: [UIImage imageNamed:imageConnectionSuccess]];
//    }
//    else
//    {
//    	NSLog([NSString stringWithFormat: @"'%s' is not reachable", host_name]);
//    	[imageView setImage: [UIImage imageNamed:imageConnectionFailed]];
//    }
//}

@end
