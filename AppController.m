//
//  AppController.m
//  spgw4ffmpeg
//
//  Created by Patrick on 04.05.09.
//  Copyright 2009 Patrick Mosby. All rights reserved.
//

#import "AppController.h"


@implementation AppController

- (void)awakeFromNib
{
    startButtonEnabled = 0;
    // NSLog(@"startButtonEnabeld: %d", startButtonEnabled);
}

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

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *ffmpegPath = [bundle pathForAuxiliaryExecutable:@"ffmpeg"];

    // NSLog(@"ffmpegPath: %@", ffmpegPath);

    // Start ffmpeg
    task = [[NSTask alloc] init];
    [task setLaunchPath:ffmpegPath];

    NSMutableArray *tempArgs = [NSMutableArray arrayWithObjects: @"-i",
                     [inputFileField stringValue],
                     @"-acodec",
                     @"libfaac",
                     @"-ab",
                     @"128k",
                     @"-vcodec",
                     @"libx264",
                     @"-threads",
                     @"2",
                     @"-y",
                     [outputFileField stringValue], nil];

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


-(void)appendData:(NSData *)d
{
    // NSLog(@"Trying to append");
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSTextStorage *ts = [logView textStorage];
    [ts replaceCharactersInRange:NSMakeRange([ts length], 0) withString:s];
    [s release];
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

-(IBAction)showInputChooserPanel:(id)sender
{
    if ([inputChooseButton title] == @"Clear") {
        [inputFileField setStringValue:@""];
        [inputChooseButton setTitle:@"Choose"];
        startButtonEnabled = startButtonEnabled - 2;
        [self enableStartButton];
    } else {
        NSArray *fileTypes = [NSArray arrayWithObjects:@"flv", @"avi", @"mp4", @"mov", @"wmv", @"divx", @"h264", @"mkv", @"m4v", @"3gp", nil];
        NSString *moviesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
        NSOpenPanel *panel = [NSOpenPanel openPanel];

        // Run the open panel
        [panel beginSheetForDirectory:moviesDirectory
                                 file:nil
                                types:fileTypes
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
    // Did they choose "Open"?
    if (returnCode == NSOKButton) {
        NSString *path = [openPanel filename];
        [inputFileField setStringValue:path];
        [inputChooseButton setTitle:@"Clear"];
        [self enableStartButton];
        // NSLog(@"inputFile: %@", path);
    }
}

-(IBAction)showOutputChooserPanel:(id)sender
{
    if ([outputChooseButton title] == @"Clear") {
        [outputFileField setStringValue:@""];
        [outputChooseButton setTitle:@"Choose"];
        startButtonEnabled = startButtonEnabled - 2;
        [self enableStartButton];
    } else {
        NSString *moviesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Movies"];
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
        NSString *path = [savePanel filename];
        [outputFileField setStringValue:path];
        [outputChooseButton setTitle:@"Clear"];
        [self enableStartButton];
        // NSLog(@"outputFile: %@", path);
    }
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

    // NSLog(@"Something went wrong…");
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // NSLog(@"alertDidEnd called");
    if (returnCode == NSAlertFirstButtonReturn) {
        // Kill ffmpeg
        [task terminate];

        // Delete the temporary outputfile
        NSFileManager *fm = [[NSFileManager alloc] init];
        [fm removeFileAtPath:[outputFileField stringValue] handler:nil];

        [progressIndicator stopAnimation:self];
        // [startTranscodeButton setNextState];
    } else {
        // Close the confirmation alert sheet
        [[alert window] orderOut:self];

        // Reopen the progress sheet
        [NSApp beginSheet:progressSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
    }

}

}
@end
