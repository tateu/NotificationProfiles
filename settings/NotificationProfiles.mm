#import <Foundation/NSDistributedNotificationCenter.h>
#import <Preferences/Preferences.h>

#define NSLog(fmt, ...)

#define profileDirectory @"/Library/Application Support/NotificationProfiles/"
#define tempFile @"/Library/Application Support/NotificationProfiles/qW9MG4.plist"
#define sectionInfoFile @"/var/mobile/Library/BulletinBoard/SectionInfo.plist"

@interface NPProfileController: PSViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	NSMutableArray *profiles;
	UITableView *_tableView;
}
@end

@implementation NPProfileController
-(id)init
{
	if (!(self = [super init])) return nil;

	[self reloadSortOrder];
	CGRect bounds = [[UIScreen mainScreen] bounds];

	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStylePlain];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[_tableView setDataSource:self];
	[_tableView setDelegate:self];
	[_tableView setEditing:NO];
	[_tableView setAllowsSelection:YES];
	[_tableView setAllowsMultipleSelection:NO];
	[_tableView setAllowsSelectionDuringEditing:NO];
	[_tableView setAllowsMultipleSelectionDuringEditing:NO];

	return self;
}

-(void)viewDidLoad
{
	((UIViewController *)self).title = @"Notification Profiles";
	[self setView:_tableView];
	[super viewDidLoad];
}

-(void) viewWillAppear:(BOOL) animated
{
	// dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.25) * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
		[self reloadSortOrder];
		[_tableView reloadData];
	// });

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return @"CURRENT";
	} else if (section == 1) {
		return @"AVAILABLE";
	}

	return @"Unknown";
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = 0;
	if (section == 0) {
		count = 1;
	} else if (section == 1) {
		count = [profiles count] - 1;
	}

	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}

	if (indexPath.section == 0) {
		NSDictionary *data = [profiles objectAtIndex:0];
		cell.textLabel.text = [data objectForKey:@"profileName"];
		cell.detailTextLabel.text = @""; // [NSString stringWithFormat:@"Last Modified: %@", [data objectForKey:@"lastModified"]];
	} else {
		NSDictionary *data = [profiles objectAtIndex:(indexPath.row + 1)];
		cell.textLabel.text = [data objectForKey:@"profileName"];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"Last Modified: %@", [data objectForKey:@"lastModified"]];
	}

	cell.textLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.textColor = [UIColor grayColor];

	return cell;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return NO;
	}

	return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([alertView tag] == 5651 && buttonIndex == 1) {
		// Overwrite existing profile
		NSString *profileName = alertView.accessibilityValue;
		NSString *destination = [NSString stringWithFormat:@"%@%@.plist", profileDirectory, profileName];

		NSError *error = nil;

		[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
		[[NSFileManager defaultManager] copyItemAtPath:sectionInfoFile toPath:tempFile error:&error];
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not create temporary save profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			return;
		}

		NSURL *destinationURL = [NSURL fileURLWithPath:destination];
		BOOL success = [[NSFileManager defaultManager] replaceItemAtURL:destinationURL withItemAtURL:[NSURL fileURLWithPath:tempFile] backupItemName:@"profile.backup" options:0 resultingItemURL:&destinationURL error:&error];
		if (!success) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not save profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		} else {
			[self reloadSortOrder];
			[_tableView reloadData];
		}
	} else if ([alertView tag] == 5653 && buttonIndex == 1) {
		// Save
		NSString *profileName = [alertView textFieldAtIndex:0].text;
		NSString *destination = [NSString stringWithFormat:@"%@%@.plist", profileDirectory, profileName];

		if (!profileName || [profileName isEqualToString:@""]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, You cannot save a profile with no name" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			return;
		}

		if ([NSFileManager.defaultManager fileExistsAtPath:destination]) {
			UIAlertView *alert = [[UIAlertView alloc] init];
			[alert setTitle:@"That profile exists!"];
			[alert setMessage:@"Would you like to overwrite it?"];
			[alert setTag:5651];
			[alert setDelegate:self];
			[alert addButtonWithTitle:@"No"];
			[alert addButtonWithTitle:@"Yes"];
			alert.cancelButtonIndex = 0;

			[alert setAccessibilityValue:profileName];
			[alert show];
		} else {
			NSError *error = nil;
			[[NSFileManager defaultManager] copyItemAtPath:sectionInfoFile toPath:destination error:&error];

			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not save profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alert show];
			} else {
				[self reloadSortOrder];
				[_tableView reloadData];
			}
		}
	} else if ([alertView tag] == 5654 && buttonIndex == 1) {
		// Load
		NSString *profileName = alertView.accessibilityValue;
		NSString *source = [NSString stringWithFormat:@"%@%@.plist", profileDirectory, alertView.accessibilityValue];
		NSError *error = nil;

		[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
		BOOL result = [[NSFileManager defaultManager] moveItemAtPath:sectionInfoFile toPath:tempFile error:&error];
		if (!result) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not create temporary load profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			return;
		}
		[[NSFileManager defaultManager] copyItemAtPath:source toPath:sectionInfoFile error:&error];

		if (!result) {
			result = [[NSFileManager defaultManager] moveItemAtPath:tempFile toPath:sectionInfoFile error:&error];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not load profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		} else {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"net.tateu.notificationprofiles/loadSectionInfo" object:nil userInfo:@{@"profileName":profileName}];
			[self reloadSortOrder];
			[_tableView reloadData];
		}
	}
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if (indexPath.section == 0) {
		} else {
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

			NSString *sourceFile = [NSString stringWithFormat:@"%@%@.plist", profileDirectory, cell.textLabel.text];
			NSError *error = nil;

			BOOL success = [[NSFileManager defaultManager] removeItemAtPath:sourceFile error:&error];
			if (success) {
				[self reloadSortOrder];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error, Could not delete profile" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alert show];
			}
		}
	}

	[_tableView reloadData];
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.section == 0 && indexPath.row == 0) {
		// Save
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save" message:@"Please enter a Profile Name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alert textFieldAtIndex:0].delegate = self;
		[alert setTag:5653];
		[alert show];
	} else if (indexPath.section == 1) {
		UIAlertView *alert = [[UIAlertView alloc] init];
		[alert setTitle:@"Are you sure you want to load the selected profile?"];
		[alert setMessage:@"If your current profile is Unsaved, it will be lost!!!"];
		[alert setTag:5654];
		[alert setDelegate:self];
		[alert addButtonWithTitle:@"Cancel"];
		[alert addButtonWithTitle:@"Yes"];
		alert.cancelButtonIndex = 0;

		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		[alert setAccessibilityValue:cell.textLabel.text];
		[alert show];
	}

	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

-(void)reloadSortOrder
{
	profiles = nil;
	NSMutableArray *preProfiles = [[NSMutableArray alloc] init];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setLocale:[NSLocale currentLocale]];

	NSError *error = nil;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:profileDirectory error:&error];

	NSString *match = @"*.plist";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
	for (NSString *fileName in [directoryContents filteredArrayUsingPredicate:predicate]) {
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[profileDirectory stringByAppendingString:fileName] error:nil];
		NSDate *lastModified = [attributes fileModificationDate];

		NSString *profileName = [fileName substringWithRange:NSMakeRange(0, [fileName length] - 6)];
		if (![profileName isEqualToString:@"qW9MG4"]) {
			NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:profileName, @"profileName", [dateFormatter stringFromDate:lastModified], @"lastModified", nil];
			[preProfiles addObject:data];
		}
	}

	if (preProfiles && [preProfiles count] > 0) {
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"profileName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
		profiles = [NSMutableArray arrayWithArray:[preProfiles sortedArrayUsingDescriptors:@[sort]]];
	}

	// NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:sectionInfoFile error:nil];
	// NSDate *lastModified = [attributes fileModificationDate];
	[profiles insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"SectionInfo.plist", @"profileName", @"", @"lastModified", nil] atIndex:0];
}
@end
