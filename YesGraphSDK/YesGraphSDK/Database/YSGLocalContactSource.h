//
//  YSGLocalContactSource.h
//  YesGraphSDK
//
//  Created by Dal Rupnik on 25/08/15.
//  Copyright © 2015 YesGraph. All rights reserved.
//

@import Foundation;

#import "YSGContactSource.h"

@interface YSGLocalContactSource : NSObject <YSGContactSource>

@property (nonatomic, readonly) BOOL hasPermission;

@end
