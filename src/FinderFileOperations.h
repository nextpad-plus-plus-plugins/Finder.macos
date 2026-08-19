#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Stateless helpers that bridge the plugin's tree/list UI to real macOS
/// Finder/filesystem behavior. Everything here uses only NSWorkspace,
/// NSFileManager and NSTask (to shell out to /usr/bin/open) — no
/// third-party dependency, no private API.
@interface FinderFileOperations : NSObject

/// Reveals the given path in Finder (select it, bring Finder to front).
+ (void)revealInFinder:(NSString *)path;

/// Opens /usr/bin/open -a Terminal <path>, i.e. a new Terminal window/tab
/// cd'd into the given directory. If `path` is a file, uses its containing
/// directory.
+ (void)openTerminalAtPath:(NSString *)path;

/// Opens the file/folder with the OS default application (double-click
/// behavior), same as Finder's "Open".
+ (void)openWithDefaultApplication:(NSString *)path;

/// Creates an empty new file named "Untitled.txt" (auto-incrementing to
/// avoid collisions) inside directoryPath. Returns the new file's path, or
/// nil on failure (with *error set).
+ (nullable NSString *)createNewFileInDirectory:(NSString *)directoryPath
                                           error:(NSError **)error;

/// Creates a new folder named "Untitled Folder" (auto-incrementing) inside
/// directoryPath. Returns the new folder's path, or nil on failure.
+ (nullable NSString *)createNewFolderInDirectory:(NSString *)directoryPath
                                             error:(NSError **)error;

/// Renames the item at path to newName (just the last path component).
/// Returns the new full path, or nil on failure.
+ (nullable NSString *)renameItemAtPath:(NSString *)path
                                 toName:(NSString *)newName
                                  error:(NSError **)error;

/// Moves the item to the Trash (NSWorkspace recycle behavior — recoverable,
/// unlike NSFileManager removeItem which deletes permanently).
+ (BOOL)moveItemToTrash:(NSString *)path error:(NSError **)error;

/// Copies the absolute POSIX path onto the pasteboard as plain text.
+ (void)copyPathToPasteboard:(NSString *)path;

/// Copies just the last path component (file/folder name) onto the pasteboard.
+ (void)copyNameToPasteboard:(NSString *)path;

/// Duplicates the item, mimicking Finder's "Duplicate" naming ("Foo copy",
/// "Foo copy 2", ...). Returns the new path, or nil on failure.
+ (nullable NSString *)duplicateItemAtPath:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
