//
//  MHSlideShow.h
// Copyright 2013 Matthias Hennemeyer
// License: MIT. Source: http://github.com/mhennemeyer/mhslideshow
//

#import <UIKit/UIKit.h>

@protocol SlideShowView <NSObject>
- (id)content;
- (void)setContent:(id)content;
@end

@interface MHSlideShow : UIView <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSArray *collection;
@property (nonatomic, assign) BOOL animated;
@property (nonatomic, assign) BOOL paginated;
@property (nonatomic, strong) NSString *headerTitle;
@property (nonatomic, strong) NSString *cellNibName;
@property (nonatomic, strong) UIView *prototypeView;
@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, assign) CGSize borderSize;
@property (nonatomic, strong) UIPageControl *pageControl;

- (void) setupView;
- (void) configureItem:(void (^)(id obj, id view))block;
- (void) update;
- (NSNumber *)height;
- (void)didSelectItem:(void (^)(id obj))block;
- (void)startAnimation;
- (void)stopAnimation;
@end
