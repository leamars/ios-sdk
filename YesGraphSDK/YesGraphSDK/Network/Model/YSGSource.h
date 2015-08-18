//
//  YSGSource.h
//  YesGraphSDK
//
//  Created by Dal Rupnik on 18/08/15.
//  Copyright © 2015 YesGraph. All rights reserved.
//

@import Foundation;

@interface YSGSource : NSObject

@property (nonnull, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *email;
@property (nullable, nonatomic, copy) NSString *phone;
@property (nonnull, nonatomic, copy) NSString *type;

+ (nonnull instancetype)userSource;

@end