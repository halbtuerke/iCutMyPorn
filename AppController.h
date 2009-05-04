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
    IBOutlet NSButton       *outputChosseButton;
    IBOutlet NSButton       *startTranscodeButton;
    
    IBOutlet NSMatrix       *qualityRadioGroup;
}

-(IBAction)startCancelTranscode:(id)sender;
-(IBAction)showInputChooserPanel:(id)sender;
-(IBAction)showOutputChooserPanel:(id)sender;

@end
