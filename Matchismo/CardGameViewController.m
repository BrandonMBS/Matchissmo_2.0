//
//  CardGameViewController.m
//  Matchismo
//
//  Created by Martin Mandl on 02.11.13.
//  Copyright (c) 2013 m2m server software gmbh. All rights reserved.
//

#import "CardGameViewController.h"
#import "CardMatchingGame.h"
#import "PlayingCardView.h"
#import "PlayingCard.h"
#import "Grid.h"

@interface CardGameViewController ()

@property (nonatomic, strong) CardMatchingGame *game;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIView *gridView;
@property (strong, nonatomic) NSMutableArray *cardViews;
@property (strong, nonatomic) Grid *grid;
@property (weak, nonatomic) IBOutlet UIButton *addCardsButton;


@end

@implementation CardGameViewController


- (Grid *)grid
{
    if (!_grid){
        _grid = [[Grid alloc] init];
        _grid.cellAspectRatio = self.maxCardSize.width / self.maxCardSize.height;
        _grid.minimumNumberOfCells = self.numberOfStartingCards;
        _grid.maxCellWidth = self.maxCardSize.width;
        _grid.maxCellHeight = self.maxCardSize.height;
        _grid.size = self.gridView.frame.size;
    }
    return _grid;
}
- (CardMatchingGame *)game
{
    if (!_game) {
      _game = [[CardMatchingGame alloc] initWithCardCount:self.numberOfStartingCards
                                                       usingDeck:[self createDeck]];
    }
    return _game;
}

-(NSMutableArray *)cardViews
{
    if (!_cardViews) _cardViews = [NSMutableArray arrayWithCapacity:self.numberOfStartingCards];
    return _cardViews;
}

- (Deck *)createDeck // abstract
{
    return nil;
}
    
- (IBAction)touchDealButton:(UIButton *)sender {
    self.game = nil;
    for (UIView *subView in self.cardViews){
        [subView removeFromSuperview];
    }
    self.cardViews = nil;
    self.grid = nil;
    self.addCardsButton.enabled = YES;
    self.addCardsButton.alpha = 1.0;
    [self updateUI];
}

- (IBAction)touchAddCardsButton:(UIButton *)sender {
    for (int i = 0; i < sender.tag; i++) {
        [self.game drawNewCard];
    }
    if (self.game.deckIsEmpty){
        sender.enabled = NO;
        sender.alpha = 0.5;
    }
    [self updateUI];
}

#define CARDSPACINGINPERCENT 0.08

- (void)updateUI
{
    for (NSUInteger cardIndex = 0; cardIndex < self.game.numberOfDealtCards; cardIndex++){
        Card *card = [self.game cardAtIndex:cardIndex];
        NSUInteger viewIndex = [self.cardViews indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UIView class]]){
                if (((UIView*)obj).tag == cardIndex) return YES;
            }
            return NO;
        }];
        
        UIView *cardView;
        if (viewIndex == NSNotFound){
            if (!card.matched) {
                
                cardView = [self createViewForCard:card];
                cardView.tag = cardIndex;
                cardView.frame = CGRectMake(self.gridView.bounds.size.width, self.gridView.bounds.size.height, self.grid.cellSize.width, self.grid.cellSize.height);
                
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchCard:)];
                [cardView addGestureRecognizer:tap];
                [self.cardViews addObject:cardView];
                viewIndex = [self.cardViews indexOfObject:cardView];
                [self.gridView addSubview:cardView];
            }
        } else {
            cardView = self.cardViews[viewIndex];
            if (!card.matched){
                [self updateView:cardView forCard:card];
            } else {
                [cardView removeFromSuperview];
                [self.cardViews removeObject:cardView];
                if (self.removeMatchingCards){
                    [self.cardViews removeObject:cardView];
                    [UIView animateWithDuration:1.0 animations:^ {cardView.frame = CGRectMake(0.0, self.gridView.bounds.size.height, self.grid.cellSize.width, self.grid.cellSize.height);
                    } completion:^(BOOL finished) { [cardView removeFromSuperview];
                    }];
                } else {
                    cardView.alpha = card.matched ? 0.6 : 1.0;
                }
            }
        }
    }
    self.grid.minimumNumberOfCells = [self.cardViews count];
    
    NSUInteger changedViews = 0;
    for (NSUInteger viewIndex = 0; viewIndex < [self.cardViews count]; viewIndex++) {
        CGRect frame = [self.grid frameOfCellAtRow:viewIndex / self.grid.columnCount inColumn:viewIndex % self.grid.columnCount];
        frame = CGRectInset(frame, frame.size.width * CARDSPACINGINPERCENT, frame.size.height * CARDSPACINGINPERCENT);
        UIView *cardView = (UIView *)self.cardViews[viewIndex];
        if (![self frame:frame equalToFrame:cardView.frame])
        {
            [UIView animateWithDuration:0.5 delay:1.5 * changedViews++ / [self.cardViews count] options:UIViewAnimationOptionCurveEaseOut animations:^{cardView.frame = frame;} completion:NULL];
        }
    }
    
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", self.game.score];
    //self.gameResult.score = self.game.score;
}

#define FRAMEROUNDINGERROR 0.01

-(BOOL)frame:(CGRect)frame1 equalToFrame:(CGRect)frame2
{
    if (fabs(frame1.size.width - frame2.size.width) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.size.height - frame2.size.height) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.x - frame2.origin.x) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.y - frame2.origin.y) > FRAMEROUNDINGERROR) return NO;
    return YES;
}

- (NSAttributedString *)titleForCard:(Card *)card
{
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:card.chosen ? card.contents : @""];
    return title;
}

- (UIImage *)backgroundImageForCard:(Card *)card
{
    return [UIImage imageNamed:card.chosen ? @"cardfront" : @"cardback"];
}

-(UIView *)createViewForCard:(Card *)card
{
    UIView *view = [[UIView alloc] init];
    [self updateView:view forCard:card];
    return view;
}

- (void)updateView: (UIView *)view forCard:(Card *)card
{
    view.backgroundColor = [UIColor blueColor];
}

- (void)touchCard:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded){
        Card *card = [self.game cardAtIndex:gesture.view.tag];
        if (!card.matched)
        {
            [UIView transitionWithView:gesture.view duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{card.chosen = !card.chosen;
                [self updateView:gesture.view forCard:card];
            } completion:^(BOOL finished) {
                card.chosen = !card.chosen;
                [self.game chooseCardAtIndex:gesture.view.tag];
                [self updateUI];
            }];
        }
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.grid.size = self.gridView.bounds.size;
    [self updateUI];
}


@end
