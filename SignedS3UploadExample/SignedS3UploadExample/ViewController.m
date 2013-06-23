//
//  ViewController.m
//  SignedS3UploadExample
//
//  Created by Carson on 6/22/13.
//  Copyright (c) 2013 Carson McDonald. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.uploadButton.enabled = NO;
    self.progressView.hidden = YES;
}

- (IBAction)selectImageAction:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.allowsEditing = NO;
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:imagePicker animated:YES completion:^{
        self.uploadButton.enabled = NO;
        self.selectedImageView.image = nil;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.selectedImageView.image = info[UIImagePickerControllerOriginalImage];
    
    self.uploadButton.enabled = YES;
        
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)uploadImageAction:(id)sender
{
}

@end
