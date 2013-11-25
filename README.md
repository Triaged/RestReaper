RestReaper
==========

Makes RESTFul service interaction fast and easy for iOS and Mac OS X. It eliminates the boilerplate of parsing JSON and is completely asynchronous. It is design in mind with the popular Ruby on Rails API routes (Index, Show, Destroy, Update, Create or the CRUD model). It also has full support for coreData objects as well, so you can now synchronous RESTFul network resources without having to write a bunch of boilerplate code to make it happen. Sounds to good to be true? Well head to the examples to make all your dreams come true!

## Examples ##

Our JSON objects looks something like this:

```javascript
{
    "id": 1,
    "name": "Dalton",
    "password_digest": "somecooldigest",
    "first_name": "Dalton",
    "last_name": "Cherry",
    "screen_name": null,
    "age": 22,
    "employed": false,
    "created_at": "2013-10-28T15:40:32.000Z",
    "updated_at": "2013-10-28T22:30:02.000Z"
}
```

First we need to create a Reaper subclass singleton object to interact with our RESTFul service.

```objective-c
@implementation APIReaper

+(instancetype)sharedReaper
{
    static APIReaper *reaper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reaper = [[[self class] alloc] initWithBaseURL:[NSURL URLWithString:@"http://myapiservice"]];
        [reaper.netManager.requestSerializer setAuthorizationHeaderFieldWithToken:@"myauthtoken"];
    });
    return reaper;
}

@end
 
```

Here is an NSManagedObject example. Just change your subclass from NSMangedObject to RRManagedObject.
```objective-c
#import "RRManagedObject.h"

@interface User : RRManagedObject

@property(nonatomic,copy)NSString *name;
@property(nonatomic,copy)NSString *firstName;
@property(nonatomic,copy)NSString *lastName;
@property(nonatomic,strong)NSNumber *age;
@property(nonatomic,strong)NSNumber *employed;

//just for create
@property(nonatomic,copy)NSString *passwordConfirmation;
@property(nonatomic,copy)NSString *password;

@end
```

Then in our User.m file we need to add a methods
```objective-c
+(NSString*)restResource
{
    return @"users.json";
}

+(Reaper*)reaperType
{
    return [APIReaper sharedReaper];
}

+(NSArray*)excludedParameters:(ReaperAction)action
{
    if(action == ReaperActionCreate)
        return nil;
    return @[@"password",@"passwordConfirmation"];
}
```
Now on to the good stuff!
## Index ##

```objective-c
//first pull all items from coreData that we have saved
[User all:^(NSArray *items){
    for(User *user in items)
        NSLog(@"user.name: %@",user.name);
	//now it is time to go reap the restful service
    [User reapIndex:^(Reaper *reaper, NSArray* objects){
		//update our people as employed
	   	user.employed = [NSNumber numberWithBool:YES];
		[user reapSave:^(Reaper *reaper, User *item){
			NSLog(@"successfully update: %@ employed: %@",item.name,item.employed);
		}failure:^(Reaper *reaper, NSError* error){
			NSLog(@"error: %@",[error localizedDescription]);
		}];
     }failure:^(Reaper *reaper, NSError* error){
         NSLog(@"error: %@",[error localizedDescription]);
     }];
}];
```
Let's breakdown what just happen. We first pulled all the User objects from CoreData so we know what we already have. Next we 'reaped' the index resource of our RESTFul service (which in this example is: _http://mycoolRestService/users.json_). The term 'reaped' means we queried the users.json, converted all the JSON objects into their proper User objects and saved/updated them in CoreData. Lastly we update each object's employed property to YES and did a reapSave, which sent the updated properties to your RESTFul service and saved the changes to CoreData. Note how you did not have to write a single line of boilerplate for interacting with the REST service or CoreData, you just got you use your objects as normal.

## Update ##

```objective-c
//find the first object from CoreData
[User where:@"objID == 1" success:^(id items){
	user.employed = [NSNumber numberWithBool:YES];
    [user reapSave:^(Reaper *reaper, User *item){
         NSLog(@"successfully update: %@ employed: %@",item.name,item.employed);
     }failure:^(Reaper *reaper, NSError* error){
         NSLog(@"error: %@",[error localizedDescription]);
     }];
}];
```

## Delete ##

```objective-c
//find all John's and delete them
[User all:^(NSArray *items){
	if([user.name isEqualToString:@"John"])
    {
        [user reapDestroy:^(Reaper* reaper){
            NSLog(@"John was successfully deleted");
        }failure:^(Reaper* reaper, NSError* error){
            NSLog(@"error deleting John: %@",[error localizedDescription]);
        }];
    }
}];
```

## Create ##

```objective-c
//Create a new John Object
User* john = [User newObject]; //[[User alloc] init]; if not a ManagedObject
john.name = @"John";
john.firstName = @"John";
john.lastName = @"Doe";
john.age = @123;
john.password = @"test";
john.passwordConfirmation = @"test";
[john reapSave:^(Reaper *reaper, User *item){
    NSLog(@"john objID: %@ name: %@",item.objID,item.name);
}failure:^(Reaper *reaper, NSError* error){
    NSLog(@"error: %@",[error localizedDescription]);
}];
```

## Show ##
```objective-c
//1 is the resource show action you want to reap. (e.g. http://mycoolRestService/users/1.json)
[User reapShow:1 success:^(Reaper *reaper, id object){
	NSLog(@"object: %@",object);    
}failure:^(Reaper *reaper, NSError* error){
	NSLog(@"error: %@",[error localizedDescription]);
}];
```

## Install ##

The recommended approach for installing RestReaper is via the CocoaPods package manager, as it provides flexible dependency management and dead simple installation.

via CocoaPods

Install CocoaPods if not already available:

	$ [sudo] gem install cocoapods
	$ pod setup
Change to the directory of your Xcode project, and Create and Edit your Podfile and add RestReaper:

	$ cd /path/to/MyProject
	$ touch Podfile
	$ edit Podfile
	platform :ios, '5.0' 
	# Or platform :osx, '10.8'
	pod 'RestReaper'

Install into your project:

	$ pod install
	
Open your project in Xcode from the .xcworkspace file (not the usual project file)

## Requirements ##

RestReaper requires at least iOS 5/Mac OSX 10.8 or above.
It has dependencies on this frameworks:

* https://github.com/daltoniam/DCModel
* https://github.com/daltoniam/JSONJoy
* https://github.com/AFNetworking/AFNetworking


## License ##

RestReaper is license under the Apache License.

## Contact ##

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam





