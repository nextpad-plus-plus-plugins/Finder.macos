#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class FinderPanelView;

@protocol FinderPanelViewDelegate <NSObject>
/// User double-clicked (or pressed Return/Cmd-O on) a file — open it in Nextpad++.
- (void)finderPanelView:(FinderPanelView *)view openFileAtPath:(NSString *)path;

/// User clicked the "Locate Current File" toolbar button. The plugin knows
/// the active buffer's path (via NPPM_GETFULLCURRENTPATH) — the view itself
/// deliberately has no reference to nppData, so it asks the delegate and,
/// if a path comes back, is expected to receive a follow-up call to
/// -revealAndSelectPath:.
- (void)finderPanelViewDidRequestLocateCurrentFile:(FinderPanelView *)view;
@end

/// Sidebar panel: folder tree (left) + file list (right) over the real
/// filesystem, with Finder-style context menu actions. This is the
/// macOS-native analogue of the classic Windows "Explorer" Notepad++ plugin
/// (drive/root picker + tree + file list + reveal/rename/delete/terminal).
///
/// All filesystem access is synchronous NSFileManager enumeration scoped to
/// one directory at a time (lazy-loaded on expand/navigate), which keeps
/// this simple and fast enough for interactive use without background
/// threads or a file-system-event dependency.
@interface FinderPanelView : NSView

@property (nonatomic, weak, nullable) id<FinderPanelViewDelegate> delegate;

/// Navigates the tree + file list to show `path` (a directory). If `path`
/// is a file, its containing directory is shown and the file is selected
/// and scrolled into view in the file list.
- (void)navigateToPath:(NSString *)path;

/// Convenience for the "Locate Current File" toolbar/menu action.
- (void)revealAndSelectPath:(NSString *)path;

/// Currently displayed root directory (persisted by the plugin between
/// sessions via FinderPreferences).
@property (nonatomic, readonly, copy) NSString *currentRootPath;

@end

NS_ASSUME_NONNULL_END
