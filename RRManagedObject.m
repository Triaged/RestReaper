//
//  RRManagedObject.m
//  iOSTester
//
//  Created by Dalton Cherry on 10/28/13.
//  Copyright (c) 2013 Lightspeed Systems. All rights reserved.
//

#import "RRManagedObject.h"

@implementation RRManagedObject

@dynamic objID,updatedAt,createdAt;

////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapIndex:(int)page success:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:nil];
    [[self reaperType] reapIndex:[self class] url:url
                      parameters:[Reaper combineParams:[self globalParameters:ReaperActionIndex] page:page]
                         success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapIndex:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self reapIndex:0 success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapShow:(id)objectID success:(void (^)(Reaper *, id))success
        failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapShow:[self class] url:url parameters:[self globalParameters:ReaperActionShow] success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapDestroy:(id)objectID success:(void (^)(Reaper *))success
           failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapDestroy:[self class] url:url parameters:[self globalParameters:ReaperActionDestroy] success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapCreate:(NSDictionary *)postParams success:(void (^)(Reaper *, id))success
          failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:nil];
    [[self reaperType] reapCreate:[self class] url:url
                       parameters:[Reaper combineParams:[self globalParameters:ReaperActionCreate] params:postParams]
                          success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapUpdate:(id)objectID parameters:(NSDictionary *)postParams success:(void (^)(Reaper *, id))success
          failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapUpdate:[self class] url:url
                       parameters:[Reaper combineParams:[self globalParameters:ReaperActionUpdate] params:postParams]
                          success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapSave:(void (^)(Reaper *reaper,id item))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    NSLog(@"doing nothing!");
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapDestroy:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    NSLog(@"doing nothing!");
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(Reaper*)reaperType
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override the reaperType method in your subclass"]
                                 userInfo:nil];
    return [Reaper sharedReaper];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)restResource
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override the restResource method in your subclass"]
                                 userInfo:nil];
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)excludedParameters:(ReaperAction)action
{
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSDictionary*)globalParameters:(ReaperAction)action
{
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end

@implementation NSManagedObject (RRManagedObject)

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapSave:(void (^)(Reaper *reaper,id item))success
failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    RRManagedObject* object = (RRManagedObject*)self;
    Class class = NSClassFromString(self.entity.name);
    ReaperAction action = ReaperActionUpdate;
    if(!object.objID || [object.objID intValue] == 0)
        action = ReaperActionCreate;
    NSMutableDictionary* values = [Reaper createPostValues:[class excludedParameters:action] object:object class:class];
    if(action == ReaperActionCreate)
        [class reapCreate:values success:success failure:failure];
    else
        [class reapUpdate:object.objID parameters:values success:^(Reaper* reaper, id item){
            if(item)
                success(reaper,item);
            else
            {
                [class saveObject:self success:^(id object){
                    success(reaper,object);
                }failure:^(NSError* error){
                    failure(reaper,error);
                }];
            }
            
        }failure:failure];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapDestroy:(void (^)(Reaper *reaper))success
failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    RRManagedObject* object = (RRManagedObject*)self;
    Class class = NSClassFromString(self.entity.name);
    [class reapDestroy:object.objID success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
