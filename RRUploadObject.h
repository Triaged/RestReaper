////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  RRUploadObject.h
//
//  Created by Dalton Cherry on 12/11/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@interface RRUploadObject : NSObject

/**
 Use this to specific the fileName.
 */
@property(nonatomic,copy)NSString *fileName;

/**
 Use this to specific the mimeType.
 fileURLs will attempt an automatic lookup based on file extension
 */
@property(nonatomic,copy)NSString *mimeType;

/**
 Use this if you want to upload a file from memory
 */
@property(nonatomic,strong)NSData *data;

/**
 Use this if you want to upload a file from disk
 */
@property(nonatomic,strong)NSURL *fileURL;



@end
