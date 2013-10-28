////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  RRManagedObject.h
//
//  Created by Dalton Cherry on 10/28/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <CoreData/CoreData.h>
#import "DCModel.h"
#import "Reaper.h"

@interface RRManagedObject : NSManagedObject<ReaperDataSource>

@property(nonatomic,strong)NSNumber *objID;
@property(nonatomic,strong)NSDate *createdAt;
@property(nonatomic,strong)NSDate *updatedAt;

@end

@interface NSManagedObject (RRManagedObject)

@end
