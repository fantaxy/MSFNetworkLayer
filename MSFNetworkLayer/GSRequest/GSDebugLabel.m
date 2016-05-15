//
//  GSDebugLabel.m
//  QQMSFContact
//
//  Created by Fanta Xu on 16/1/21.
//
//

#import "GSDebugLabel.h"
#import "UIView+Positioning.h"

#if !__has_feature(objc_arc)
#error  does not support Objective-C Automatic Reference Counting (ARC)
#endif

#define kSize CGSizeMake([[UIScreen mainScreen] bounds].size.width-24, 20)
#define kViewTag (30313766)

@implementation GSDebugLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width == 0 && frame.size.height == 0) {
        frame.size = kSize;
    }
    self = [super initWithFrame:frame];
    
    self.tag = kViewTag;
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    self.textAlignment = NSTextAlignmentLeft;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
    self.left = 12;
    self.top = 20;
    [self setFont:[UIFont fontWithName:@"Menlo" size:_scale_W(13)]];
    [self setTextColor:[UIColor whiteColor]];
    
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return kSize;
}

- (void)setText:(NSString *)text
{
    UIView *current = [[[UIApplication sharedApplication] keyWindow] viewWithTag:kViewTag];
    if (!current || current != self) {
        [current removeFromSuperview];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] addSubview:self];
    }
    if (self.prefixStr.length) {
        [super setText:[NSString stringWithFormat:@" %@ %@", self.prefixStr, text]];
    }
    else {
        [super setText:text];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:2];
}

@end
