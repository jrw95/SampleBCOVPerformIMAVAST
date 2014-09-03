//
//  ViewController.m
//  SampleBCOVPerformIMAVAST
//
//  Created by Jim Whisenant on 8/27/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

#import "ViewController.h"


static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";

static NSString * const kViewControllerIMAVASTResponseAdTag1 = @"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fhanna_MA_group%2Fvideo_comp_app&ciu_szs=&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&correlator=[timestamp]";
static NSString * const kViewControllerIMAVASTResponseAdTag2 = @"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fhanna_MA_group%2Fwrapper_with_comp&ciu_szs=728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&correlator=[timestamp]";
static NSString * const kViewControllerIMAVASTResponseAdTag3 = @"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fhanna_MA_group%2Fwrapper_with_comp&ciu_szs=728x90&impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&m_ast=vast";


@interface ViewController ()

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, assign) BOOL isBrowserOpen;
@property (nonatomic, weak) id<BCOVPlaybackSession> currentPlaybackSession;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property BOOL adTagWillConfigureOnPlaylist;

@end


@implementation ViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

-(void)setup
{
    
    self.adTagWillConfigureOnPlaylist = YES;
    
    self.adIsPlaying = NO;
    self.isBrowserOpen = NO;
    
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
    
    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;
    
    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    BCOVIMASessionProviderOptions *sessionProviderOption = [BCOVIMASessionProviderOptions VASTOptions];
    
    if (self.adTagWillConfigureOnPlaylist)
    {
        sessionProviderOption.adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyFromCuePointPropertiesWithAdTag:kViewControllerIMAVASTResponseAdTag1 adsCuePointProgressPolicy:nil];
    }
    id<BCOVPlaybackSessionProvider> playbackSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings adsRenderingSettings:renderSettings upstreamSessionProvider:nil options:sessionProviderOption];

    id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:playbackSessionProvider viewStrategy:[self viewStrategyWithFrame:CGRectMake(0, 0, 400, 400)]];

    playbackController.delegate = self;
    self.playbackController = playbackController;
    
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.
    // We will use @weakify(self)/@strongify(self) a few times later in the code.
    // For more info on weakify/strongify, visit https://github.com/jspahrsummers/libextobjc.
    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:self queue:nil usingBlock:^(NSNotification *note) {
        
        @strongify(self);
        
        if (self.adIsPlaying && !self.isBrowserOpen)
        {
            [self.playbackController resumeAd];
        }
        
    }];

    [self configureContent];

    // Set autoPlay to YES to initiate playback as soon as the PlaybackController is created.
    // [[self playbackController] setAutoPlay:YES];

    // Set autoAdvance to YES to automatically advance to the next video in your playlist.
    // [[self playbackController] setAutoAdvance:YES];
    
}

- (void)configureContent
{

    // create an array of videos
    NSArray *videos = @[[self videoWithURL:[NSURL URLWithString:@"http://solutions.brightcove.com/bcls/assets/videos/BirdsOfAFeather.mp4"]],
                        [self videoWithURL:[NSURL URLWithString:@"http://solutions.brightcove.com/bcls/assets/videos/Sea-Marvels.mp4"]]
                        ];
    
    NSMutableArray *newVideos = [NSMutableArray arrayWithCapacity:videos.count];
    
    for (BCOVVideo *video in videos)
    {
        // Update each video to add the tag.
        BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
            
            if (self.adTagWillConfigureOnPlaylist)
            {
                mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeBefore],
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(25,1)],
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeAfter]
                 ]];
            }
            else
            {
                mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeBefore properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag1 }],
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(25,1) properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag2 }],
                 [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeAfter properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag3 }],
                 ]];
            }
        }];
        
        [newVideos addObject:updatedVideo];

    }
    
    [self.playbackController setVideos:newVideos];

}

- (void)willOpenInAppBrowser
{
    self.isBrowserOpen = YES;
}

- (void)willCloseInAppBrowser
{
    self.isBrowserOpen = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.playbackController.view.frame = self.videoContainerView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainerView addSubview:self.playbackController.view];
}

-(void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.currentPlaybackSession = session;
    NSLog(@"ViewController Debug - Advanced to new session.");
}

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVIMAComponent.h.
    
    NSString *type = lifecycleEvent.eventType;
    
    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController Debug - Ads loaded.");
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
        
        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                self.adIsPlaying = YES;
                NSLog(@"ViewController Debug - Ad Started.");
                break;
            case kIMAAdEvent_COMPLETE:
                self.adIsPlaying = NO;
                NSLog(@"ViewController Debug - Ad Completed.");
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController Debug - All ads completed.");
                break;
            default:
                break;
        }
        
    }
}

- (BCOVPlaybackControllerViewStrategy)videoStillViewStrategyWithFrame
{
    return [^ UIView * (UIView *videoView, id<BCOVPlaybackController> playbackController) {
        
        // Returns a view which covers `videoView` with a UIImageView
        // whose background is black and which presents the video still from
        // each video as it becomes the current video.
        VideoStillView *stillView = [[VideoStillView alloc] initWithVideoView:videoView];
        VideoStillViewMediator *stillViewMediator = [[VideoStillViewMediator alloc] initWithVideoStillView:stillView];
        // The Google Ads SDK for IMA does not play prerolls instantly when
        // the AVPlayer starts playing. Delaying the dismissal of the video
        // still for a second prevents the first video frame from "flashing"
        // briefly when this happens.
        stillViewMediator.dismissalDelay = 1.f;
        
        // (You should save `consumer` to an instance variable if you will need
        // to remove it from the playback controller's session consumers.)
        BCOVDelegatingSessionConsumer *consumer = [[BCOVDelegatingSessionConsumer alloc] initWithDelegate:stillViewMediator];
        [playbackController addSessionConsumer:consumer];
        
        return stillView;
        
    } copy];
}

- (BCOVPlaybackControllerViewStrategy)viewStrategyWithFrame:(CGRect)frame
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    // In this example, we use the defaultControlsViewStrategy. In real app, you
    // wouldn't be using this.  You would add your controls and container view
    // in the composedViewStrategy block below.
    BCOVPlaybackControllerViewStrategy stillViewStrategy = [self videoStillViewStrategyWithFrame];
    BCOVPlaybackControllerViewStrategy defaultControlsViewStrategy = [manager defaultControlsViewStrategy];
    BCOVPlaybackControllerViewStrategy imaViewStrategy = [manager BCOVIMAAdViewStrategy];
    
    // We create a composed view strategy using the defaultControlsViewStrategy
    // and the BCOVIMAAdViewStrategy.  The purpose of this block is to ensure
    // that the ads appear above above the controls so that we don't need to
    // implement any logic to show and hide the controls.  This should be customized
    // how you see fit.
    // This block is not executed until the playbackController.view property is
    // accessed, even though it is an initialization property. You can
    // use the playbackController property to add an object as a session consumer.
    BCOVPlaybackControllerViewStrategy composedViewStrategy = ^ UIView * (UIView *videoView, id<BCOVPlaybackController> playbackController) {
        
        videoView.frame = frame;
        
        UIView *viewWithStill = stillViewStrategy(videoView, playbackController);
        UIView *viewWithControls = defaultControlsViewStrategy(viewWithStill, playbackController); //Replace this with your own container view.
        UIView *viewWithAdsAndControls = imaViewStrategy(viewWithControls, playbackController);
        
        return viewWithAdsAndControls;
        
    };
    
    return [composedViewStrategy copy];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BCOVVideo *)videoWithURL:(NSURL *)url
{
    // set the delivery method for BCOVSources that belong to a video
    BCOVSource *source = [[BCOVSource alloc] initWithURL:url deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
    return [[BCOVVideo alloc] initWithSource:source cuePoints:[BCOVCuePointCollection collectionWithArray:@[]] properties:@{}];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
