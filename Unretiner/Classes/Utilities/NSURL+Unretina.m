//
//  NSURL+Unretina.m
//  Unretiner
//
//  Created by Stuart Hall on 31/07/11.
//

#import "NSURL+Unretina.h"
#import "NSBitmapImageRep+Resizing.h"

@implementation NSURL (Unretina)

static NSString* const kRetinaString = @"@2x";
static NSString* const kHdString = @"-hd";
static NSString* const kIpadHDString = @"-ipadhd";
static NSString* const kIpadHDString2 = @"@4x";

- (BOOL)unretina:(NSURL*)folder errors:(NSMutableArray*)errors warnings:(NSMutableArray*)warnings overwrite:(BOOL)overwrite {
    BOOL success = NO;
    if (![self isRetinaImage]) {
        if (![self isAlreadyRenamed]) {
            //renames all normal image files to @1x
            NSString * fullFileName = [self lastPathComponent];
            NSString * fileExtension = [fullFileName pathExtension];
            NSString * fileName = [fullFileName stringByDeletingPathExtension];
            NSString * newFileName = [fileName stringByAppendingString:@"@1x"];
            NSString * newFullFileName = [newFileName stringByAppendingPathExtension:fileExtension];
            NSString *oldPath = self.path;
            
            NSString *temp = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-temp", newFullFileName]];
            NSString *target = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFullFileName];
            
            [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:temp error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:temp toPath:target error:nil];
        }
        return YES;
    }
    //if ([self isRetinaImage]) {
    // New path is the same file minus the @2x
    NSString* newFilename = [[self lastPathComponent] stringByReplacingOccurrencesOfString:@"@2x" withString:@"@1x"];
    newFilename = [newFilename stringByReplacingOccurrencesOfString:@"-hd" withString:@"@1x"];
    newFilename = [newFilename stringByReplacingOccurrencesOfString:@"-ipadhd" withString:@"@2x"];
    newFilename = [newFilename stringByReplacingOccurrencesOfString:@"@4x" withString:@"@2x"];
    NSString* newPath = [NSString stringWithFormat:@"%@%@", [folder relativeString], newFilename];
    NSURL* newUrl = [NSURL URLWithString:newPath];
    
    // Check if file exists
    if (!overwrite && [newUrl checkResourceIsReachableAndReturnError:nil]) {
        // Exists already
        [warnings addObject:[NSString stringWithFormat:@"%@ : Skipped (exists)", [[newUrl absoluteString] lastPathComponent]]];
        return NO;
    }
    
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfURL:self];
    if (sourceImage && [sourceImage isValid]) {
        // Hack to ensure the size is set correctly independent of the dpi
        NSImageRep *rep = [[sourceImage representations] objectAtIndex:0];
        [sourceImage setScalesWhenResized:YES];
        [sourceImage setSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
        
        // Warn if either dimension is odd
        if (((((int)[sourceImage size].width) % 2 != 0) && (((int)[sourceImage size].width) != 1)) ||
            ((((int)[sourceImage size].height) % 2 != 0) && (((int)[sourceImage size].height) != 1)))
        {
            [warnings addObject:[NSString stringWithFormat:@"%@ : has dimensions not divisible by 2", [[self absoluteString] lastPathComponent]]];
        }
        
        // Determine the image type
        NSBitmapImageFileType imageType = [self imageType];
        if ((int)imageType >= 0) {
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)[NSData dataWithContentsOfURL:self]);
            CGImageRef imageRef = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
            imageRef = [self createScaledCGImageFromCGImage:imageRef WithScale:0.5f];
            
            
            // Write out the new image
            if (![self CGImageWriteToFile:imageRef WithPath:newUrl]) {
                [errors addObject:[NSString stringWithFormat:@"%@ : Error creating file", newPath]];
            }else {
                //[self unpremultiplyFileWithURL:newUrl];
                success = YES;
            }
        }else {
            [errors addObject:[NSString stringWithFormat:@"%@ : Unknown image type", [[self absoluteString] lastPathComponent]]];
        }
    }else {
        // Invalid
        //    [errors addObject:[NSString stringWithFormat:@"%@ : Appears to be invalid", [[self absoluteString] lastPathComponent]]];
    }
    
    // Cleanup
    if (sourceImage) {
        [sourceImage release];
    }
    // }
    //else if (errors) {
    // Not a valid retina file
    
    //    [errors addObject:[NSString stringWithFormat:@"%@ : Not a @2x or -hd file", [[self absoluteString] lastPathComponent]]];
    // }
    //renames old retina file to @4x or @2x if necessary
    NSString* newOldFilename = [[self lastPathComponent] stringByReplacingOccurrencesOfString:@"-ipadhd" withString:@"@4x"];
    newOldFilename = [newOldFilename stringByReplacingOccurrencesOfString:@"-hd" withString:@"@2x"];
    NSString *oldPath = self.path;
    
    NSString *temp = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-temp", newOldFilename]];
    NSString *target = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newOldFilename];
    
    [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:temp error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:temp toPath:target error:nil];
    if([newUrl isRetinaImage]){
        [newUrl unretina:folder errors:errors warnings:warnings overwrite:overwrite];
    }
   
    return success;
}
- (BOOL) CGImageWriteToFile:(CGImageRef) image WithPath: (NSURL *)url {
    CFURLRef urlRef = (CFURLRef)url;
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(urlRef, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        return NO;
        NSLog(@"Failed to write image to %@", [url absoluteString]);
    }
    CFRelease(destination);
    return YES;
}
- (CGImageRef)createScaledCGImageFromCGImage:(CGImageRef)image WithScale:(float) scale{
    int width = CGImageGetWidth(image) * scale;
    int height = CGImageGetHeight(image) * scale;

    // create context, keeping original image properties
    CGContextRef context = CGBitmapContextCreate(NULL, width, height,
                                                 CGImageGetBitsPerComponent(image),
                                                 CGImageGetBytesPerRow(image),
                                                 CGImageGetColorSpace(image),
                                                 kCGImageAlphaPremultipliedLast);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    if(context == NULL)
        return nil;
    
    // draw image to context (resizing it)
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // extract resulting image from context
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return imgRef;
}
- (void)unpremultiplyFileWithURL:(NSURL *)filePathURL
{
    NSString *path = [[filePathURL filePathURL] path];
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)filePathURL, NULL);
    if(imageSource) {
        CGImageRef premultipliedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);
        
        if(premultipliedImage) {
            CGImageRef unpremultipliedImage = [self newUnpremultipliedImageWithImage:premultipliedImage];
            CFRelease(premultipliedImage);
            if(unpremultipliedImage) {
                NSString *extension = [path pathExtension];
                NSString *noExtension = [path stringByDeletingPathExtension];
                
                NSString *newPath = [noExtension stringByAppendingPathExtension:extension];
                
                CGImageDestinationRef pngDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:newPath],
                                                                                       kUTTypePNG, 1, NULL);
                CGImageDestinationAddImage(pngDestination, unpremultipliedImage, NULL);
                CGImageDestinationFinalize(pngDestination);
                CFRelease(pngDestination);
                
                CFRelease(unpremultipliedImage);
            }
        }
    }
}

static void CGBitmapContextReleaseCFTypeRefCallback(void *releaseInfo, void *data)
{
    CFRelease(releaseInfo);
}

- (CGImageRef)newUnpremultipliedImageWithImage:(CGImageRef)image
{
    CGImageRef unpremltipliedImage = NULL;
    
    CGColorSpaceRef imageColorSpace = CGImageGetColorSpace(image);
    if(imageColorSpace) {
        CFRetain(imageColorSpace);
    } else {
        imageColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    BOOL goodBitmapInfo = NO;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
    if((bitmapInfo & kCGImageAlphaLast) == kCGImageAlphaLast) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedLast;
        goodBitmapInfo = YES;
    } else if((bitmapInfo & kCGImageAlphaFirst) == kCGImageAlphaFirst) {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        goodBitmapInfo = YES;
    } else {
        NSLog(@"Unexpected bitmap info alpha information - bitmap info is 0x%02lx - can't unpremultiply", (long)bitmapInfo);
    }
    
    if(goodBitmapInfo) {
        CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
        CGContextRef premultContext = CGBitmapContextCreateWithData((void *)CFDataGetBytePtr(data),
                                                                    CGImageGetWidth(image), CGImageGetHeight(image),
                                                                    CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image),
                                                                    imageColorSpace, bitmapInfo,
                                                                    CGBitmapContextReleaseCFTypeRefCallback, (void *)CFRetain(data));
        
        unpremltipliedImage = CGBitmapContextCreateImage(premultContext);
        
        CFRelease(premultContext);
        CFRelease(data);
    }
    
    CFRelease(imageColorSpace);
    
    return unpremltipliedImage;
}


- (NSBitmapImageFileType)imageType {
    NSString* extension = [[self pathExtension] lowercaseString];
    if ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame) {
        // JPG
        return NSJPEGFileType;
    }
    else if ([extension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
        // PNG
        return NSPNGFileType;
    }
    else if ([extension caseInsensitiveCompare:@"gif"] == NSOrderedSame) {
        // GIF
        return NSGIFFileType;
    }
    else if ([extension caseInsensitiveCompare:@"tif"] == NSOrderedSame || [extension caseInsensitiveCompare:@"tiff"] == NSOrderedSame) {
        // TIFF
        return NSTIFFFileType;
    }
    
    // Hack
    return -1;
}

- (BOOL)isRetinaImage {
    // See if the file is a retina image
    NSString* lastComponent = [[self absoluteString] lastPathComponent];
    lastComponent = [lastComponent stringByDeletingPathExtension];
    return [lastComponent hasSuffix:kRetinaString] || [lastComponent hasSuffix:kHdString] || [lastComponent hasSuffix:kIpadHDString]|| [lastComponent hasSuffix:kIpadHDString2];
;
}
- (BOOL)isAlreadyRenamed {
    // See if the file is a retina image
    NSString* lastComponent = [[self absoluteString] lastPathComponent];
    lastComponent = [lastComponent stringByDeletingPathExtension];
    return [lastComponent hasSuffix:@"1x"];
    ;
}

@end
