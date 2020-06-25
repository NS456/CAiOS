//
//  KeyboardAccessoryView.m
//  CAiOS
//
//  Created by Neville Smythe on 30/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeyboardAccessoryView.h"

@implementation KeyboardAccessoryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

- (void) playClickForCustomKeyTap {
    //NSLog(@"play click");
    [[UIDevice currentDevice]  playInputClick];
}

@end
