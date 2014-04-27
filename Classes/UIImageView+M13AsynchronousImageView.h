//
//  UIImageView+M13AsynchronousImageView.h
//  M13AsynchronousImageView
//
//  Created by Brandon McQuilkin on 4/24/14.
//  Copyright (c) 2014 Brandon McQuilkin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    M13AsynchronousImageLoaderImageLoadedLocationNone,
    M13AsynchronousImageLoaderImageLoadedLocationCache,
    M13AsynchronousImageLoaderImageLoadedLocationLocalFile,
    M13AsynchronousImageLoaderImageLoadedLocationExternalFile
} M13AsynchronousImageLoaderImageLoadedLocation;

/**
 The completion block for loading an image.
 
 @param success Wether or not the load succeded.
 @param url     The URL of the image.
 @param target  The designated target for loading the image if a target exists. (Usually a UIImageView.)
 */
typedef void (^M13AsynchronousImageLoaderCompletionBlock)(BOOL success, M13AsynchronousImageLoaderImageLoadedLocation location, UIImage *image, NSURL *url, id target);

@interface M13AsynchronousImageLoader : NSObject

/**@name Control Methods*/
/**
 Returns the default asynchronous image loader. The default loader is named "Default". This is the method most people will use to get the image loader.
 
 @return The default asynchronous image loader.
 */
+ (M13AsynchronousImageLoader *)defaultLoader;
/**
 Returns an asynchronous image loader with the given name. If no loader exists with that name, one will be created.
 
 @param name The name of the asynchronous image loader to retreive.
 
 @return The asynchronous image loader with the given name.
 */
+ (M13AsynchronousImageLoader *)loaderWithName:(NSString *)name;
/**
 Clears, and removes from memory the asynchronous image loader with the given name.
 
 @param name The name of the asynchronous image loader to cleanup.
 */
+ (void)cleanupLoaderWithName:(NSString *)name;
/**
 The cache all asynchronous image loaders will use, unless set otherwise.
 
 @return The default image Cache.
 */
+ (NSCache *)defaultImageCache;

/**@name Loading Images*/
/**
 Loads the image at the given URL into the cache.
 
 @note The url can be internal or external.
 
 @param url The URL of the image to download.
 */
- (void)loadImageAtURL:(NSURL *)url;
/**
 Load the image at the given URL. When the image has loaded then perform the given completion block.
 
 @note The URL can be internal or external.
 
 @param url    The URL to load the image from.
 @param target The target of the image loading.
 @param completion The completion block to run when finished loading the image.
 */
- (void)loadImageAtURL:(NSURL *)url target:(id)target completion:(M13AsynchronousImageLoaderCompletionBlock)completion;
/**
 Cancels loading the image at the given URL.
 
 @param url The URL of the image to cancel downloading of.
 */
- (void)cancelLoadingImageAtURL:(NSURL *)url;
/**
 Cancel loading the images set to be loaded for the given target.
 
 @param target The target to cancel loading the images for.
 */
- (void)cancelLoadingImagesForTarget:(id)target;
/**
 Cancels loading the image at the given URL, for the given target.
 
 @param url        The URL of the image to cancel.
 @param target     The target to cancel the loading of the image for.
 */
- (void)cancelLoadingImageAtURL:(NSURL *)url target:(id)target;


/**@name Properties*/
/**
 The cache the image loader will use to cache the images.
 */
@property (nonatomic, strong) NSCache *imageCache;
/**
 The maximum number of images to load concurrently.
 */
@property (nonatomic, assign) NSUInteger maximumNumberOfConcurrentLoads;
/**
 The length of time to try and load an image before stopping.
 */
@property (nonatomic, assign) NSTimeInterval loadingTimeout;


@end

@interface UIImageView (M13AsynchronousImageView)
/**
 Load the image from the given URL, then set the loaded image to the image property.
 
 @param url The URL to download the image from.
 */
- (void)loadImageFromURL:(NSURL *)url;
/**
 Loads the image from the given URL. Then set the loaded image to the image property. After the image is finished loading, the completion block will be run.
 
 @note If using this method in a table or collection view, one will likely have to refresh the cell containing the image view once the image has been set; If the location value in the completion block is not from the cache. If it is from the cache, the image was set immediatly, and no additional action should be required.
 
 @param url        The URL to load the image from.
 @param completion The completion block to run once the image has been downloaded.
 */
- (void)loadImageFromURL:(NSURL *)url completion:(M13AsynchronousImageLoaderCompletionBlock)completion;
/**
 Cancels loading all the images set to load for the image view.
 */
- (void)cancelLoadingAllImages;
/**
 Cancels loading the image at the given URL set to load for the image view.
 
 @param url The URL of the image to cancel loading of.
 */
- (void)cancelLoadingImageAtURL:(NSURL *)url;

@end
