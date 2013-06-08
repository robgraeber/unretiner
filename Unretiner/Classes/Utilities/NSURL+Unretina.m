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
