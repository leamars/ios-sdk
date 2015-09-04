//
//  YSGTwitterService.m
//  YesGraphSDK
//
//  Created by Dal Rupnik on 18/08/15.
//  Copyright © 2015 YesGraph. All rights reserved.
//

@import Social;

#import "YSGTwitterService.h"

@implementation YSGTwitterService

- (NSString *)name
{
    return @"Twitter";
}

- (NSString *)serviceType
{
    return SLServiceTypeTwitter;
}

@end