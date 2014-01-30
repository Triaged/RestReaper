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
#import "RRUploadObject.h"
#if TARGET_OS_IPHONE
typedef UIImage RRImage;
#else
typedef NSImage RRImage;
#endif

@implementation Reaper

////////////////////////////////////////////////////////////////////////////////////////////////////
+(instancetype)sharedReaper
{
    //example of a singleton
    /*static id reaper = nil;
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
     reaper = [[[self class] alloc] initWithBaseURL:[NSURL urlWithString:@"myresturl"]];
     });
     return reaper;*/
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override the sharedReaper method in a subclass"]
                                 userInfo:nil];
    return nil;
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
    [self.netManager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject){
         NSArray* array = responseObject;
         NSError* error = [self checkError:responseObject];
         if(error)
         {
             failure(self,error);
             return;
         }
         if([responseObject isKindOfClass:[NSDictionary class]] && responseObject[@"response"])
             array = responseObject[@"response"]; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
         if([array isKindOfClass:[NSDictionary class]])
         {
             //well this is super not standard, but we will try to work around it
             [self createResponse:array classType:classType success:success failure:failure check:YES];
             return;
         }
         if(![array isKindOfClass:[NSArray class]])
         {
             NSError* error = [self errorWithDetail:NSLocalizedString(@"Index response object is not of NSArray class", nil) code:ReaperErrorCodeInvalidResponse];
             failure(self,error);
             return;
         }
         BOOL isCoreData = NO;
         JSONJoy* mapper = [classType jsonMapper];
         NSMutableArray* gather = [NSMutableArray arrayWithCapacity:array.count];
         NSArray *keys = nil;
         for(id object in array)
         {
             if([NSNull null] != (NSNull*)object)
             {
                 NSError* error = nil;
                 id value = [mapper process:object error:&error];
                 //id value = [classType objectWithJoy:object error:&error];
                 if(error)
                     return failure(self,error);
                 if(value)
                     [gather addObject:value];
                 if([value isKindOfClass:[NSManagedObject class]])
                 {
                     NSArray *props = [mapper propertyKeys];
                     NSMutableArray *gatherKeys = [NSMutableArray arrayWithCapacity:props.count];
                     for(NSString *name in props)
                     {
                         NSString *checkName = [JSONJoy convertToJsonName:name];
                         if([object valueForKey:name] || [object valueForKey:checkName])
                             [gatherKeys addObject:name];
                         if([name isEqualToString:@"objID"] && [object valueForKey:@"id"])
                             [gatherKeys addObject:name];
                     }
                     keys = gatherKeys;
                     isCoreData = YES;
                 }
             }
         }
         if(isCoreData)
         {
             [classType updateObjects:gather properties:keys success:^(id items){
                 success(self,items);
             }failure:^(NSError* error){
                 failure(self,error);
             }];
         }
         else
             success(self,gather);
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapShow:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
        success:(void (^)(Reaper *reaper,id object))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject){
         [self createResponse:responseObject classType:classType success:success failure:failure check:YES];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error){
         failure(self,error);
     }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapDestroy:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
           success:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager DELETE:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject){
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
     }failure:^(AFHTTPRequestOperation *operation, NSError *error){
         failure(self,error);
     }];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapUpdate:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
          success:(void (^)(Reaper *reaper,id object))success
          failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    [self.netManager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject){
         [self createResponse:responseObject classType:classType success:success failure:failure check:YES];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         failure(self,error);
     }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reapCreate:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
          success:(void (^)(Reaper *reaper,id object))success
          failure:(void (^)(Reaper *reaper, NSError *error))failure
{
    BOOL multiForm = NO;
    NSMutableDictionary *formDict = nil;
    NSMutableDictionary * newParams = nil;
    for(id key in parameters)
    {
        //automatic lookup attempts
        if([parameters[key] isKindOfClass:[RRImage class]] || [parameters[key] isKindOfClass:[NSData class]] || [parameters[key] isKindOfClass:[NSURL class]] || [parameters[key] isKindOfClass:[RRUploadObject class]])
        {
            if(!formDict)
                formDict = [NSMutableDictionary dictionary];
            if(!newParams)
                newParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
        }
        if([parameters[key] isKindOfClass:[RRUploadObject class]])
        {
            RRUploadObject *upload = parameters[key];
            [formDict setObject:upload forKey:key];
            multiForm = YES;
            [newParams removeObjectForKey:key];
        }
#if TARGET_OS_IPHONE
        else if([parameters[key] isKindOfClass:[UIImage class]])
        {
            UIImage *image = parameters[key];
            RRUploadObject *obj = [RRUploadObject new];
            obj.data =  UIImageJPEGRepresentation(image,0.5);
            obj.mimeType = @"image/jpeg";
            obj.fileName = NSLocalizedString(@"image.jpg", nil);
            [formDict setObject:obj forKey:key];
            multiForm = YES;
            [newParams removeObjectForKey:key];
        }
#else
        else if([parameters[key] isKindOfClass:[NSImage class]])
        {
            NSImage *image = parameters[key];
            NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
            
            RRUploadObject *obj = [RRUploadObject new];
            obj.data =  [bitmapRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor: @0.5}];
            obj.mimeType = @"image/jpeg";
            obj.fileName = NSLocalizedString(@"image.jpg", nil);
            [formDict setObject:obj forKey:key];
            multiForm = YES;
            [newParams removeObjectForKey:key];
        }
#endif
        else if([parameters[key] isKindOfClass:[NSData class]])
        {
            NSData *data = parameters[key];
            RRUploadObject *obj = [RRUploadObject new];
            obj.data = data;
            [formDict setObject:obj forKey:key];
            multiForm = YES;
            [newParams removeObjectForKey:key];
        }
        else if([parameters[key] isKindOfClass:[NSURL class]])
        {
            NSURL *url = parameters[key];
            if([url isFileURL])
            {
                RRUploadObject *obj = [RRUploadObject new];
                obj.fileURL = url;
                obj.fileName = [url lastPathComponent];
                [formDict setObject:obj forKey:key];
                multiForm = YES;
                [newParams removeObjectForKey:key];
            }
        }
    }
    if(multiForm)
    {
        parameters = newParams;
        [self.netManager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for(id key in formDict)
            {
                RRUploadObject *obj = formDict[key];
                if(obj.fileURL && obj.mimeType)
                    [formData appendPartWithFileURL:obj.fileURL name:key fileName:obj.fileName mimeType:obj.mimeType error:nil];
                else if(obj.fileURL)
                    [formData appendPartWithFileURL:obj.fileURL name:key error:nil];
                else if(obj.mimeType && obj.fileName && obj.data)
                    [formData appendPartWithFileData:obj.data name:key fileName:obj.fileName mimeType:obj.mimeType];
                else
                    [formData appendPartWithFormData:obj.data name:key];
            }
        }success:^(AFHTTPRequestOperation *operation, id responseObject){
            [self createResponse:responseObject classType:classType success:success failure:failure check:NO];
        }failure:^(AFHTTPRequestOperation *operation, NSError *error){
            failure(self,error);
        }];
    }
    else
    {
        [self.netManager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject){
             [self createResponse:responseObject classType:classType success:success failure:failure check:NO];
         }failure:^(AFHTTPRequestOperation *operation, NSError *error){
             failure(self,error);
         }];
    }
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)createResponse:(id)responseObject classType:(Class)classType success:(void (^)(Reaper *reaper,id object))success
              failure:(void (^)(Reaper *reaper, NSError *error))failure check:(BOOL)check
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
        if(response && [response isKindOfClass:[NSDictionary class]])
            dict = response; //fairly typical for API response, like in the commonly used RoR gem, RocketPants.
    }
    if(![dict isKindOfClass:[NSDictionary class]] && check)
    {
        NSError* error = [self errorWithDetail:NSLocalizedString(@"Create response object is not of NSDictonary class", nil) code:ReaperErrorCodeInvalidResponse];
        failure(self,error);
        return;
    }
    if([dict isKindOfClass:[NSDictionary class]])
    {
        NSError* error = nil;
        JSONJoy* mapper = [classType jsonMapper];
        id value = [mapper process:dict error:&error];
        if(error)
            return failure(self,error);
        if([value isKindOfClass:[NSManagedObject class]])
        {
            NSArray *props = [mapper propertyKeys];
            NSMutableArray *gatherKeys = [NSMutableArray arrayWithCapacity:props.count];
            for(NSString *name in props)
            {
                NSString *checkName = [JSONJoy convertToJsonName:name];
                if([dict valueForKey:name] || [dict valueForKey:checkName])
                    [gatherKeys addObject:name];
                if([name isEqualToString:@"objID"] && [dict valueForKey:@"id"])
                    [gatherKeys addObject:name];
            }
            [classType updateObject:value properties:gatherKeys success:^(id item){
                success(self,item);
            }failure:^(NSError* error){
                failure(self,error);
            }];
        }
        else
            success(self,value);
    }
    else
    {
        //POST and PUT can not return anything, which is bad in practice, but it does happen...
        success(self,nil);
    }
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
    //if(![baseURL hasPrefix:@"/"])
    //    url = [NSString stringWithFormat:@"/%@",baseURL];
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
+(NSDictionary*)combineParams:(NSDictionary*)dict params:(NSDictionary*)params
{
    NSMutableDictionary* parameters = nil;
    if(dict || params)
        parameters = [NSMutableDictionary dictionary];
    if(dict)
        [parameters addEntriesFromDictionary:dict];
    if(params)
        [parameters addEntriesFromDictionary:params];
    return parameters;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSDictionary*)combineParams:(NSDictionary*)dict page:(int)page
{
    NSDictionary *pageParam = nil;
    if(page > 0)
        pageParam = @{@"page": [NSNumber numberWithInt:page]};
    return [self combineParams:dict params:pageParam];
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
