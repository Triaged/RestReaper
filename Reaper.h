////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Reaper.h
//
//  Created by Dalton Cherry on 10/25/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "AFNetworking.h"

///-------------------------------
/// @name Initalizing a JSONJoy Object
///-------------------------------
typedef enum {
    ReaperErrorCodeInvalidResponse = 1,
    ReaperErrorCodeErrorResponse = 2
} ReaperErrorCode;

@class Reaper;

@protocol ReaperDataSource <NSObject>

@required
//these should be properties
-(NSNumber*)objID;
-(NSDate*)createdAt;
-(NSDate*)updatedAt;

//now your reaping methods
+(void)reapIndex:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure;

+(void)reapShow:(int)objectID success:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure;

+(void)reapDestroy:(int)objectID success:(void (^)(Reaper *reaper,NSArray* objects))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

//this is uses so you can point to your own subclass of reaper, incase you have multiple REST services
+(Reaper*)reaperType;

//the rest route to use for your requests
+(NSString*)restRoute;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@interface Reaper : NSObject

@property(nonatomic,strong)AFHTTPRequestOperationManager* netManager;

///-------------------------------
/// @name Initalizing a RESTReaper Object
///-------------------------------

/**
 Initializes and returns a Reaper singleton object with the baseURL for the RESTFul services.
 This method has to be run before sharedReaper method can be called.
 */
+(instancetype)initReaper:(NSURL*)url;

/**
 Returns the Reaper singleton.
 This is what you will use to interaction with the RESTFul services.
 */
+(instancetype)sharedReaper;

/**
 Initializes and returns a Reaper object with a baseURL.
 This is used by initReaper method. You should not have to call this under most circimstances.
 */
-(instancetype)initWithBaseURL:(NSURL*)url;


///-------------------------------
/// @name Interaction with RESTFUL Services
///-------------------------------

/**
 Fetchs, converts, and saves JSON as objects for the index resource of the service.
 classType is the class of the objects that you want to create from the service response JSON.
 resource is the Resource to access (e.g. http://baseURL/resource)
 parameters are the parameters to send with the request (such as ?auth_token=token or as such)
 success block returns the newly created objects of classType.
 failure block returns if an error occured during the operation
 */
-(void)reapIndex:(Class)classType url:(NSString*)resource parameters:(NSDictionary *)parameters
success:(void (^)(Reaper *reaper,NSArray* objects))success
failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 Fetchs, converts, and saves JSON as an object for the show resource of the service.
 classType is the class of the object that you want to create from the service response JSON.
 resource is the Resource to access (e.g. http://baseURL/resource/1)
 parameters are the parameters to send with the request (such as ?auth_token=token or as such)
 success block returns the newly created object of classType.
 failure block returns if an error occured during the operation
 */
-(void)reapShow:(Class)classType url:(NSString*)resource parameters:(NSDictionary *)parameters
        success:(void (^)(Reaper *reaper,id object))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 Deletes an object for the resource of the service as well as deleting it from coreData store.
 resource is the resource path to destroy (e.g. http://baseURL/resource/1)
 parameters are the parameters to send with the request (such as ?auth_token=token or as such)
 success block returns the object was successfully deleted.
 failure block returns if an error occured during the operation
 */
-(void)reapDestroy:(NSString*)resource parameters:(NSDictionary *)parameters
        success:(void (^)(Reaper *reaper))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

-(void)reapUpdate:(Class)classType url:(NSString*)resource parameters:(NSDictionary *)parameters
        success:(void (^)(Reaper *reaper,id object))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

@end
