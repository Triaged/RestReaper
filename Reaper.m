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
#import <objc/runtime.h>

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
         NSError* error = [self checkError:responseObject];
         if(error)
         {
             failure(self,error);
             return;
         }
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
             NSError* error = [self checkError:responseObject];
             if(error)
             {
                 failure(self,error);
                 return;
             }
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
         NSError* error = [self checkError:responseObject];
         if(error)
         {
             failure(self,error);
             return;
         }
         if([classType isSubclassOfClass:[NSManagedObject class]])
         {
             NSRange range = [url rangeOfString:@"/" options:NSBackwardsSearch];
             if(range.location != NSNotFound)
             {
                 NSString* value = [url substringFromIndex:range.location+1];
                 range = [value rangeOfString:@"."];
                 if(range.location != NSNotFound)
                     value = [value substringToIndex:range.location];
                 [classType where:[NSString stringWithFormat:@"objID = %@",value] sort:nil limit:1 success:^(id items){
                     [classType destroyObjects:items success:^{
                         success(self);
                     }failure:^(NSError* error){
                         failure(self,error);
                     }];
                 }];
             }
             else
                 success(self);
         }
         else
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
    [self.netManager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary* dict = responseObject;
         if([responseObject isKindOfClass:[NSDictionary class]])
         {
             NSError* error = [self checkError:responseObject];
             if(error)
             {
                 failure(self,error);
                 return;
             }
             NSDictionary* response = responseObject[@"response"];
             if(response)
                 dict = response; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
         }
         if([dict isKindOfClass:[NSDictionary class]])
         {
             id value = [classType objectWithJoy:dict];
             if([value isKindOfClass:[NSManagedObject class]])
             {
                 [value saveOrUpdate:^(id item){
                     success(self,item);
                 }failure:^(NSError* error){
                     failure(self,error);
                 }];
                 return;
             }
         }
         success(self,nil);
     }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapCreate:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
          success:(void (^)(Reaper *reaper,id object))success
          failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary* dict = responseObject;
        if([responseObject isKindOfClass:[NSDictionary class]])
        {
            NSError* error = [self checkError:responseObject];
            if(error)
            {
                failure(self,error);
                return;
            }
            NSDictionary* response = responseObject[@"response"];
            if(response)
                dict = response; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
        }
        if(![dict isKindOfClass:[NSDictionary class]])
        {
            NSError* error = [self errorWithDetail:NSLocalizedString(@"Create response object is not of NSDictonary class", nil) code:ReaperErrorCodeInvalidResponse];
            failure(self,error);
            return;
        }
        id value = [classType objectWithJoy:dict];
        if([value isKindOfClass:[NSManagedObject class]])
        {
            [classType updateObject:value success:^(id item){
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
-(NSError*)checkError:(id)response
{
    if([response isKindOfClass:[NSDictionary class]])
    {
        id errorVal = response[@"error"];
        if(errorVal)
        {
            NSString* errorString = nil;
            if([errorVal isKindOfClass:[NSString class]])
                errorString = errorVal;
            else
                errorString = NSLocalizedString(@"Got an error when destroying", nil);
            
            return [self errorWithDetail:errorString code:ReaperErrorCodeErrorResponse];
        }
    }
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSError*)errorWithDetail:(NSString*)detail code:(ReaperErrorCode)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:detail forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:NSLocalizedString(@"RestReaper", nil) code:code userInfo:details];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)resourceRoute:(NSString*)baseURL resource:(id)resource
{
    NSString* url = baseURL;
    NSString* format = @"";
    if(![baseURL hasPrefix:@"/"])
        url = [NSString stringWithFormat:@"/%@",baseURL];
    if(!resource)
        return url;
    NSRange range = [url rangeOfString:@"." options:NSBackwardsSearch];
    if(range.location != NSNotFound)
    {
        format = [url substringFromIndex:range.location];
        url = [url substringToIndex:range.location];
    }
    return [NSString stringWithFormat:@"%@/%@%@",url,resource,format];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSMutableDictionary*)createPostValues:(NSArray*)excludedParams object:(id)object class:(Class)classType
{
    NSArray* propArray = [self getPropertiesOfClass:classType];
    NSMutableDictionary* values = [NSMutableDictionary dictionaryWithCapacity:propArray.count];
    for(NSString* propName in propArray)
    {
        id value = [object valueForKey:propName];
        if(value && ![excludedParams containsObject:propName] && ![propName isEqualToString:@"createdAt"] && ![propName isEqualToString:@"updatedAt"] && ![propName isEqualToString:@"objID"])
        {
            NSString* key = [JSONJoy convertToJsonName:propName];
            [values setObject:[object valueForKey:propName] forKey:key];
        }
    }
    return values;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//gets all the properties names of the class
+(NSArray*)getPropertiesOfClass:(Class)objectClass
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectClass, &outCount);
    NSMutableArray* gather = [NSMutableArray arrayWithCapacity:outCount];
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        NSString* propName = [NSString stringWithUTF8String:property_getName(property)];
        [gather addObject:propName];
    }
    free(properties);
    if([objectClass superclass] && [objectClass superclass] != [NSObject class])
        [gather addObjectsFromArray:[self getPropertiesOfClass:[objectClass superclass]]];
    return gather;
}
////////////////////////////////////////////////////////////////////////////////////////////////////


@end
