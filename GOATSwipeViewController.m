//
//  GOATSwipeViewController.m
//
//
//  Created by Sam Saccone on 7/17/14.
//
//

#import "GOATSwipeViewController.h"
#import <FlickrKit/FlickrKit.h>
#import <MDCSwipeToChoose/MDCSwipeToChoose.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface GOATSwipeViewController () <MDCSwipeToChooseDelegate>
@property (nonatomic, strong) NSArray *goats;
@property (nonatomic, assign) NSUInteger goatIndex;
/** Label that sits under the goat views.

 Since it's visible when there are no goats, it's used for
 displaying a loading message as well as an "out of goat"
 message.
 */
@property (nonatomic, strong) UILabel *backgroundLabel;
@end

@implementation GOATSwipeViewController

#pragma mark - View Lifecycle

- (instancetype)init
{
    self = [super init];
    
    _goatIndex = 0;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.backgroundLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundLabel.text = NSLocalizedString(@"Loading goats...", @"Loading goats message");
    self.backgroundLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.backgroundLabel];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Trigger loading goats
    [self loadGoats:^{
        // Goats have loaded
        dispatch_async(dispatch_get_main_queue(), ^{
            // on the main thread
            // Update UI with 2 new goat views
            UIView *firstView = [self viewForGoat:self.goats[0]];
            [self.view addSubview:firstView];
            UIView *secondView = [self viewForGoat:self.goats[1]];
            [self.view insertSubview:secondView belowSubview:firstView];
            self.goatIndex = 2;

            // Update background label
            self.backgroundLabel.text = NSLocalizedString(@"Out of goats 😧", @"Out of goats message");
        });
    }];
}

#pragma mark - Goat Management

/**
 Fetches a collection of goat Flickr image description dictionaries
 and saves them to the `goats` property on the view controller.

 @param onGoatLoad Called asynchronously when the goats have been loaded.
 */
- (void)loadGoats:(void (^)())onGoatLoad
{
    FKFlickrPhotosSearch *goats = [FKFlickrPhotosSearch new];
    [goats setText:@"goats"];
    
    [[FlickrKit sharedFlickrKit] call:goats
                           completion:^(NSDictionary *response, NSError *error) {
                               self.goats = ((NSDictionary *)response[@"photos"])[@"photo"];;
                               if (onGoatLoad) {
                                   onGoatLoad();
                               }
                           }];
}

/**
 Creates a new UIView for a given goat

 @param goat An image description dictionary from the Flickr API
 */
- (UIView *)viewForGoat:(NSDictionary *)goat
{
    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.likedText = @"Goat";
    options.nopeText = @"No Goat";
    
    MDCSwipeToChooseView *swipeView = [[MDCSwipeToChooseView alloc] initWithFrame:self.view.bounds
                                                                          options:options];
    swipeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    swipeView.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    swipeView.backgroundColor = [UIColor whiteColor];
    swipeView.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    [swipeView.imageView sd_setImageWithURL:[fk photoURLForSize:FKPhotoSizeLarge1024 fromPhotoDictionary:goat]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shareGoat)];
    [swipeView addGestureRecognizer:longPress];
    
    return swipeView;
}

- (NSDictionary *)nextGoat
{
    if (self.goatIndex >= self.goats.count) {
        return nil;
    }
    NSDictionary *goat = self.goats[self.goatIndex];
    self.goatIndex++;
    return goat;
}

#pragma mark - MDCSwipeToChooseDelegate Callbacks

- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction {
    [view removeFromSuperview];
    NSDictionary *nextGoat = [self nextGoat];
    if (nextGoat) {
        MDCSwipeToChooseView *swipeView = [self viewForGoat:nextGoat];
        [self.view insertSubview:swipeView aboveSubview:self.backgroundLabel];
    }
}

#pragma mark - Share

- (void)shareGoat {
    
    NSDictionary *activeGoat = self.goats[self.goatIndex -1];

    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    NSURL *activeGoatUrl = [fk photoURLForSize:FKPhotoSizeLarge1024 fromPhotoDictionary:activeGoat];

    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[activeGoatUrl] applicationActivities:nil];

    [self presentViewController:activityController animated:YES completion:nil];
}

@end
