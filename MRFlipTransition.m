//
//  MRFlipTransitionAnimator.m
//  LayerContentScaleTest
//
//  Created by mmt on 20/6/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//

#import "MRFlipTransition.h"

@interface MRGradientShadowedLayer : CALayer

@property (nonatomic, strong)   CAGradientLayer *shadowCover;

+ (instancetype)layerWithShadowBeginFromTop:(BOOL)top;

@end

@implementation MRGradientShadowedLayer

- (instancetype)initWithShadowBeginFromTop:(BOOL)top
{
    self = [super init];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor].CGColor;
        
        self.shadowCover = [CAGradientLayer layer];
        self.shadowCover.colors = top ?
        @[(id)[UIColor colorWithWhite:0 alpha:0.4].CGColor,
          (id)[UIColor clearColor].CGColor]
        : @[(id)[UIColor clearColor].CGColor,
            (id)[UIColor colorWithWhite:0 alpha:0.4].CGColor];
        [self addSublayer:self.shadowCover];
        
        self.shadowColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
        self.shadowOffset = CGSizeMake(0, top ? 1 : -1);
        self.shadowRadius = 2.0;
        self.shadowOpacity = 0.8;
    }
    
    return self;
}

+ (instancetype)layerWithShadowBeginFromTop:(BOOL)top
{
    return [[MRGradientShadowedLayer alloc] initWithShadowBeginFromTop:top];
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    self.shadowCover.frame = self.bounds;
    self.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

@end

@interface MRTransformView : UIView

@property (nonatomic, strong)   CATransformLayer    *transformLayer;
@property (nonatomic, strong)   MRGradientShadowedLayer *lowerLayer;
@property (nonatomic, strong)   CALayer                 *upperFrontLayer;
@property (nonatomic, strong)   MRGradientShadowedLayer *upperBackLayer;

@end

@implementation MRTransformView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.transformLayer = [CATransformLayer layer];
        [self.layer addSublayer:self.transformLayer];
        
        self.lowerLayer = [MRGradientShadowedLayer layerWithShadowBeginFromTop:YES];
        self.lowerLayer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        self.lowerLayer.contentsRect = CGRectMake(0, 0.5, 1, 0.5);
        self.lowerLayer.doubleSided = NO;
        [self.transformLayer addSublayer:self.lowerLayer];
        
        self.upperFrontLayer = [CALayer layer];
        self.upperFrontLayer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        self.upperFrontLayer.anchorPoint = CGPointMake(0.5, 0.0);
        self.upperFrontLayer.contentsRect = CGRectMake(0, 0.5, 1, 0.5);
        self.upperFrontLayer.doubleSided = NO;
        [self.transformLayer addSublayer:self.upperFrontLayer];
        
        self.upperBackLayer = [MRGradientShadowedLayer layerWithShadowBeginFromTop:NO];
        self.upperBackLayer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        self.upperBackLayer.anchorPoint = CGPointMake(0.5, 1.0);
        self.upperBackLayer.contentsRect = CGRectMake(0, 0, 1, 0.5);
        self.upperBackLayer.doubleSided = NO;
        [self.transformLayer addSublayer:self.upperBackLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.transformLayer.frame = self.bounds;
    CATransform3D sublayerTransform = self.transformLayer.sublayerTransform;
    sublayerTransform.m34 = -1 / (CGRectGetHeight(self.bounds) * 4.7 * 0.5);
    self.transformLayer.sublayerTransform = sublayerTransform;
    
    CGRect upperRect = CGRectMake(0,
                                  0,
                                  CGRectGetWidth(self.bounds),
                                  CGRectGetHeight(self.bounds) / 2.0);
    CGRect lowerRect = CGRectMake(0,
                                  CGRectGetHeight(upperRect),
                                  CGRectGetWidth(upperRect),
                                  CGRectGetHeight(upperRect));
    
    self.upperFrontLayer.frame = self.lowerLayer.frame = lowerRect;
    self.upperBackLayer.frame = upperRect;
}

@end

typedef UIViewController *(^MRFlipTransitionReturnBlock)(void);

@interface MRFlipTransition ()

@property (nonatomic, strong)                   UIImage                         *contentImage;
@property (assign, getter = isPresentAnimation) BOOL                            presentAnimation;
@property (nonatomic, weak)                     UIViewController                *presentingViewController;
@property (assign)                              MRFlipTransitionPresentingStyle style;
@property (nonatomic, strong)                   MRTransformView                 *transformView;
@property (copy, nonatomic)                     MRFlipTransitionReturnBlock     presentBlock;
@property (nonatomic, strong)                   UIView                          *shadowView;

@end

static NSTimeInterval   const MRFlipEaseInDuration = 0.4;
static NSTimeInterval   const MRFlipLayerDuration = 0.8;
static CGFloat          const MRInfinityMerginY = 10.0;
static CGFloat          const MREaseInExtraDistance = 40.0;
static CGFloat          const MRScaleFactor = 0.875;
static CGFloat          const MRInfinityFactor = 0.01;

@implementation MRFlipTransition

- (instancetype)initWithPresentingViewController:(UIViewController *)controller presentBlock:(UIViewController *(^)(void))block
{
    NSParameterAssert(controller && block);
    self = [super init];
    if (self)
    {
        _presentAnimation = YES;
        _presentingViewController = controller;
        _presentBlock = block;
        _shadowView = [[UIView alloc] initWithFrame:CGRectZero];
        _shadowView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        _shadowView.layer.opacity = 0.0;
    }
    
    return self;
}

- (void)presentFrom:(MRFlipTransitionPresentingStyle)direction completion:(void(^)(void))completion
{
    UIViewController *controller = self.presentBlock();
    if (!_presentAnimation || !controller || self.presentingViewController.presentedViewController)
    {
        return;
    }
 
    _style = direction;
    controller.modalPresentationStyle = UIModalPresentationCustom;
    controller.transitioningDelegate = self;
    [self.presentingViewController presentViewController:controller animated:YES completion:completion];
}

- (void)dismissTo:(MRFlipTransitionPresentingStyle)direction completion:(void(^)(void))completion
{
    if (_presentAnimation || !self.presentingViewController.presentedViewController || self.presentingViewController.presentedViewController.isBeingDismissed)
    {
        return;
    }
    
    _style = direction;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

#pragma mark - Snapshot
- (void)updateContentSnapshot:(UIView *)view afterScreenUpdate:(BOOL)update
{
    if (CGSizeEqualToSize(view.bounds.size, CGSizeZero))
    {
        return;
    }
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:update];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.contentImage = snapshotImage;
}

#pragma mark - UIViewControllerAnimatedTransitioning delegate
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return MRFlipEaseInDuration + MRFlipLayerDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    _transformView.upperFrontLayer.contents = (__bridge id)(self.coverImage.CGImage);
    
    if (_presentAnimation)
    {
        _transformView = [[MRTransformView alloc] initWithFrame:containerView.bounds];
        _shadowView.frame = containerView.bounds;
        
        [self prepareLayersWithCompletionBlock:^{
            
            CGRect endFrame = fromViewController.view.bounds;
            toViewController.view.frame = endFrame;
            toViewController.view.alpha = 0.0;
            
            [containerView addSubview:toViewController.view];
            [containerView addSubview:_shadowView];
            [containerView addSubview:_transformView];
            
            _transformView.upperBackLayer.contents = (__bridge id)(self.contentImage.CGImage);
            _transformView.lowerLayer.contents = (__bridge id)(self.contentImage.CGImage);
            
            [self animateEaseInAnimationWithCompletionBlock:^{
                [self animateFlipFrontLayerWithCompletionBlock:^{
                    
                    _transformView.upperFrontLayer.opacity = 0.0;
                    _transformView.upperBackLayer.opacity = 1.0;
                    
                    [self animateFlipBackLayerWithCompletionBlock:^{
                        
                        BOOL isCancelled = [transitionContext transitionWasCancelled];
                        if (!isCancelled)
                        {
                            [_transformView removeFromSuperview];
                            [_shadowView removeFromSuperview];
                        }
                        
                        _presentAnimation = isCancelled;
                        toViewController.view.alpha = isCancelled ? 0.0 : 1.0;
                        [transitionContext completeTransition:!isCancelled];
                    }];
                }];
            }];
        }];
    }
    else
    {
        [self updateContentSnapshot:fromViewController.view afterScreenUpdate:NO];
        
        [fromViewController.view removeFromSuperview];
        [containerView addSubview:toViewController.view];
        [containerView addSubview:_shadowView];
        [containerView addSubview:_transformView];
        
        _transformView.upperBackLayer.contents = (__bridge id)(self.contentImage.CGImage);
        _transformView.lowerLayer.contents = (__bridge id)(self.contentImage.CGImage);
        
        [self animateFlipBackLayerWithCompletionBlock:^{
            
            _transformView.upperBackLayer.opacity = 0.0;
            _transformView.upperFrontLayer.opacity = 1.0;
            
            [self animateFlipFrontLayerWithCompletionBlock:^{
                [self animateEaseInAnimationWithCompletionBlock:^{
                    
                    BOOL isCancelled = [transitionContext transitionWasCancelled];
                    if (!isCancelled)
                    {
                        [_transformView removeFromSuperview];
                        [_shadowView removeFromSuperview];
                        _transformView = nil;
                    }
                    _presentAnimation = !isCancelled;
                    [transitionContext completeTransition:!isCancelled];
                }];
            }];
        }];
    }
}

#pragma mark - Preparation
- (void)prepareLayersWithCompletionBlock:(void(^)(void))block
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:block];
    
    if (_presentAnimation)
    {
        _transformView.upperFrontLayer.transform = CATransform3DIdentity;
        _transformView.upperBackLayer.transform = CATransform3DMakeRotation(-M_PI_2, 1.0, 0.0, 0.0);
        _transformView.upperBackLayer.shadowCover.opacity = 0.5;
        _transformView.lowerLayer.transform = CATransform3DIdentity;
        _transformView.lowerLayer.shadowCover.opacity = 1.0;
        
        CATransform3D transform = _transformView.layer.transform;
        if (_style == MRFlipTransitionPresentingFromBottom)
        {
            transform = CATransform3DScale(transform, MRScaleFactor, MRScaleFactor, 1.0);
            transform = CATransform3DTranslate(transform, 0, CGRectGetHeight([UIScreen mainScreen].bounds), 0);
        }
        else
        {
            transform = CATransform3DScale(transform, MRInfinityFactor * MRScaleFactor, MRInfinityFactor * MRScaleFactor, 1.0);
            transform = CATransform3DTranslate(transform, 0, MRInfinityMerginY, 0);
        }
        _transformView.layer.transform = transform;
    }
    else
    {
        _transformView.upperFrontLayer.transform = CATransform3DMakeRotation(M_PI_2, 1.0, 0.0, 0.0);
        _transformView.upperBackLayer.transform = CATransform3DIdentity;
        _transformView.upperBackLayer.shadowCover.opacity = 0.0;
        _transformView.lowerLayer.transform = CATransform3DIdentity;
        _transformView.lowerLayer.shadowCover.opacity = 0.0;
        _transformView.layer.transform = CATransform3DIdentity;
    }
    
    [CATransaction commit];
}

#pragma mark - Animations
- (void)animateEaseInAnimationWithCompletionBlock:(void(^)(void))block
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:MRFlipEaseInDuration] forKey:kCATransactionAnimationDuration];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
    [CATransaction setCompletionBlock:block];
    
    BOOL fromBottom = _style == MRFlipTransitionPresentingFromBottom;
    
    CATransform3D transform = _transformView.layer.transform;
    if (fromBottom)
    {
        transform = CATransform3DTranslate(transform, 0, (CGRectGetHeight([UIScreen mainScreen].bounds) + MREaseInExtraDistance) * (_presentAnimation ? -1 : 1) , 0);
        
        CABasicAnimation *easeInAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
        easeInAnimation.fromValue = _presentAnimation ? @(CGRectGetHeight([UIScreen mainScreen].bounds)) : @(-MREaseInExtraDistance);
        easeInAnimation.toValue = _presentAnimation ? @(-MREaseInExtraDistance) : @(CGRectGetHeight([UIScreen mainScreen].bounds));
        easeInAnimation.fillMode = kCAFillModeForwards;
        easeInAnimation.removedOnCompletion = NO;
        [_transformView.layer addAnimation:easeInAnimation forKey:nil];
        _transformView.layer.transform = transform;
    }
    else
    {
        CGFloat factor = _presentAnimation ? 1 / MRInfinityFactor : MRInfinityFactor;
        CGFloat distance = _presentAnimation ? - MREaseInExtraDistance - MRInfinityMerginY * MRInfinityFactor :  (MREaseInExtraDistance + MRInfinityMerginY) * (1 / MRInfinityFactor);
        CATransform3D presentTransform = CATransform3DScale(transform, factor, factor, 1.0);
        presentTransform = CATransform3DTranslate(presentTransform, 0, distance, 0);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.fromValue = [NSValue valueWithCATransform3D:transform ];
        animation.toValue = [NSValue valueWithCATransform3D:presentTransform];
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        [_transformView.layer addAnimation:animation forKey:nil];
        _transformView.layer.transform = presentTransform;
    }
    
    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    shadowAnimation.fromValue = _presentAnimation ? @0.0 : @0.4;
    shadowAnimation.toValue = _presentAnimation ? @0.4 : @0.0;
    shadowAnimation.removedOnCompletion = NO;
    shadowAnimation.fillMode = kCAFillModeForwards;
    [_shadowView.layer addAnimation:shadowAnimation forKey:nil];
    _shadowView.layer.opacity = _presentAnimation ? 0.4 : 0.0;
    
    [CATransaction commit];
}

- (void)animateFlipFrontLayerWithCompletionBlock:(void(^)(void))block
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:MRFlipLayerDuration / 2.0] forKey:kCATransactionAnimationDuration];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:_presentAnimation ? kCAMediaTimingFunctionEaseIn : kCAMediaTimingFunctionEaseOut] forKey:kCATransactionAnimationTimingFunction];
    [CATransaction setCompletionBlock:block];
    
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    rotateAnimation.fromValue = _presentAnimation ? @0 : @(M_PI_2);
    rotateAnimation.toValue = _presentAnimation ? @(M_PI_2) : @0;
    rotateAnimation.fillMode = kCAFillModeForwards;
    rotateAnimation.removedOnCompletion = NO;
    [_transformView.upperFrontLayer addAnimation:rotateAnimation forKey:nil];
    _transformView.upperFrontLayer.transform = CATransform3DRotate(_transformView.upperFrontLayer.transform, M_PI_2 * (_presentAnimation ? 1 : -1), 1.0, 0, 0);
    
    CABasicAnimation *opacityLowerAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityLowerAnimation.fromValue = _presentAnimation ? @1 : @0.5;
    opacityLowerAnimation.toValue = _presentAnimation ? @0.5 : @1;
    opacityLowerAnimation.fillMode = kCAFillModeForwards;
    opacityLowerAnimation.removedOnCompletion = NO;
    [_transformView.lowerLayer.shadowCover addAnimation:opacityLowerAnimation forKey:nil];
    _transformView.lowerLayer.shadowCover.opacity = _presentAnimation ? 0.5 : 1.0;
    
    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    shadowAnimation.fromValue = _presentAnimation ? @0.4 : @0.7;
    shadowAnimation.toValue = _presentAnimation ? @0.7 : @0.4;
    shadowAnimation.removedOnCompletion = NO;
    shadowAnimation.fillMode = kCAFillModeForwards;
    [_shadowView.layer addAnimation:shadowAnimation forKey:nil];
    _shadowView.layer.opacity = _presentAnimation ? 0.7 : 0.4;
    
    [CATransaction commit];
}

- (void)animateFlipBackLayerWithCompletionBlock:(void(^)(void))block
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:MRFlipLayerDuration / 2.0] forKey:kCATransactionAnimationDuration];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:_presentAnimation ? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseIn] forKey:kCATransactionAnimationTimingFunction];
    [CATransaction setCompletionBlock:block];
    
    CATransform3D transform = _transformView.layer.transform;
    if (_presentAnimation)
    {
        transform = CATransform3DTranslate(transform, 0, MREaseInExtraDistance, 0);
        transform = CATransform3DScale(transform, 1 / MRScaleFactor, 1 / MRScaleFactor, 1.0);
    }
    else
    {
        transform = CATransform3DTranslate(transform, 0, - MREaseInExtraDistance, 0);
        transform = CATransform3DScale(transform, MRScaleFactor, MRScaleFactor, 1.0);
    }
    CABasicAnimation *transformLayerAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformLayerAnimation.fromValue = [NSValue valueWithCATransform3D:_transformView.layer.transform];
    transformLayerAnimation.toValue = [NSValue valueWithCATransform3D:transform];
    transformLayerAnimation.fillMode = kCAFillModeForwards;
    transformLayerAnimation.removedOnCompletion = NO;
    [_transformView.layer addAnimation:transformLayerAnimation forKey:nil];
    _transformView.layer.transform = transform;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    animation.fromValue = _presentAnimation ? @(-M_PI_2) : @0;
    animation.toValue = _presentAnimation ? @0 : @(-M_PI_2);
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [_transformView.upperBackLayer addAnimation:animation forKey:nil];
    _transformView.upperBackLayer.transform = CATransform3DRotate(_transformView.upperBackLayer.transform, M_PI_2 * (_presentAnimation ? 1 : -1), 1.0, 0, 0);
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = _presentAnimation ? @0.5 : @0.0;
    opacityAnimation.toValue = _presentAnimation ? @0.0 : @0.5;
    opacityAnimation.fillMode = kCAFillModeForwards;
    opacityAnimation.removedOnCompletion = NO;
    [_transformView.upperBackLayer.shadowCover addAnimation:opacityAnimation forKey:nil];
    [_transformView.lowerLayer.shadowCover addAnimation:opacityAnimation forKey:nil];
    _transformView.upperBackLayer.shadowCover.opacity = _presentAnimation ? 0.0 : 0.5;
    _transformView.lowerLayer.shadowCover.opacity = _presentAnimation ? 0.0 : 0.5;
    
    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    shadowAnimation.fromValue = _presentAnimation ? @0.7 : @1.0;
    shadowAnimation.toValue = _presentAnimation ? @1.0 : @0.7;
    shadowAnimation.removedOnCompletion = NO;
    shadowAnimation.fillMode = kCAFillModeForwards;
    [_shadowView.layer addAnimation:shadowAnimation forKey:nil];
    _shadowView.layer.opacity = _presentAnimation ? 1.0 : 0.7;
    
    [CATransaction commit];
}

@end
