//
//  KeyboardAccessoryView.h
//  CAiOS
//
//  Created by Neville Smythe on 30/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeyboardAccessoryView : UIView <UIInputViewAudioFeedback> {
}
- (BOOL) enableInputClicksWhenVisible;
- (void) playClickForCustomKeyTap;

@end

