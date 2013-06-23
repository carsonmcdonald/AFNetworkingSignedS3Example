//
//  ViewController.h
//  SignedS3UploadExample
//
//  Created by Carson on 6/22/13.
//  Copyright (c) 2013 Carson McDonald. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)selectImageAction:(id)sender;
- (IBAction)uploadImageAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end
