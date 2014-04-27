//
//  ExternalImageTableViewController.m
//  M13AsynchronousImageView
//
//  Created by Brandon McQuilkin on 4/27/14.
//  Copyright (c) 2014 Brandon McQuilkin. All rights reserved.
//

#import "ExternalImageTableViewController.h"
#import "UIImageView+M13AsynchronousImageView.h"
#import "ImageTableViewCell.h"

@interface ExternalImageTableViewController ()

@end

@implementation ExternalImageTableViewController
{
    NSMutableArray *externalFileURLs;
    UIImage *loadingImage;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    loadingImage = [UIImage imageNamed:@"Loading"];
    self.tabBarItem.selectedImage = [UIImage imageNamed:@"ExternalFileSelected"];
    
    //Load the images listed in image list.
    //All images from http://pixabay.com/ : All images in public domain
    
    externalFileURLs = [NSMutableArray array];
    NSString *namesString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fullURLs" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSArray *fileNamesArray = [namesString componentsSeparatedByString:@"\n"];
    
    for (int i = 0; i < fileNamesArray.count; i++) {
        NSString *urlString = fileNamesArray[i];
        NSURL *url = [NSURL URLWithString:urlString];
        [externalFileURLs addObject:url];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return externalFileURLs.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocalCell" forIndexPath:indexPath];
 
    // Configure the cell...
 
    //Set the loading image
    cell.loadedImageView.image = loadingImage;
 
    //Cancel any other previous downloads for the image view.
    [cell.loadedImageView cancelLoadingAllImages];
 
    //Load the new image
    [cell.loadedImageView loadImageFromURL:externalFileURLs[indexPath.row] completion:^(BOOL success, M13AsynchronousImageLoaderImageLoadedLocation location, UIImage *image, NSURL *url, id target) {
        //This is where you would refresh the cell if need be. If a cell of basic style, just call "setNeedsRelayout" on the cell.
    }];
 
    return cell;
}

@end
