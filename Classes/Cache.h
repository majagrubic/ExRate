//
//  Cache.h
//  Kino
//
//  Created by Danijel Huis on 12/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Cache : NSObject 
{

}
+(void)addObject:(NSObject *)object forKey:(NSString *)key lifeInSeconds:(int)lifeInSeconds;
+(NSObject *)getObjectForKey:(NSString *)key;
+(void)removeObjectForKey:(NSString *)key;
+(void)clear;
//===== State
+(BOOL)getStateForKey:(NSString *)key setState:(BOOL)setState;
@end

//===============================================================================================================================================================
//===============================================================================================================================================================
#pragma mark														CacheObject Class
//===============================================================================================================================================================
//===============================================================================================================================================================
@interface CacheObject : NSObject
{
	NSObject *object;
	double expirationDate;
}
@property(nonatomic, retain) NSObject *object;
@property(nonatomic, assign) double expirationDate;
-(id)initWithObject:(NSObject *)_object expirationDate:(double)_expirationDate;
@end