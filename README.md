AFNetworking S3 Upload Example
==============================

This is an example project that demonstrates using AFNetworking to PUT a file into S3 using a signed S3 URL.

There are two parts to this example, a simple server side [Sinatra](http://www.sinatrarb.com/) web app found in the 
"server" directory that will return signed S3 URLs and an iOS app found in the "SignedS3UploadExample" directory.

## Web App Details

The web app needs to be configured before use. The following three items must be changed:

```
S3_KEY='S3 key here'
S3_SECRET='S3 secret here'
S3_BUCKET='/uploadtestbucket'
```

The S3 upload will be signed for uploading with the "public-read" ACL so you will want to change that if the 
uploads should be private instead:

```
amz_headers = "x-amz-acl:public-read"
```

## Client App Details

All of the work is done in the ViewController.m file. There is a #define at the top of the file that must be
changed to point to your deployed web app:

```
#define S3_SIGNING_API_URL @"http://yourserver.com/signput.json"
```

After selecting an image to upload and using the upload button a call is made to "requestSignedURLForUploadNamed" 
that in turn calls the web app to generate a signed URL for the file. Once that web app call returns successfully 
a call is made to "doImageUpload" to perform the PUT request.

