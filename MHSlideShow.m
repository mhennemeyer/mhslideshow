//
//  MHSlideShow.m
// Copyright 2013 Matthias Hennemeyer
// License: MIT. Source: http://github.com/mhennemeyer/slideshow
//

#import "MHSlideShow.h"

@interface MHSlideShow()
@property (nonatomic, assign) NSInteger currentSlideShowIndex;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) void (^configureViewBlock)(id obj, id view);
@property (nonatomic, copy) void (^didSelectItem)(id obj);
@property (nonatomic, copy) void (^onUserScrolled)(id obj);
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation MHSlideShow

- (id)initWithFrame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void) removeFromSuperview {
    [self.pageControl removeFromSuperview];
    [super removeFromSuperview];
}

- (BOOL) hasHeader {
    return nil!=self.headerTitle;
}

- (void)setupView {
    [self setupHighlightsView];
    [self update];
}

- (void)configureItem:(void (^)(id obj, id view))block {
    self.configureViewBlock = block;
}

- (void)didSelectItem:(void (^)(id obj))block {
    self.didSelectItem = block;
}

- (void)onUserScrolled:(void (^)(id obj))block {
    self.onUserScrolled = block;
}

- (void) update {
    [self.collectionView reloadData];
}

- (void)setCellNibName:(NSString *)cellNibName {
    if ([NSClassFromString(cellNibName) conformsToProtocol:@protocol(SlideShowView)]) {
        _cellNibName = cellNibName;
        NSArray *toplevelObjects = [[NSBundle mainBundle] loadNibNamed:_cellNibName owner:self options:nil];
        UIView*view;
        for (id currentObject in toplevelObjects) {
            if ([currentObject isKindOfClass:NSClassFromString(self.cellNibName)]) {
                view = currentObject;
                break;
            }
        }
        self.prototypeView = view;
    } else {
        @throw [[NSException alloc] initWithName:@"Protocoll SlideShowView" reason:[NSString stringWithFormat:@"%@ must conform to protocoll SlideShowView. See SlideShow.h", cellNibName] userInfo:nil];
    }
}

- (NSNumber *)height {
    return [[NSNumber alloc] initWithFloat:self.frame.size.height];

}

#pragma mark - Animation

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.animated) [self stopAnimation];
    
    return [super hitTest:point withEvent:event];
}

- (void)startAnimation {
    [self.timer fire];
}

- (void)stopAnimation {
    NSLog(@"stopAnimation");
    [self.timer invalidate];
}

#pragma mark - ScrollView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.paginated) {
        CGFloat pageWidth = self.collectionView.frame.size.width;
        self.pageControl.currentPage = self.collectionView.contentOffset.x / pageWidth;
    }
}

#pragma mark - Collection View

- (void) scrollToNext {
    if (self.collection.count==0||self.collection.count==1||!self.animated) return;
    NSIndexPath *indexPath = [self nextSlideShowIndexPath];
    if (indexPath.section%self.collection.count==0) {
        
        NSMutableArray *newHighlightsOrder = [[NSMutableArray alloc] init];
        
        [newHighlightsOrder addObject:[self.collection objectAtIndex:self.collection.count-2]];
        
        [newHighlightsOrder addObject:[self.collection objectAtIndex:self.collection.count-1]];
        
        for (int i = 0; i<self.collection.count-2;i++) {
            [newHighlightsOrder addObject:[self.collection objectAtIndex:i]];
        }
        
        self.collection = newHighlightsOrder;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                              atScrollPosition:UICollectionViewScrollPositionLeft
                                                      animated:NO];
        [self.collectionView reloadData];
        self.currentSlideShowIndex = 0;
        
        indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    }
    
    
    ////NSLog(@"Slide to %@", indexPath);
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}

- (NSIndexPath *)nextSlideShowIndexPath {
    self.currentSlideShowIndex++;
    return [NSIndexPath indexPathForItem:0 inSection:self.currentSlideShowIndex%self.collection.count];
}

- (void)swipedRight {
    NSLog(@"Swiped Right");
}

- (void)swipedLeft {
    NSLog(@"Swiped Right");
}

- (void)pageControlPageChanged:(id)sender {
    NSInteger item = [self.pageControl currentPage];
    if (self.paginated) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:item] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    }
}



- (void)setupHighlightsView {
    if (self.animated) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(scrollToNext) userInfo:nil repeats:YES];
    }
    
    
    
    self.currentSlideShowIndex = 0;
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGFloat contentWidth = self.frame.size.width;//[self.collection count] * [self cellFrame].size.width;
    
    
    NSLog(@"SlideShow ContentWidth: %f", contentWidth);
    
    CGRect frameForContent = CGRectMake(0, 0, contentWidth, [self cellFrame].size.height +  self.borderSize.height );
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:frameForContent collectionViewLayout:layout];
    
    if (self.paginated) {
        self.collectionView.pagingEnabled = YES;
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
        self.pageControl.numberOfPages = [self.collection count];
        [self.pageControl sizeToFit];
        
        CGRect newFrameForPageControl = self.pageControl.frame;
        NSLog(@"page pos: %f", self.pageControl.frame.size.width);
        newFrameForPageControl.origin = CGPointMake(self.frame.size.width/2 - newFrameForPageControl.size.width/2, self.frame.size.height - 35);
        self.pageControl.frame = newFrameForPageControl;
        self.pageControl.backgroundColor = [UIColor clearColor];
        [self.pageControl addTarget:self action:@selector(pageControlPageChanged:) forControlEvents:UIControlEventValueChanged];
        if ([self.collection count]<2) {
            self.pageControl.hidden = YES;
        }
    }
    
    
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    

    
    [self addSubview:self.collectionView];
    
    CGFloat containerWidth = [self.collection count] * [self cellFrame].size.width;
    NSLog(@"SlideShow ContainerWidth: %f", containerWidth);
    
    
    CGRect frameForContainer = CGRectMake(
                                          self.frame.origin.x,
                                          self.frame.origin.y,
                                          containerWidth,
                                          frameForContent.size.height + self.borderSize.height);
    self.frame = frameForContainer;
    if (nil==self.collection||self.collection.count==0)
        self.frame = CGRectZero;
}



- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.collection count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

// todo ??? deselect ???
- (void)didSelectObject:(id)obj {
    NSLog(@"didSelect:%@" ,obj);
    if (nil!=self.didSelectItem) {
        self.didSelectItem(obj);
    }
}

- (CGRect)cellFrame {
    return CGRectMake(self.borderSize.width, self.borderSize.height, self.cellSize.width+ self.borderSize.width, self.cellSize.height + self.borderSize.height);
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    
    if ([[cell subviews] count]>0) {
        [cell.subviews[0] removeFromSuperview];
    }
    
    NSArray *toplevelObjects = [[NSBundle mainBundle] loadNibNamed:self.cellNibName owner:self options:nil];
    
    UIView<SlideShowView> *view;
    for (id currentObject in toplevelObjects) {
        if ([currentObject isKindOfClass:NSClassFromString(self.cellNibName)]) {
            view = currentObject;
            break;
        }
    }
    
    id obj = [self.collection objectAtIndex:indexPath.section];
    view.content = obj;
    self.configureViewBlock(obj, view);
    
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showDetailForHighlight:)]];
    
    
    CGRect newFrame = [self cellFrame];
    view.frame = newFrame;

    [cell addSubview:view];

    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize retVal = CGSizeZero;
    retVal.height = [self cellFrame].size.height + 2* self.borderSize.height;
    retVal.width  = [self cellFrame].size.width + self.borderSize.width;
    return retVal;
}

//- (void)updateHighlightsView {
//    self.slideShowDisabled = !self.animated;
//    self.highlights = [self.utilities parseFilterToEvents:[[self.utilities share] tipps] andFilter:nil];
//    [self.highlightsCollectionView reloadData];
//}
//
- (void)showDetailForHighlight:(id)gestureRecognizer {
    id<SlideShowView> view = (id)[gestureRecognizer view];
    NSLog(@"didSelect in Slideshow");
    [self didSelectObject:[view content]];
}

@end
