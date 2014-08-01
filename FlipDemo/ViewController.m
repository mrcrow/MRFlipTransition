//
//  ViewController.m
//  FlipDemo
//
//  Created by mmt on 12/7/14.
//  Copyright (c) 2014 Michael WU. All rights reserved.
//

#import "ViewController.h"
#import "AnotherViewController.h"
#import "MRFlipTransition.h"

@interface ViewController ()
@property (nonatomic, strong)   MRFlipTransition    *animator;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.animator = [[MRFlipTransition alloc] initWithPresentingViewController:self];
    
    UIButton *launchButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 210, 60)];
    launchButton.backgroundColor = [UIColor blackColor];
    [launchButton setTitle:@"Present" forState:UIControlStateNormal];
    [launchButton addTarget:self action:@selector(showAnotherController:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:launchButton];
}

- (void)showAnotherController:(id)sender
{
    AnotherViewController *controller = [[AnotherViewController alloc] initWithNibName:nil bundle:nil];
    [self.animator present:controller from:MRFlipTransitionPresentingFromInfinityAway completion:nil];
}

@end
