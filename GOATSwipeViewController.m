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
@property (nonatomic, strong) UILabel *backgroundLabel;
@end

@implementation GOATSwipeViewController

#pragma mark - View Lifecycle

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
    
    [self loadGoats:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *firstView = [self swipeViewForGoat:self.goats[0]];
            [self.view addSubview:firstView];
            [self.view insertSubview:[self swipeViewForGoat:self.goats[1]] belowSubview:firstView];
            self.goatIndex = 2;
            self.backgroundLabel.text = NSLocalizedString(@"Out of goats 😧", @"Out of goats message");
        });
    }];
}

#pragma mark - Goat Management

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

- (MDCSwipeToChooseView *)swipeViewForGoat:(NSDictionary *)goat
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
        MDCSwipeToChooseView *swipeView = [self swipeViewForGoat:nextGoat];
        [self.view insertSubview:swipeView aboveSubview:self.backgroundLabel];
    }
}

@end
