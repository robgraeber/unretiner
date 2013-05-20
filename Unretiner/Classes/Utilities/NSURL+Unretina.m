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

- (BOOL)unretina:(NSURL*)folder errors:(NSMutableArray*)errors warnings:(NSMutableArray*)warnings overwrite:(BOOL)overwrite {
    BOOL success = NO;
    if (![self isRetinaImage]) {
        NSString* lastComponent = [[self absoluteString] lastPathComponent];
        NSString *pathExtension = [lastComponent pathExtension];
        NSMutableString *afileName = [[lastComponent stringByDeletingPathExtension] mutableCopy];
        [afileName appendFormat:@"@2x.%@",pathExtension];
        NSString* copyURL = [NSString stringWithFormat:@"%@%@", [folder relativeString], afileName];
        [afileName release];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtURL:self toURL:[NSURL URLWithString:copyURL] error:&error];
        
    }
    //if ([self isRetinaImage]) {
    // New path is the same file minus the @2x
    NSString* newFilename = [[self lastPathComponent] stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
    newFilename = [newFilename stringByReplacingOccurrencesOfString:@"-hd" withString:@""];
    newFilename = [newFilename stringByReplacingOccurrencesOfString:@"-ipadhd" withString:@"-hd"];
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
            
            CGFloat _newWidth = ((((int)[sourceImage size].width) == 1) ? 1 : ([sourceImage size].width / 2.0));
            CGFloat _newHeight = ((((int)[sourceImage size].height) == 1) ? 1 : ([sourceImage size].height / 2.0));
            
            // Create a bitmap representation
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithWidth:_newWidth andHeight:_newHeight];
            [imageRep setImage:sourceImage];
            
            // Write out the new image
            NSData *imageData = [imageRep representationUsingType:imageType properties:nil];
            if (![imageData writeToURL:newUrl atomically:YES]) {
                [errors addObject:[NSString stringWithFormat:@"%@ : Error creating file", newPath]];
            }
            else {
                success = YES;
            }
        }
        else {
            [errors addObject:[NSString stringWithFormat:@"%@ : Unknown image type", [[self absoluteString] lastPathComponent]]];
        }
    }
    else {
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
    if([newUrl isRetinaImage]){
        [newUrl unretina:folder errors:errors warnings:warnings overwrite:overwrite];
    }
    return success;
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
    return [lastComponent hasSuffix:kRetinaString] || [lastComponent hasSuffix:kHdString] || [lastComponent hasSuffix:kIpadHDString];
}

@end
