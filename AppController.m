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

}
@end
