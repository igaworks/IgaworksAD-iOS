//
//  DADemo.m
//  IgaworksAd
//
//  Created by wonje,song on 2014. 6. 2..
//  Copyright (c) 2014년 wonje,song. All rights reserved.
//

#import "DADemo.h"

@implementation DADemo

@synthesize gender = _gender;
@synthesize age = _age;

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@synthesize accuracyInMeters = _accuracyInMeters;

+ (DADemo *)sharedInstance
{
    static DADemo *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DADemo alloc] init];
    });
    
    return _sharedInstance;
}

- (void)setLocationWithLatitude:(double)latitude
                      longitude:(double)longitude
                       accuracy:(double)accuracyInMeters
{
    _latitude = latitude;
    _longitude = longitude;
    _accuracyInMeters = accuracyInMeters;
}

@end
