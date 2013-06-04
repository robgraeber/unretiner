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
        //renames all normal image files to @4x
        NSString * fullFileName = [self lastPathComponent];
        NSString * fileExtension = [fullFileName pathExtension];
        NSString * fileName = [fullFileName stringByDeletingPathExtension];
        NSString * newFileName = [fileName stringByAppendingString:@"@4x"];
        NSString * newFullFileName = [newFileName stringByAppendingPathExtension:fileExtension];
        NSString *oldPath = self.path;
        
        NSString *temp = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-temp", newFullFileName]];
        NSString *target = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFullFileName];
        
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:temp error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:temp toPath:target error:nil];
        
        success = YES;
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

@end
