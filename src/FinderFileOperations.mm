#import "FinderFileOperations.h"
#import <AppKit/AppKit.h>

@implementation FinderFileOperations

+ (void)revealInFinder:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
}

+ (void)openTerminalAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    [fm fileExistsAtPath:path isDirectory:&isDir];
    NSString *dir = isDir ? path : [path stringByDeletingLastPathComponent];

    // Shelling out to /usr/bin/open is the standard, supported way to hand a
    // directory to the user's default terminal app — no AppleScript, no
    // private API, no new dependency.
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-a", @"Terminal", dir];
    @try {
        [task launch];
    } @catch (NSException *ex) {
        NSLog(@"[Finder] Failed to launch Terminal: %@", ex);
    }
}

+ (void)openWithDefaultApplication:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

+ (NSString *)uniqueNameInDirectory:(NSString *)directoryPath
                          baseName:(NSString *)baseName
                         extension:(nullable NSString *)extension {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ext = extension.length > 0 ? [@"." stringByAppendingString:extension] : @"";
    NSString *candidate = [baseName stringByAppendingString:ext];
    NSString *fullPath = [directoryPath stringByAppendingPathComponent:candidate];
    if (![fm fileExistsAtPath:fullPath]) return candidate;

    for (NSInteger i = 2; i < 10000; i++) {
        candidate = [NSString stringWithFormat:@"%@ %ld%@", baseName, (long)i, ext];
        fullPath = [directoryPath stringByAppendingPathComponent:candidate];
        if (![fm fileExistsAtPath:fullPath]) return candidate;
    }
    // Extremely unlikely fallback.
    return [NSString stringWithFormat:@"%@ %@%@", baseName, [NSUUID UUID].UUIDString, ext];
}

+ (nullable NSString *)createNewFileInDirectory:(NSString *)directoryPath
                                           error:(NSError **)error {
    NSString *name = [self uniqueNameInDirectory:directoryPath baseName:@"Untitled" extension:@"txt"];
    NSString *fullPath = [directoryPath stringByAppendingPathComponent:name];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm createFileAtPath:fullPath contents:[NSData data] attributes:nil]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FinderPlugin" code:1
                                      userInfo:@{NSLocalizedDescriptionKey: @"Could not create file."}];
        }
        return nil;
    }
    return fullPath;
}

+ (nullable NSString *)createNewFolderInDirectory:(NSString *)directoryPath
                                             error:(NSError **)error {
    NSString *name = [self uniqueNameInDirectory:directoryPath baseName:@"Untitled Folder" extension:nil];
    NSString *fullPath = [directoryPath stringByAppendingPathComponent:name];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:error]) {
        return nil;
    }
    return fullPath;
}

+ (nullable NSString *)renameItemAtPath:(NSString *)path
                                 toName:(NSString *)newName
                                  error:(NSError **)error {
    if (newName.length == 0 || [newName containsString:@"/"]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FinderPlugin" code:2
                                      userInfo:@{NSLocalizedDescriptionKey: @"Invalid name."}];
        }
        return nil;
    }
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *newPath = [directory stringByAppendingPathComponent:newName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:newPath] && ![newPath isEqualToString:path]) {
        if (error) {
            *error = [NSError errorWithDomain:@"FinderPlugin" code:3
                                      userInfo:@{NSLocalizedDescriptionKey: @"An item with that name already exists."}];
        }
        return nil;
    }
    if (![fm moveItemAtPath:path toPath:newPath error:error]) {
        return nil;
    }
    return newPath;
}

+ (BOOL)moveItemToTrash:(NSString *)path error:(NSError **)error {
    NSURL *url = [NSURL fileURLWithPath:path];
    return [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:nil error:error];
}

+ (void)copyPathToPasteboard:(NSString *)path {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:path forType:NSPasteboardTypeString];
}

+ (void)copyNameToPasteboard:(NSString *)path {
    NSString *name = [path lastPathComponent];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:name forType:NSPasteboardTypeString];
}

+ (nullable NSString *)duplicateItemAtPath:(NSString *)path error:(NSError **)error {
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *ext = [path pathExtension];
    NSString *baseNoExt = [path lastPathComponent];
    if (ext.length > 0) {
        baseNoExt = [baseNoExt stringByDeletingPathExtension];
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *candidateName = [NSString stringWithFormat:@"%@ copy", baseNoExt];
    NSString *candidate = ext.length > 0 ? [candidateName stringByAppendingPathExtension:ext] : candidateName;
    NSString *fullPath = [directory stringByAppendingPathComponent:candidate];

    NSInteger suffix = 2;
    while ([fm fileExistsAtPath:fullPath]) {
        candidateName = [NSString stringWithFormat:@"%@ copy %ld", baseNoExt, (long)suffix];
        candidate = ext.length > 0 ? [candidateName stringByAppendingPathExtension:ext] : candidateName;
        fullPath = [directory stringByAppendingPathComponent:candidate];
        suffix++;
        if (suffix > 10000) break; // safety valve
    }

    if (![fm copyItemAtPath:path toPath:fullPath error:error]) {
        return nil;
    }
    return fullPath;
}

@end
