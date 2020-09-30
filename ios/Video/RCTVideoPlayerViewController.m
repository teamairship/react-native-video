#import "RCTVideoPlayerViewController.h"

@interface RCTVideoPlayerViewController ()

@end

@implementation RCTVideoPlayerViewController

- (BOOL)shouldAutorotate {

  if (self.autorotate || self.preferredOrientation.lowercaseString == nil || [self.preferredOrientation.lowercaseString isEqualToString:@"all"])
    return YES;
  
  return NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [_rctDelegate videoPlayerViewControllerWillDismiss:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    _isFullScreen = false;
}

- (void) orientationChanged:(NSNotification *)note {
    UIDevice * device = note.object;
    
    switch(device.orientation) {
        case UIDeviceOrientationLandscapeRight:
        case UIDeviceOrientationLandscapeLeft:
            [self goFullscreen];
        default: break;
    };
}

- (void)goFullscreen {
    if (_isFullScreen || ![self.view isDescendantOfView:self.parentViewController.view]) {
        return;
    }
    
    _isFullScreen = true;
    
    [_rctDelegate videoPlayerWillPresentFullScreen];
    
    NSString *selectorForFullscreen = @"transitionToFullScreenViewControllerAnimated:completionHandler:";
    if (@available(iOS 11.3, *)) {
        selectorForFullscreen = @"transitionToFullScreenAnimated:interactive:completionHandler:";
    } else if (@available(iOS 11.0, *)) {
        selectorForFullscreen = @"transitionToFullScreenAnimated:completionHandler:";
    }
    
    SEL fullScreenSEL = NSSelectorFromString([@"_" stringByAppendingString:selectorForFullscreen]);
    
    if ([self respondsToSelector:fullScreenSEL]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:fullScreenSEL]];
        [invocation setSelector:fullScreenSEL];
        [invocation setTarget:self];
        
        NSInteger index = 2; //arguments 0 and 1 are self and _cmd respectively, automatically set
        BOOL animated = YES;
        [invocation setArgument:&(animated) atIndex:index];
        index++;
        
        if (@available(iOS 11.3, *)) {
            BOOL interactive = YES;
            [invocation setArgument:&(interactive) atIndex:index]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
            index++;
        }
        
        id completionBlock = ^void() {
            [self.rctDelegate videoPlayerDidPresentFullScreen];
        };
        
        [invocation setArgument:&(completionBlock) atIndex:index];
        [invocation invoke];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#if !TARGET_OS_TV
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  if ([self.preferredOrientation.lowercaseString isEqualToString:@"landscape"]) {
    return UIInterfaceOrientationLandscapeRight;
  }
  else if ([self.preferredOrientation.lowercaseString isEqualToString:@"portrait"]) {
    return UIInterfaceOrientationPortrait;
  }
  else { // default case
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return orientation;
  }
}
#endif

@end
