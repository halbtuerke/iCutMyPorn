//
//  AppController.h
//  spgw4ffmpeg
//
//  Created by Patrick on 04.05.09.
//  Copyright 2009 Patrick Mosby. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet NSTextField    *inputFileField;
    IBOutlet NSTextField    *outputFileField;
    IBOutlet NSTextField    *startTimeCodeField;
    IBOutlet NSTextField    *durationTimeCodeField;

    IBOutlet NSButton       *inputChooseButton;
    IBOutlet NSButton       *outputChooseButton;
    IBOutlet NSButton       *startTranscodeButton;

    IBOutlet NSMatrix       *qualityRadioGroup;

    IBOutlet NSPanel        *progressSheet;
    IBOutlet NSWindow       *mainWindow;
    IBOutlet NSWindow       *logWindow;
    IBOutlet NSProgressIndicator *progressIndicator;

    IBOutlet NSTextView     *logView;

    NSTask                  *task;
    NSPipe                  *pipe;

    NSString                *qualitySettings;
    int                     startButtonEnabled;
}

-(IBAction)startTranscode:(id)sender;
-(IBAction)showInputChooserPanel:(id)sender;
-(IBAction)showOutputChooserPanel:(id)sender;
-(IBAction)cancelTranscode:(id)sender;
-(IBAction)showLogWindow:(id)sender;
-(void)enableStartButton;
@end
