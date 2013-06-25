//
//  ViewController.m
//  SignedS3UploadExample
//
//  Created by Carson on 6/22/13.
//  Copyright (c) 2013 Carson McDonald. All rights reserved.
//

#import "ViewController.h"

#import "AFNetworking.h"

// This is URL will produce signed S3 URLs
#define S3_SIGNING_API_URL @"http://yourserver.com/signput.json"

@interface ViewController ()

- (void)requestSignedURLForUploadNamed:(NSString *)name ofType:(NSString *)mimeType successHandler:(void (^)(NSString *signedUrl))successHandler errorHandler:(void (^)(NSError *error))errorHandler;
- (void)doImageUpload:(UIImage *)imageToUpload ofType:(NSString *)mimeType toSignedS3URL:(NSString *)signedS3URL successHandler:(void (^)(NSString *objectURL))successHandler progressHandler:(void (^)(double percentUploaded))progressHandler errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.uploadButton.enabled = NO;
    self.progressView.hidden = YES;
    self.progressLabel.hidden = NO;
    self.progressLabel.text = @"Select image";
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

    [picker dismissViewControllerAnimated:YES completion:^{
        self.uploadButton.enabled = YES;
        self.progressLabel.text = @"Image selected";
    }];
}

- (IBAction)uploadImageAction:(id)sender
{
    self.uploadButton.enabled = NO;
    self.selectImageButton.enabled = NO;
    self.progressLabel.text = @"Requesting signed URL";
    
    // The name of the file when it is stored in S3
    NSString *uploadFilename = [NSString stringWithFormat:@"image_%f.jpg", [[NSDate date] timeIntervalSince1970]];
    // The mime type that will be stored along with the upload
    NSString *uploadMimeType = @"image/jpeg";
    
    [self requestSignedURLForUploadNamed:uploadFilename ofType:uploadMimeType successHandler:^(NSString *signedUrl){

        self.progressView.hidden = NO;
        self.progressView.progress = 0.0;
        self.progressLabel.hidden = YES;
        
        [self doImageUpload:self.selectedImageView.image ofType:uploadMimeType toSignedS3URL:signedUrl successHandler:^(NSString *objectURL) {
            
            self.progressLabel.text = @"Upload complete";
            
            self.progressView.hidden = YES;
            self.progressView.progress = 0.0;
            self.progressLabel.hidden = NO;
        
            self.uploadButton.enabled = YES;
            self.selectImageButton.enabled = YES;
            
        } progressHandler:^(double percentUploaded) {
          
            self.progressView.progress = percentUploaded;
            
        } errorHandler:^(NSError *error, NSString *errorString) {
        
            self.progressLabel.text = [NSString stringWithFormat:@"Upload error: %@", errorString];
        
            self.progressView.hidden = YES;
            self.progressView.progress = 0.0;
            self.progressLabel.hidden = NO;
            
            self.uploadButton.enabled = YES;
            self.selectImageButton.enabled = YES;
            
        }];

    } errorHandler:^(NSError *error){
       
        self.uploadButton.enabled = YES;
        self.selectImageButton.enabled = YES;
        self.progressLabel.text = [NSString stringWithFormat:@"Error signing: %@", error.localizedDescription];
    
    }];
}

- (void)requestSignedURLForUploadNamed:(NSString *)name ofType:(NSString *)mimeType successHandler:(void (^)(NSString *signedUrl))successHandler errorHandler:(void (^)(NSError *error))errorHandler
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?name=%@&type=%@", S3_SIGNING_API_URL, name, mimeType]]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    
        successHandler(JSON[@"url"]);
    
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    
        errorHandler(error);
    
    }];
    [operation start];
}

- (void)doImageUpload:(UIImage *)imageToUpload ofType:(NSString *)mimeType toSignedS3URL:(NSString *)signedS3URL successHandler:(void (^)(NSString *objectURL))successHandler progressHandler:(void (^)(double percentUploaded))progressHandler errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler
{
    NSData *imageData = UIImageJPEGRepresentation(self.selectedImageView.image, 0.99);
    
    NSURL *url = [NSURL URLWithString:signedS3URL];
    NSString *baseURL = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, url.port == nil ? @"" : [NSString stringWithFormat:@":%@", url.port]];
    NSString *urlPathAndQuery = [NSString stringWithFormat:@"%@%@", url.path, url.query == nil ? @"" : [NSString stringWithFormat:@"?%@", url.query]];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:urlPathAndQuery parameters:nil];

    [request setValue:[NSString stringWithFormat:@"%d", imageData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:mimeType forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"public-read" forHTTPHeaderField:@"x-amz-acl"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        progressHandler((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
    
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    
        successHandler([NSString stringWithFormat:@"%@%@", baseURL, url.path]);
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
       
        errorHandler(error, operation.responseString);
    
    }];
    
    operation.inputStream = [[NSInputStream alloc] initWithData:imageData];
    
    [httpClient enqueueHTTPRequestOperation:operation];
}

@end
