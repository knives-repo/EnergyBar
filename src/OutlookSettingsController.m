//
//  OutlookSettingsController.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/3/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookSettingsController.h"
#import "NSImage+Utils.h"
#import "OutlookUtils.h"
#import "Outlook.h"

@implementation CategoryColorPopUpButtonCell

- (id) initWithCoder:(NSCoder *)coder
{
    // super
    self = [super initWithCoder:coder];
    
    // now manually add one item for each preset color
    NSDictionary* presetColors = [OutlookUtils presetColors];
    for (NSString* key in [OutlookUtils presetColorNames]) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        [menuItem setImage:[NSImage swatchWithColor:[presetColors objectForKey:key] size:NSMakeSize(60,10)]];
        [menuItem setIdentifier:key];
        [self.menu addItem:menuItem];
    }
    
    // done
    return self;
}

@end


@interface OutlookSettingsController ()
@property (retain) Outlook* outlook;
@property (retain) NSMutableArray* categories;
@end

@implementation OutlookSettingsController

- (id)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [self initialize];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self initialize];
    return self;
}

- (void)initialize {
    self.outlook = [[[Outlook alloc] init] autorelease];
    [self.outlook loadCurrentAccount:^{
        //[self updateOutlookStatus];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateStatus];
    [self loadCategories];
}

- (void)updateStatus
{
    if (self.outlook.currentAccount == nil) {
        [self.statusLabel setStringValue:@"Not connected"];
        [self.signInButton setEnabled:YES];
        [self.signOutButton setEnabled:NO];
    } else {
        [self.statusLabel setStringValue:self.outlook.currentAccount.username];
        [self.signInButton setEnabled:NO];
        [self.signOutButton setEnabled:YES];
    }
}

- (void)loadCategories
{
    self.categories = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"outlookCategories"]];
}

- (IBAction)outlookSignIn:(id)sender
{
    [self.outlook signIn:^(NSDictionary* profile) {
        NSLog(@"[CONNECT] %@", profile);
        [self updateStatus];
        [self.delegate outlookAccountUpdated];
    }];
}

- (IBAction)outlookSignOut:(id)sender
{
    [self.outlook signOut:^() {
        [self updateStatus];
        [self.delegate outlookAccountUpdated];
    }];
}

- (IBAction)outlookWidgetSettingsChange:(id)sender
{
    [self.delegate outlookSettingsUpdated:NO];
}

- (IBAction)outlookWidgetSettingsChangeWithReload:(id)sender
{
    [self.delegate outlookSettingsUpdated:YES];
}

- (IBAction)onCategoriesAddRemove:(id)sender
{
    NSInteger activeSegment = self.categoriesAddRemoveButton.selectedSegment;
    if (activeSegment == 0)
    {
        [self.categories addObject:@{
                    @"name": @"Category",
                    @"color": @"preset0"
        }];
        [self.categoriesTable reloadData];
        [self save];
    }
    else
    {
        [self.categories removeObjectAtIndex:[self.categoriesTable selectedRow]];
        [self.categoriesTable reloadData];
        [self save];
    }
}

- (void) save
{
    [[NSUserDefaults standardUserDefaults] setObject:self.categories forKey:@"outlookCategories"];
    [self.delegate outlookSettingsUpdated:NO];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.categories.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    // get category
    NSDictionary* category = [self.categories objectAtIndex:row];
    id value = [category objectForKey:tableColumn.identifier];
    
    // translate
    if ([tableColumn.identifier isEqualToString:@"color"])
    {
        value = [NSNumber numberWithUnsignedLong:[[OutlookUtils presetColorNames] indexOfObject:value]];
    }
    
    // done
    return value;

}

- (void)tableView:(NSTableView *)tableView setObjectValue:(nullable id)object forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    // get edited category
    NSDictionary* category = [self.categories objectAtIndex:row];
    
    // translate
    if ([tableColumn.identifier isEqualToString:@"color"])
    {
        object = [[OutlookUtils presetColorNames] objectAtIndex:[object intValue]];
    }
    
    // now set and save
    NSMutableDictionary* edited = [NSMutableDictionary dictionaryWithDictionary:category];
    [edited setValue:object forKey:tableColumn.identifier];
    [self.categories setObject:edited atIndexedSubscript:row];
    [self save];
}

@end
