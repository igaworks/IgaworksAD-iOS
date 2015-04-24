//
//  LiveOpsPopup.h
//  IgaworksAd
//
//  Created by 강기태 on 2015. 2. 27..
//  Copyright (c) 2015년 wonje,song. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LiveOpsPopupCompleteCallback)();
typedef void (^LiveOpsPopupLinkCallback)(NSString* popupSpaceKey, NSDictionary* customData);


@interface LiveOpsPopup : NSObject

+ (void)getPopups:(LiveOpsPopupCompleteCallback)block;
+ (void)showPopups:(NSString*)popupSpaceKey;

+ (void)setPopupLinkListener:(LiveOpsPopupLinkCallback)block;

@end