//
//  Cache.m
//  Kino
//
//  Created by Danijel Huis on 12/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//	Description:	Simple class that caches object with under given key
//					There is seperate array(keysArray) that keeps track of key input order, because NSDictionary order of keys
//					is undefined(allKeys property), maybe there is better solution?
//	Functions/Properties:
//					maximumObjects	-	number of object in cache allowed


#import "Cache.h"

static NSMutableDictionary *cacheDictionary=nil;
static int maximumObjects;
static NSMutableArray *keyArray;
static NSLock *cacheLock;
static NSMutableDictionary *stateDictionary;	
static NSTimer *cacheTimer;
static BOOL initialized=NO;

@interface Cache()
+(NSObject *)getObjectForKeyInternal:(NSString *)key;
+(void)removeObjectForKeyInternal:(NSString *)key;
@end

@implementation Cache
+(void)initialize
{
	if(initialized) return;
	initialized=YES;
	
	if(!cacheDictionary) cacheDictionary=[[NSMutableDictionary alloc] init];
	if(!keyArray) keyArray=[[NSMutableArray alloc] init];
	if(!stateDictionary) stateDictionary=[[NSMutableDictionary alloc] init];
	maximumObjects=10;
	cacheLock=[[NSLock alloc] init];
	// Todo time
	cacheTimer=[NSTimer scheduledTimerWithTimeInterval:60 target: [Cache class] selector:@selector(TimerFunction:) userInfo:nil repeats:YES];
}
//===============================================================================================================================================================
#pragma mark														Timer
//===============================================================================================================================================================

+(void)TimerFunction:(NSTimer *)timer
{
	[cacheLock lock];
	NSLog(@"=========================Cache: %@", keyArray);
	double currentDate=[[NSDate date] timeIntervalSince1970];
	CacheObject *cacheObject=nil;
	NSMutableArray *tempKeyArray=[NSArray arrayWithArray:keyArray];		// Because we cant change array while enumerating...
	
	//===== If objects expirationDate is passed we remove it....
	for(NSString *key in tempKeyArray)
	{
		cacheObject=[cacheDictionary objectForKey:key];
		if(currentDate>cacheObject.expirationDate)
		{
			[self removeObjectForKeyInternal:key];
		}
	}
	
	//===== If there is more objects than max then we remove the one that was put earliest in cache
	if(keyArray.count>0 && keyArray.count>maximumObjects)  [self removeObjectForKeyInternal:[keyArray objectAtIndex:0]];
	[cacheLock unlock];
}

// Adding object for key
+(void)addObject:(NSObject *)object forKey:(NSString *)key lifeInSeconds:(int)lifeInSeconds
{
	[cacheLock lock];
	if(object!=nil && key!=nil && key.length>0)
	{
		@try
		{
			//===== Creating cache object and adding it to cacheDicionary
			CacheObject *cacheObject=[[[CacheObject alloc] initWithObject:object expirationDate:[[NSDate date] timeIntervalSince1970]+lifeInSeconds] autorelease];
			[cacheDictionary setObject:cacheObject forKey:key];
			
			// The order of elements in keyArray reflects their input order, if some object with same key is cached again
			// then his key goes at the end(deleted last).
			if([keyArray containsObject:key]) [keyArray removeObject:key];
			[keyArray addObject:key];
			
			// If there is more objects than max then we remove the one that was put earliest in cache
			if(keyArray.count>maximumObjects) [self removeObjectForKeyInternal:[keyArray objectAtIndex:0]];
		}
		@catch (NSException *exception) 
		{
			NSLog(@"========NTH Exception========>, %s: %@-%@-%@", __PRETTY_FUNCTION__, exception.name,exception.description, exception.userInfo);
		}
	}
	[cacheLock unlock];
}


// Returns object for key if it exists, else it returns nil
+(NSObject *)getObjectForKeyInternal:(NSString *)key
{
	NSObject *object;
	@try
	{
		object=[cacheDictionary objectForKey:key];		
	}
	@catch (NSException *exception) 
	{
		NSLog(@"========NTH Exception========>, %s: %@-%@-%@", __PRETTY_FUNCTION__, exception.name,exception.description, exception.userInfo);
		object=nil;
	}
	return object;
}

// Removing object
+(void)removeObjectForKeyInternal:(NSString *)key
{
	@try
	{
		// Removing object
		[cacheDictionary removeObjectForKey:key];
		// Removing key
		[keyArray removeObject:key];
	}
	@catch (NSException *exception) 
	{
		NSLog(@"========NTH Exception========>, %s: %@-%@-%@", __PRETTY_FUNCTION__, exception.name,exception.description, exception.userInfo);
	}
}




// Returns object for key if it exists, else it returns nil
+(NSObject *)getObjectForKey:(NSString *)key
{
	CacheObject *cacheObject=nil;
	[cacheLock lock];
	cacheObject=(CacheObject *)[self getObjectForKeyInternal:key];
	[cacheLock unlock];
	return cacheObject.object;
}
// Removing object
+(void)removeObjectForKey:(NSString *)key
{
	[cacheLock lock];
	[self removeObjectForKeyInternal:key];
	[cacheLock unlock];	
}
+(void)clear
{
	[cacheLock lock];
	@try
	{
		// Removing object
		[cacheDictionary removeAllObjects];
		// Removing key
		[keyArray removeAllObjects];
	}
	@catch (NSException *exception) 
	{
		NSLog(@"========NTH Exception========>, %s: %@-%@-%@", __PRETTY_FUNCTION__, exception.name,exception.description, exception.userInfo);
	}
	[cacheLock unlock];
}
#pragma mark State
//==========================================================================================================================================================
//															State
//
//	This part is one simple dictionary in which we can put keys and then later check if that key is in dictionary(been set)
//	We can use it for example to check if some url(key) is already been downloaded, under download overwrite just put:
//	overwrite=![Cache getStateForKey:url setState:YES]
//	That will make sure that url is downloaded just once per app
//==========================================================================================================================================================
// If key is inside stateDictionary before call then it returns 1, else returns 0
// If setState, then state for key is set
+(BOOL)getStateForKey:(NSString *)key setState:(BOOL)setState
{
	BOOL state;
	state=[stateDictionary objectForKey:key]!=nil;
	if(setState) [stateDictionary setObject:key forKey:key];
	return state;
}


+(void)dealloc
{
	[cacheTimer invalidate];
	cacheTimer=nil;
	[keyArray release];
	[cacheLock release];
	[stateDictionary release];
	[cacheDictionary release];
	[super dealloc];
}

@end

//===============================================================================================================================================================
//===============================================================================================================================================================
#pragma mark														CacheObject Class
//===============================================================================================================================================================
//===============================================================================================================================================================
@implementation CacheObject
@synthesize object, expirationDate;

-(id)initWithObject:(NSObject *)_object expirationDate:(double)_expirationDate
{
	if(self=[super init])
	{
		self.object=_object;
		expirationDate=_expirationDate;
	}
	return self;
}
-(void)dealloc
{
	[object release];
	[super dealloc];
}
@end















