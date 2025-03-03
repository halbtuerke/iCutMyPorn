//
//  AppController.m
//  spgw4ffmpeg
//
//  Created by Patrick on 04.05.09.
//  Copyright 2009 Patrick Mosby. All rights reserved.
//

#import "AppController.h"


@implementation AppController

@synthesize inputFilePath, outputFilePath, allowedFileTypes, moviesDirectory, ffmpegPath;

#pragma mark Initialization

- (id)init
{
    self = [super init];
    
    if (self) {
        conversionSuccessful = NO;
        self.inputFilePath = nil;
        self.outputFilePath = nil;
        self.moviesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
        bundle = [NSBundle mainBundle];
        self.ffmpegPath = [bundle pathForAuxiliaryExecutable:@"ffmpeg"];
        [NSApp setDelegate:self];
        self.allowedFileTypes = [NSArray arrayWithObjects:@"flv", @"avi", @"mp4", @"mov", @"wmv", @"divx", @"h264", @"mkv", @"m4v", @"3gp", @"mpg", @"mpeg", nil];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    self.inputFilePath = nil;
    self.outputFilePath = nil;
    self.allowedFileTypes = nil;
    self.moviesDirectory = nil;
    self.ffmpegPath = nil;
}

+ (NSSet *)keyPathsForValuesAffectingInputButtonTitle {
	return [NSSet setWithObjects:@"inputFilePath", nil];
}

+ (NSSet *)keyPathsForValuesAffectingOutputButtonTitle {
	return [NSSet setWithObjects:@"outputFilePath", nil];
}

#pragma mark Drag & Drop onto Application

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{    
    NSString *fileextension = [filename pathExtension];    
    
    if (![allowedFileTypes containsObject:fileextension]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Sorry but it seems that I can't handle this kind of file"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
    } else {
        self.inputFilePath = filename;
    }
    
    return YES;
}

#pragma mark -
# pragma mark InputChooser

-(IBAction)showInputChooserPanel:(id)sender
{
    if ([inputChooseButton title] == @"Clear") {
        [self clear:@"INPUT"];
    } else {
        NSOpenPanel *panel = [NSOpenPanel openPanel];

        // Run the open panel
        [panel beginSheetForDirectory:moviesDirectory
                                 file:nil
                                types:allowedFileTypes
                       modalForWindow:mainWindow
                        modalDelegate:self
                       didEndSelector:@selector(inputChooserPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];

    }
}

- (void)inputChooserPanelDidEnd:(NSOpenPanel *)openPanel
             returnCode:(int)returnCode
            contextInfo:(void *)x
{
    if (returnCode == NSOKButton) {
        self.inputFilePath = [openPanel filename];
    }
}

# pragma mark OutputChooser

-(IBAction)showOutputChooserPanel:(id)sender
{
    if ([outputChooseButton title] == @"Clear") {
        [self clear:@"OUTPUT"];
    } else {
        NSSavePanel *panel = [NSSavePanel savePanel];

        [panel beginSheetForDirectory:moviesDirectory
                                 file:@"Extracted Video.mp4"
                       modalForWindow:mainWindow
                        modalDelegate:self
                       didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
    }
}

- (void)savePanelDidEnd:(NSSavePanel *)savePanel
            returnCode:(int)returnCode
            contextInfo:(void *)x
{
    if (returnCode == NSOKButton) {
        self.outputFilePath = [savePanel filename];
    }
}

#pragma mark Helper Methods

-(void)clear:(NSString *)which
{
    if (which == @"INPUT") {
        self.inputFilePath = nil;
    } else {
        self.outputFilePath = nil;
    }
}

#pragma mark Button Bindings

-(NSString *)inputButtonTitle
{
    if (inputFilePath == nil) {
        return @"Choose";
    } else {
        return @"Clear";
    }
}

-(NSString *)outputButtonTitle
{
    if (outputFilePath == nil) {
        return @"Choose";
    } else {
        return @"Clear";
    }
}

#pragma mark -
# pragma mark NSTask methods

-(IBAction)startTranscode:(id)sender
{
    // Validate all user inputs
    
    // Show progress sheet and start the progress indicator
    [NSApp beginSheet:progressSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
    [progressIndicator startAnimation:self];
    
    // NSLog(@"startTimeCode: %@", [startTimeCodeField stringValue]);
    // NSLog(@"durationTimeCode: %@", [durationTimeCodeField stringValue]);
    // NSLog(@"quality: %@", [[qualityRadioGroup selectedCell] title]);
    
    NSString *startTimeCode = [startTimeCodeField stringValue];
    NSString *durationTimeCode = [durationTimeCodeField stringValue];
    
    // NSLog(@"ffmpegPath: %@", ffmpegPath);
    
    // Start ffmpeg
    task = [[NSTask alloc] init];
    [task setLaunchPath:ffmpegPath];
    
    NSMutableArray *tempArgs = [NSMutableArray arrayWithObjects: @"-i",
                                inputFilePath,
                                @"-acodec",
                                @"libfaac",
                                @"-ab",
                                @"128k",
                                @"-vcodec",
                                @"libx264",
                                @"-threads",
                                @"2",
                                @"-y",
                                outputFilePath, nil];
    
    NSArray *qualityArray;
    
    // NSLog(@"qualityRadioGroup: %@", [[qualityRadioGroup selectedCell] title]);
    
    // NSLog(@"TEMPARGS %@", tempArgs);
    
    if ([[[qualityRadioGroup selectedCell] title] isEqualToString:@"Lossless"]) {
        qualityArray = [NSArray arrayWithObjects:@"-crf", @"18", @"-me_method", @"umh", @"-subq", @"6", nil];
        [tempArgs addObjectsFromArray:qualityArray];
        // NSLog(@"tempargs: %@", tempArgs);
    } else if ([[[qualityRadioGroup selectedCell] title] isEqualToString:@"Recompress"]) {
        qualityArray = [NSArray arrayWithObjects:@"-b", @"1000k", @"-subq", @"4", nil];
        [tempArgs addObjectsFromArray:qualityArray];
        // NSLog(@"tempargs: %@", tempArgs);
    }
    
    NSArray *timecodeArray;
    
    // -- convert from startTimeCode to end of file
    // else if startTimeCode is not equal to "00:00:00" and durationTimeCode is equal to "00:00:00" then
    if (![startTimeCode isEqualToString:@"00:00:00"] && [durationTimeCode isEqualToString:@"00:00:00"]) {
        timecodeArray = [NSArray arrayWithObjects:@"-ss", startTimeCode, nil];
        [tempArgs addObjectsFromArray:timecodeArray];
    } else if (![startTimeCode isEqualToString:@"00:00:00"] && ![durationTimeCode isEqualToString:@"00:00:00"]) {
        timecodeArray = [NSArray arrayWithObjects:@"-ss", startTimeCode, @"-t", durationTimeCode, nil];
        [tempArgs addObjectsFromArray:timecodeArray];
    } else if ([startTimeCode isEqualToString:@"00:00:00"] && ![durationTimeCode isEqualToString:@"00:00:00"]) {
        timecodeArray = [NSArray arrayWithObjects:@"-t", durationTimeCode, nil];
        [tempArgs addObjectsFromArray:timecodeArray];
    }
    
    //-- convert from startTimeCode to durationTimeCode
    //else if startTimeCode is not equal to "00:00:00" and durationTimeCode is not equal to "00:00:00" then
    //-- convert from start of file to durationTimeCode
    
    NSArray *args = [NSArray arrayWithArray:tempArgs];
    
    // NSLog(@"args: %@", args);
    
    [task setArguments:args];
    
    // NSLog(@"arguments: %@", [task arguments]);
    
    
    // Release the old pipe
    [pipe release];
    // Create a new pipe
    pipe = [[NSPipe alloc] init];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fh = [pipe fileHandleForReading];
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [nc addObserver:self selector:@selector(dataReady:) name:NSFileHandleReadCompletionNotification object:fh];
    [nc addObserver:self selector:@selector(taskTerminated:) name:NSTaskDidTerminateNotification object:task];
    
    
    [logView setString:@"FUCKER!"];
    [fh readInBackgroundAndNotify];
    [task launch];
}

-(IBAction)cancelTranscode:(id)sender
{
    // Is the task running?
    if (task) {
        // Close progress sheet
        [progressSheet orderOut:nil];
        [NSApp endSheet:progressSheet];

        // Ask the user if he's sure
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];

        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Are you sure?"];
        [alert setInformativeText:@"Temporary movie file will be deleted."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // NSLog(@"alertDidEnd called");
    if (returnCode == NSAlertFirstButtonReturn) {
        // Kill ffmpeg
        [task terminate];

        // Delete the temporary outputfile
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        [fm removeFileAtPath:outputFilePath handler:nil];

        [progressIndicator stopAnimation:self];
        // [startTranscodeButton setNextState];
    } else {
        // Close the confirmation alert sheet
        [[alert window] orderOut:self];

        // Reopen the progress sheet
        [NSApp beginSheet:progressSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
    }

}

-(void)taskTerminated:(NSNotification *)note
{
    // NSLog(@"taskTerminated:");
    int termStatus = [task terminationStatus];

    // NSLog(@"terminationStatus is: %d", termStatus);
    [progressIndicator stopAnimation:self];
    [progressSheet orderOut:nil];
    [NSApp endSheet:progressSheet];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    [alert addButtonWithTitle:@"OK"];

    if (termStatus == 255) {
        [alert setMessageText:@"Conversion canceled"];
        [alert setAlertStyle:NSWarningAlertStyle];
    } else if (termStatus == 1) {
        [alert setMessageText:@"Sorry but it seems that I can't handle this movie file"];
        [alert setAlertStyle:NSWarningAlertStyle];
    } else {
        [alert setMessageText:@"Conversion finished"];
        [alert setAlertStyle:NSInformationalAlertStyle];
        conversionSuccessful = YES;
    }
    
    [self playSound:conversionSuccessful];
    [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    [self reset];
}

-(void)reset
{
    [task release];
    task = nil;
    conversionSuccessful = NO;
    
    [startTranscodeButton setState:0];
    [startTranscodeButton setEnabled: NO];
    
    [startTimeCodeField setStringValue:@"00:00:00"];
    [durationTimeCodeField setStringValue:@"00:00:00"];
    
    [self clear:@"INPUT"];
    [self clear:@"OUTPUT"];
}

# pragma mark successful/failed sounds

-(void)playSound:(BOOL)success
{
    NSSound *successSound = [[[NSSound alloc] init] autorelease];
    
    // system sounds in /Library/Sounds and ~/Library/Sounds will be played automatically when NSSound is used
	if (success == YES) {
		successSound = [NSSound soundNamed:@"complete"];
	} else if (success == NO) {
		successSound = [NSSound soundNamed:@"Basso"];
	}
    
    [successSound play];
}

#pragma mark -
#pragma mark Logging

-(IBAction)showLogWindow:(id)sender
{
    // NSLog(@"Log Window Button clicked");
    [logWindow makeKeyAndOrderFront:self];
}

-(void)appendData:(NSData *)d
{
    // NSLog(@"Trying to append");
    NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
    NSTextStorage *ts = [logView textStorage];
    [ts replaceCharactersInRange:NSMakeRange([ts length], 0) withString:s];
}


-(void)dataReady:(NSNotification *)n
{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
    // NSLog(@"The notification is: %@", n);
    // NSLog(@"The data is: %@", d);
    
    [self appendData:d];
    
    // If the task is running start reading again
    if ([task isRunning]) {
        // NSLog(@"Reading again");
        [[pipe fileHandleForReading] readInBackgroundAndNotify];
    }
}

#pragma mark -
# pragma mark Open PDF for Help

-(IBAction)openHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[bundle pathForResource:@"iCutMyPorn Help" ofType:@"pdf" inDirectory:@""]];
}

@end