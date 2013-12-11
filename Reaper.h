////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Reaper.h
//
//  Created by Dalton Cherry on 10/25/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "AFNetworking.h"

///-------------------------------
/// @name Error codes For Rest Reaper
///-------------------------------
typedef enum {
    ReaperErrorCodeInvalidResponse = 1,
    ReaperErrorCodeErrorResponse = 2
} ReaperErrorCode;

///-------------------------------
/// @name RESTFul service actions
///-------------------------------
typedef enum {
    ReaperActionShow = 1,
    ReaperActionIndex = 2,
    ReaperActionCreate = 3,
    ReaperActionDestroy = 4,
    ReaperActionUpdate = 5
} ReaperAction;

@class Reaper;

///-------------------------------
/// @name The Rest Reaper protocol
///-------------------------------

@protocol ReaperDataSource <NSObject>

@required

///-------------------------------
/// @name Required protocol properties
///-------------------------------

/**
 The object's ID from the RESTFul service database.
 */
-(id)objID;

/**
 The created_at date from the RESTFul service database.
 */
-(NSDate*)createdAt;

/**
 The updated_at date from the RESTFul service database.
 */
-(NSDate*)updatedAt;

///-------------------------------
/// @name Instance methods for Reaping datasource
///-------------------------------

//this will update or create your object.
/**
 This runs the create or update action on the RESTFul service, depending on if the objID is set. It also saves or updates the local store as well.
 success block returns if no errors where encountered with creating or updating the object.
 failure block returns if an error occured during the operation
 */
-(void)reapSave:(void (^)(Reaper *reaper,id item))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 This runs the destroy action on the RESTFul service for the object calling, and deletes it from the store.
 success block returns if no errors where encountered with deleting the object.
 failure block returns if an error occured during the operation
 */
-(void)reapDestroy:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure;

///-------------------------------
/// @name Class methods for Reaping datasource
///-------------------------------

/**
  This reaps the index route and returns object of the class implementing the datasource protocol.
  @param success block returns the newly created objects of the class implementing the datasource protocol.
  @param failure block returns if an error occured during the operation
 */
+(void)reapIndex:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 This reaps the index route and returns object of the class implementing the datasource protocol.
 @param page is what page of the resource you want
 @param success block returns the newly created objects of the class implementing the datasource protocol.
 @param failure block returns if an error occured during the operation
 */
+(void)reapIndex:(int)page success:(void (^)(Reaper *reaper,NSArray* objects))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure;



/**
  This reaps the show route and returns object of the class implementing the datasource protocol.
  @param objectID is the id of the object you want to run the show action on
  @param success block returns the newly created object of the class implementing the datasource protocol.
  @param failure block returns if an error occured during the operation
 */
+(void)reapShow:(id)objectID success:(void (^)(Reaper *reaper,id item))success
         failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
  This reaps the destroy route and deletes it from disk.
  @param objectID is the id of the object you want to run the show action on
  @param success block returns if the object was successfully deleted from both the network and disk.
  @param failure block returns if an error occured during the operation
 */
+(void)reapDestroy:(id)objectID success:(void (^)(Reaper *reaper))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 This reaps the create route and returns an object of the class implementing the datasource protocol.
 @param parameters are the values to send to the RESTFul create action
 @param success block returns the newly created object of the class implementing the datasource protocol.
 @param failure block returns if an error occured during the operation
 */
+(void)reapCreate:(NSDictionary*)parameters success:(void (^)(Reaper *reaper, id object))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 This reaps the update route and returns the update object of the class implementing the datasource protocol.
 @param objectID is the id of the object you want to run the show action on
 @param parameters are the values to send to the RESTFul update action
 @param success block returns the newly created object of the class implementing the datasource protocol.
 @param failure block returns if an error occured during the operation
 */
+(void)reapUpdate:(id)objectID parameters:(NSDictionary *)postParams success:(void (^)(Reaper *, id))success
          failure:(void (^)(Reaper *, NSError *))failure;

/**
 This returns the base reaper class by default.
 This is uses so you can point to your own subclass of reaper, incase you have multiple REST services
 */
+(Reaper*)reaperType;

/**
 The resource of the RESTFul service to use. (e.g. users.json)
 */
+(NSString*)restResource;

/**
 Returns a array of properties names you don't want to send to the RESTFul service.
 Default is nil, so all properties are sent.
 @param action is the action being currently executed.
 */
+(NSArray*)excludedParameters:(ReaperAction)action;

/**
 Returns a NSDictionary of the global params you want to send to your RESTFul service.
 Default is nil, so no global params are added
 @param action is the action being currently executed.
 */
+(NSDictionary*)globalParameters:(ReaperAction)action;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

@interface Reaper : NSObject

@property(nonatomic,strong)AFHTTPRequestOperationManager* netManager;

///-------------------------------
/// @name Initalizing a RESTReaper Object
///-------------------------------

/**
 Returns the Reaper singleton.
 This is what you will use to interaction with the RESTFul services. 
 Subclass this and create your own singleton
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
-(void)reapDestroy:(Class)classType url:(NSString*)url parameters:(NSDictionary *)parameters
           success:(void (^)(Reaper *reaper))success
           failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 Updates an object for the resource of the service as well as deleting it from coreData store.
 resource is the resource path to update (e.g. http://baseURL/resource/1)
 parameters are the parameters to send with the request (such as ?auth_token=token or as such)
 success block returns the object was successfully updated.
 failure block returns if an error occured during the operation
 */
-(void)reapUpdate:(Class)classType url:(NSString*)resource parameters:(NSDictionary *)parameters
        success:(void (^)(Reaper *reaper,id object))success
        failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 creates, fetchs, converts, and saves an object for the create resource of the service.
 classType is the class of the objects that you want to create from the service response JSON.
 resource is the Resource to access (e.g. http://baseURL/resource)
 parameters are the parameters to send with the request (such as ?auth_token=token or as such)
 success block returns the newly created object of classType.
 failure block returns if an error occured during the operation
 */
-(void)reapCreate:(Class)classType url:(NSString*)resource parameters:(NSDictionary *)parameters
          success:(void (^)(Reaper *reaper,id object))success
          failure:(void (^)(Reaper *reaper, NSError *error))failure;

/**
 Creates a resource route off the base url and returns it.
 baseURL is your base resourceURL (e.g. /users.json).
 resource is the resource to use. (e.g. 1).
 This would create (/users/1.json)
 */
+(NSString*)resourceRoute:(NSString*)baseURL resource:(id)resource;

/**
 Combines two dictionaries and returns a a single combine one.
 this is used primarly to combine global and local params on POST and PUT.
 dict is the first dictionary to combine.
 params is the second dictionary to combine.
 */
+(NSDictionary*)combineParams:(NSDictionary*)dict params:(NSDictionary*)params;

/**
 Combines two dictonaries and returns a a single combine one.
 this is used primarly to combine global and the page number for index calls.
 dict is the dictionary to combine.
 page is the page number to add to the dictionary.
 */
+(NSDictionary*)combineParams:(NSDictionary*)dict page:(int)page;

/**
 @return returns a parameter dictionary based on the object properties.
 @param excludedParams is an array of property names you don't want to add to the response dictionary
 @param object is the object you want to pull the properties off
 @param classType is the class (the object's class) you want to pull the properties off.
 */
+(NSMutableDictionary*)createPostValues:(NSArray*)excludedParams object:(id)object class:(Class)classType;

@end
