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

@interface GOATSwipeViewController ()
@property (nonatomic, strong) UIImageView *goatView;
@property (nonatomic, strong) NSArray *goats;
@end

@implementation GOATSwipeViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSDictionary *keys = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keys" ofType:@"plist"]];
        
        [[FlickrKit sharedFlickrKit] initializeWithAPIKey:keys[@"flickr_key"]  sharedSecret:keys[@"flickr_secret"]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self goatView] setFrame:self.view.bounds];
    [[self goatView] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth ];
    [[self view] addSubview:[self goatView]];
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateDisplayGoat)];
    [self.goatView addGestureRecognizer:tapper];
    [self.goatView setUserInteractionEnabled:YES];
}

- (UIImageView*) goatView
{
    if (_goatView == nil) {
        _goatView = [UIImageView new];
        _goatView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _goatView;
}

- (void)updateDisplayGoat
{
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    
    NSDictionary *photo = self.goats[arc4random_uniform(self.goats.count)];
    NSURL *url = [fk photoURLForSize:FKPhotoSizeLarge1024 fromPhotoDictionary:photo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.goatView respondsToSelector:@selector(sd_setImageWithURL:)]) {
            [self.goatView sd_setImageWithURL:url];
        }
    });
}

- (void)loadGoat:(void (^)())onGoatLoad
{
    if (self.goats != nil) {
        [self updateDisplayGoat];
        return;
    }
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    
    FKFlickrPhotosSearch *goats = [FKFlickrPhotosSearch new];
    
    [goats setText:@"goats"];
    
    [fk call:goats completion:^(NSDictionary *response, NSError *error) {
        NSArray *photoArray = ((NSDictionary *)response[@"photos"])[@"photo"];
        
        self.goats = photoArray;
        if (onGoatLoad) {
            onGoatLoad();
        }
    }];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadGoat:^{
        [self updateDisplayGoat];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
