//
//  AnotherViewController.m
//  FlipDemo
//
//  Created by mmt on 12/7/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//

#import "AnotherViewController.h"
#import "MRFlipTransition.h"

@interface AnotherViewController ()

@end

@implementation AnotherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    UIView *dismissView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    [self.view addSubview:dismissView];
    UISwipeGestureRecognizer *dismissGesture= [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(flyAway:)];
    dismissGesture.direction= UISwipeGestureRecognizerDirectionDown;
    [dismissView addGestureRecognizer:dismissGesture];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [(MRFlipTransition *)self.transitioningDelegate updateContentSnapshot:self.view afterScreenUpdate:YES];
}

- (void)flyAway:(id)sender
{
    [(MRFlipTransition *)self.transitioningDelegate dismissTo:MRFlipTransitionPresentingFromBottom completion:nil];
}


@end
