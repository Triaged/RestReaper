////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  RRObject.m
//
//  Created by Dalton Cherry on 10/25/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "RRObject.h"

@implementation RRObject

////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapIndex:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self reapIndex:0 success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapIndex:(int)page success:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:nil];
    NSDictionary* parameter = nil;
    if(page > 0)
        parameter = @{@"page": [NSNumber numberWithInt:page]};
    [[self reaperType] reapIndex:[self class] url:url parameters:parameter success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapShow:(id)objectID success:(void (^)(Reaper *, id))success
        failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapShow:[self class] url:url parameters:nil success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapDestroy:(id)objectID success:(void (^)(Reaper *))success
           failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapDestroy:[self class] url:url parameters:nil success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapCreate:(NSDictionary *)postParams success:(void (^)(Reaper *, id))success
          failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:nil];
    [[self reaperType] reapCreate:[self class] url:url parameters:postParams success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)reapUpdate:(id)objectID parameters:(NSDictionary *)postParams success:(void (^)(Reaper *, id))success
          failure:(void (^)(Reaper *, NSError *))failure
{
    NSString* url = [Reaper resourceRoute:[self restResource] resource:objectID];
    [[self reaperType] reapUpdate:[self class] url:url parameters:postParams success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapSave:(void (^)(Reaper *reaper,id item))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    ReaperAction action = ReaperActionUpdate;
    if(!self.objID)
        action = ReaperActionCreate;
    NSMutableDictionary* values = [Reaper createPostValues:[[self class] excludedParameters:action] object:self class:[self class]];
    if(action == ReaperActionCreate)
        [[self class] reapCreate:values success:success failure:failure];
    else
        [[self class] reapUpdate:self.objID parameters:values success:^(Reaper* reaper, id item){
            if(item)
                success(reaper,item);
            else
                success(reaper,self);
            
        }failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapDestroy:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [[self class] reapDestroy:self.objID success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(Reaper*)reaperType
{
    return [Reaper sharedReaper];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)restResource
{
    //need to throw an error if the base class is implemented,
    //as this has to be overridden to work properly.
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)excludedParameters:(ReaperAction)action
{
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
