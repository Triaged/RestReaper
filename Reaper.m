////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Reaper.m
//
//  Created by Dalton Cherry on 10/25/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "Reaper.h"
#import "JSONJoy.h"
#import "DCModel.h"

@implementation Reaper

static id reaper = nil;

////////////////////////////////////////////////////////////////////////////////////////////////////
+(instancetype)initReaper:(NSURL*)url
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reaper = [[[self class] alloc] initWithBaseURL:url];
    });
    return reaper;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(instancetype)sharedReaper
{
    return reaper;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(instancetype)initWithBaseURL:(NSURL*)url
{
    if(self = [super init])
    {
        self.netManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapIndex:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
         success:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSArray* array = responseObject;
         if([responseObject isKindOfClass:[NSDictionary class]])
             array = responseObject[@"response"]; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
         if(![array isKindOfClass:[NSArray class]])
         {
             NSError* error = [self errorWithDetail:NSLocalizedString(@"Index response object is not of NSArray class", nil) code:ReaperErrorCodeInvalidResponse];
             failure(self,error);
             return;
         }
         BOOL isCoreData = NO;
         NSMutableArray* gather = [NSMutableArray arrayWithCapacity:array.count];
         for(id object in array)
         {
             if([NSNull null] != (NSNull*)object)
             {
                 id value = [classType objectWithJoy:object];
                 if(value)
                     [gather addObject:value];
                 if([value isKindOfClass:[NSManagedObject class]])
                     isCoreData = YES;
             }
         }
         if(isCoreData)
         {
             [classType updateObjects:gather success:^(id items){
                 success(self,items);
             }failure:^(NSError* error){
                 failure(self,error);
             }];
         }
         else
             success(self,gather);
         
     }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];

}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapShow:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
         success:(void (^)(Reaper *reaper,id object))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary* dict = responseObject;
         if([responseObject isKindOfClass:[NSDictionary class]])
         {
             //probably need to check for "error" in the json, to ensure we report the right failure
             NSDictionary* response = responseObject[@"response"];
             if(response)
                 dict = response; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
         }
         if(![dict isKindOfClass:[NSDictionary class]])
         {
             NSError* error = [self errorWithDetail:NSLocalizedString(@"Show response object is not of NSDictonary class", nil) code:ReaperErrorCodeInvalidResponse];
             failure(self,error);
             return;
         }
         id value = [classType objectWithJoy:dict];
         if([value isKindOfClass:[NSManagedObject class]])
         {
             [value saveOrUpdate:^(id item){
                 success(self,item);
             }failure:^(NSError* error){
                 failure(self,error);
             }];
         }
         else
             success(self,value);
         
     }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapDestroy:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
           success:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager DELETE:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if([responseObject isKindOfClass:[NSDictionary class]])
         {
             id errorVal = responseObject[@"error"];
             if(errorVal)
             {
                 NSString* errorString = nil;
                 if([errorVal isKindOfClass:[NSString class]])
                     errorString = errorVal;
                 else
                     errorString = NSLocalizedString(@"Got an error when destroying", nil);
                 
                 NSError* error = [self errorWithDetail:errorString code:ReaperErrorCodeErrorResponse];
                 failure(self,error);
                 return;
             }
         }
         //need to delete from coreData store if it still exist here.
         success(self);
     }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];

}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapUpdate:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
          success:(void (^)(Reaper *reaper,id object))success
          failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    //do post like stuff
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSError*)errorWithDetail:(NSString*)detail code:(ReaperErrorCode)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:detail forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:NSLocalizedString(@"RestReaper", nil) code:code userInfo:details];
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
