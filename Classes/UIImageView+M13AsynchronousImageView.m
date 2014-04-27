//
//  UIImageView+M13AsynchronousImageView.m
//  M13AsynchronousImageView
//
//  Created by Brandon McQuilkin on 4/24/14.
//  Copyright (c) 2014 Brandon McQuilkin. All rights reserved.
//

#import "UIImageView+M13AsynchronousImageView.h"

/**
 The base class that outlines the interface for loading image files.
 */
@interface M13AsynchronousImageLoaderConnection : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/**
 The URL of the file to load.
 */
@property (nonatomic, strong) NSURL *fileURL;
/**
 The target of the image loading.
 */
@property (nonatomic, strong) id target;
/**
 The duration of time to wait for a timeout.
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/**
 The completion block to run once the image is downloaded.
 */
@property (nonatomic, copy) M13AsynchronousImageLoaderCompletionBlock completionBlock;
/**
 The completion block to run once the image has loaded.
 
 @param completionBlock The completion block to run.
 */
- (void)setCompletionBlock:(M13AsynchronousImageLoaderCompletionBlock)completionBlock;

/**
 Begin loading the image.
 */
- (void)startLoading;
/**
 Cancel loading the image.
 */
- (void)cancelLoading;
/**
 Wether or not the loader is currently loading the image.
 
 @return Wether or not the loader is currently loading the image.
 */
- (BOOL)isLoading;
/**
 Wether or not the loader completed loading the image.
 
 @return Wether or not the loader completed loading the image.
 */
- (BOOL)finishedLoading;

@end


@interface M13AsynchronousImageLoader ()
/**
 The queue of connections to load image files.
 */
@property (nonatomic, strong) NSMutableArray *connectionQueue;
/**
 The list of active connections.
 */
@property (nonatomic, strong) NSMutableArray *activeConnections;

@end

@implementation M13AsynchronousImageLoader

+ (M13AsynchronousImageLoader *)defaultLoader
{
    return [M13AsynchronousImageLoader loaderWithName:@"Default"];
}

+ (M13AsynchronousImageLoader *)loaderWithName:(NSString *)name
{
    return [M13AsynchronousImageLoader loaderWithName:name cleanup:NO];
}

+ (void)cleanupLoaderWithName:(NSString *)name
{
    [M13AsynchronousImageLoader loaderWithName:name cleanup:YES];
}

+ (M13AsynchronousImageLoader *)loaderWithName:(NSString *)name cleanup:(BOOL)cleanup
{
    //Create the dictionary to hold the loader if necessary
    static dispatch_once_t onceToken;
    static NSMutableDictionary *loaders;
    dispatch_once(&onceToken, ^{
        loaders = [[NSMutableDictionary alloc] init];
    });
    
    //Create or Cleanup?
    if (!cleanup) {
        //Create / retreive
        if (!loaders[name]) {
            [loaders setObject:[[M13AsynchronousImageLoader alloc] init] forKey:name];
        }
        
        return loaders[name];
    } else {
        //Remove
        [loaders removeObjectForKey:name];
    }
    
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        _imageCache = [M13AsynchronousImageLoader defaultImageCache];
        _maximumNumberOfConcurrentLoads = 5;
        _loadingTimeout = 30.0;
        _connectionQueue = [NSMutableArray array];
        _activeConnections = [NSMutableArray array];
    }
    return self;
}

+ (NSCache *)defaultImageCache
{
    static dispatch_once_t onceToken;
    static NSCache *defaultCache;
    dispatch_once(&onceToken, ^{
        defaultCache = [[NSCache alloc] init];
    });
    return defaultCache;
}

- (void)loadImageAtURL:(NSURL *)url
{
    [self loadImageAtURL:url target:nil completion:nil];
}

- (void)loadImageAtURL:(NSURL *)url target:(id)target completion:(M13AsynchronousImageLoaderCompletionBlock)completion
{
    //Try loading the image from the cache first.
    UIImage *image = [self.imageCache objectForKey:url];
    //If we have the image, return
    if (image) {
        completion(YES, M13AsynchronousImageLoaderImageLoadedLocationCache, image, url, target);
        return;
    }
    
    //Not in cache, load the image.
    M13AsynchronousImageLoaderConnection *connection = [[M13AsynchronousImageLoaderConnection alloc] init];
    connection.fileURL = url;
    connection.target = target;
    connection.timeoutInterval = _loadingTimeout;
    [connection setCompletionBlock:^(BOOL success, M13AsynchronousImageLoaderImageLoadedLocation location, UIImage *image, NSURL *url, id target) {
        //Add the image to the cache
        if (success) {
            [self.imageCache setObject:image forKey:url];
        }
        
        //Run the completion block
        completion(success, location, image, url, target);
        
        //Update the connections
        [self updateConnections];
    }];
    
    //Add the connection to the queue
    [_connectionQueue addObject:connection];
    //Update the connections
    [self updateConnections];
}


- (void)updateConnections
{
    //First check if any of the active connections are finished.
    NSMutableArray *completedConnections = [NSMutableArray array];
    for (M13AsynchronousImageLoaderConnection *connection in _activeConnections) {
        if (connection.finishedLoading) {
            [completedConnections addObject:connection];
        }
    }
    //Remove the completed connections
    [_activeConnections removeObjectsInArray:completedConnections];
    [_connectionQueue removeObjectsInArray:completedConnections];
    
    //Check our queue to see if a completed connection loaded an image a connection in the queue is requesting. If so, mark it as completed, and remove it from the queue
    NSMutableArray *completedByProxyConnections = [NSMutableArray array];
    for (M13AsynchronousImageLoaderConnection *queuedConnection in _connectionQueue) {
        for (M13AsynchronousImageLoaderConnection *completedConnection in completedConnections) {
            if ([queuedConnection.fileURL isEqual:completedConnection.fileURL]) {
                //Run the queued connection's completion, and add to the array for removal
                [completedByProxyConnections addObject:queuedConnection];
                //Figure out where the file was loaded from. Don't want to use cache, since this was a loaded image.
                M13AsynchronousImageLoaderImageLoadedLocation location = [queuedConnection.fileURL isFileURL] ? M13AsynchronousImageLoaderImageLoadedLocationLocalFile : M13AsynchronousImageLoaderImageLoadedLocationExternalFile;
                //Run the completion.
                M13AsynchronousImageLoaderCompletionBlock completion = queuedConnection.completionBlock;
                completion(YES, location, [self.imageCache objectForKey:queuedConnection.fileURL], queuedConnection.fileURL, queuedConnection.target);
            }
        }
    }
    
    //Remove the completed connections
    [_connectionQueue removeObject:completedByProxyConnections];
    
    //Now start new connections, until we reach the maximum concurrent connections amount.
    for (int i = 0; i < _maximumNumberOfConcurrentLoads - _activeConnections.count; i++) {
        if (i < _connectionQueue.count) {
            M13AsynchronousImageLoaderConnection *connection = _connectionQueue[i];
            //Start the connection
            [connection startLoading];
            [_activeConnections addObject:connection];
        }
    }
}

- (void)cancelLoadingImageAtURL:(NSURL *)url
{
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    //Cancel all connections for the given target with the given URL.
    for (M13AsynchronousImageLoaderConnection *connection in _connectionQueue) {
        if ([connection.fileURL isEqual:url]) {
            [connection cancelLoading];
            [objectsToRemove addObject:connection];
        }
    }
    //Remove those connections from the list.
    [_connectionQueue removeObjectsInArray:objectsToRemove];
    [_activeConnections removeObjectsInArray:objectsToRemove];
    [self updateConnections];
}

- (void)cancelLoadingImagesForTarget:(id)target
{
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    //Cancel all connections for the given target.
    for (M13AsynchronousImageLoaderConnection *connection in _connectionQueue) {
        if (connection.target == target) {
            [connection cancelLoading];
            [objectsToRemove addObject:connection];
        }
    }
    //Remove those connections from the list.
    [_connectionQueue removeObjectsInArray:objectsToRemove];
    [_activeConnections removeObjectsInArray:objectsToRemove];
    [self updateConnections];
}

- (void)cancelLoadingImageAtURL:(NSURL *)url target:(id)target
{
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    //Cancel all connections for the given target with the given URL.
    for (M13AsynchronousImageLoaderConnection *connection in _connectionQueue) {
        if (connection.target == target && [connection.fileURL isEqual:url]) {
            [connection cancelLoading];
            [objectsToRemove addObject:connection];
        }
    }
    //Remove those connections from the list.
    [_connectionQueue removeObjectsInArray:objectsToRemove];
    [_activeConnections removeObjectsInArray:objectsToRemove];
    [self updateConnections];
}


@end

@implementation M13AsynchronousImageLoaderConnection
{
    BOOL loading;
    BOOL receivedData;
    BOOL finished;
    BOOL canceled;
    NSURLConnection *imageConnection;
    NSMutableData *imageData;
}

- (void)setCompletionBlock:(M13AsynchronousImageLoaderCompletionBlock)completionBlock
{
    _completionBlock = completionBlock;
}

- (void)startLoading
{
    //If we are loading, or have finished, return
    if (loading || finished) {
        return;
    }
    
    //Check to see if our URL is != nil
    if (_fileURL == nil) {
        //Fail
        finished = YES;
        _completionBlock(NO, M13AsynchronousImageLoaderImageLoadedLocationNone, nil, nil, _target);
        return;
    }
    
    //Begin loading
    loading = YES;
    
    if ([_fileURL isFileURL]) {
        //Our URL is to a file on the disk, load it asynchronously
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_fileURL]];
            
            if (image) {
                //Force image to decompress. UIImage deffers decompression until the image is displayed on screen.
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                [image drawAtPoint:CGPointZero];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                //Success
                finished = YES;
                loading = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _completionBlock(YES, M13AsynchronousImageLoaderImageLoadedLocationExternalFile, image, _fileURL, _target);
                });
                
            } else {
                //Failure
                
                finished = YES;
                loading = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _completionBlock(NO, M13AsynchronousImageLoaderImageLoadedLocationLocalFile, nil, _fileURL, _target);
                });
            }
        });
    } else {
        //Our URL is to an external file, No caching, we do that ourselves.
        NSURLRequest *request = [NSURLRequest requestWithURL:_fileURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:_timeoutInterval];
        //Create a connection
        imageConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [imageConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        //Start the connection
        [imageConnection start];
    }
}

- (void)cancelLoading
{
    canceled = YES;
    
    //Check to see if we are doing anything.
    if (!loading) {
        //Doing nothing, nothing to clean up.
        finished = YES;
        return;
    }
    
    //Clean up
    loading = NO;
    finished = YES;
    [imageConnection cancel];
    imageConnection = nil;
    imageData = nil;
}

- (BOOL)isLoading
{
    return loading;
}

- (BOOL)finishedLoading
{
    return finished;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //Setup to collect image data
    imageData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Add the received data to the image data
    receivedData = YES;
    [imageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //Connection failed, failed to load image.
    imageData = nil;
    imageConnection = nil;
    
    finished = YES;
    loading = NO;
    
    NSLog(@"Failed To Load Image: %@", error.localizedDescription);
    
    dispatch_async(dispatch_get_main_queue(), ^{
         _completionBlock(NO, M13AsynchronousImageLoaderImageLoadedLocationExternalFile, nil, _fileURL, _target);
    });
   
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Canceled, no need to process image.
    if (canceled) {
        imageData = nil;
        [imageConnection cancel];
        imageConnection = nil;
        return;
    }
    
    if (receivedData) {
        //Still need to work in the background, not the main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Create the image from the data
            UIImage *image = [UIImage imageWithData:imageData];
            
            imageData = nil;
            imageConnection = nil;
            
            if (image) {
                
                //Force image to decompress. UIImage deffers decompression until the image is displayed on screen.
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                [image drawAtPoint:CGPointZero];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                //Success
                finished = YES;
                loading = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _completionBlock(YES, M13AsynchronousImageLoaderImageLoadedLocationExternalFile, image, _fileURL, _target);
                });
                
            } else {
                //Failure
                
                finished = YES;
                loading = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _completionBlock(NO, M13AsynchronousImageLoaderImageLoadedLocationExternalFile, nil, _fileURL, _target);
                });
            }
        });
    }
}

@end

@implementation UIImageView (M13AsynchronousImageView)

- (void)loadImageFromURL:(NSURL *)url
{
    [[M13AsynchronousImageLoader defaultLoader] loadImageAtURL:url target:self completion:^(BOOL success, M13AsynchronousImageLoaderImageLoadedLocation location, UIImage *image, NSURL *url, id target) {
        //Set the image if loaded
        if (success) {
            self.image = image;
        }
    }];
}

- (void)loadImageFromURL:(NSURL *)url completion:(M13AsynchronousImageLoaderCompletionBlock)completion
{
    [[M13AsynchronousImageLoader defaultLoader] loadImageAtURL:url target:self completion:^(BOOL success, M13AsynchronousImageLoaderImageLoadedLocation location, UIImage *image, NSURL *url, id target) {
        //Set the image if loaded
        if (success) {
            self.image = image;
        }
        //Run the completion
        completion(success, location, image, url, target);
    }];
}

- (void)cancelLoadingAllImages
{
    [[M13AsynchronousImageLoader defaultLoader] cancelLoadingImagesForTarget:self];
}

- (void)cancelLoadingImageAtURL:(NSURL *)url
{
    [[M13AsynchronousImageLoader defaultLoader] cancelLoadingImageAtURL:url target:self];
}

@end
