//
//  SRFSurfboardPanel.m
//  Surfboard
//
//  Created by Moshe on 8/12/14.
//  Copyright (c) 2014 Moshe Berman. All rights reserved.
//

#import "SRFSurfboardPanelCell.h"

/**
 *  A class extension for SRFSurfboardPanelCell
 */

@interface SRFSurfboardPanelCell ()

/**
 *  The device image.
 */

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;

@end

@implementation SRFSurfboardPanelCell

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    self = [super awakeAfterUsingCoder:aDecoder];
    
    if (self)
    {   
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    //  Set the title text.
    self.textView.text = self.panel.text;
    self.labelTitle.text = self.panel.title;
    //self.textView.text = [self customizeText:self.panel.text];
    
    //  Add the image, tinted
    self.imageView.image = self.panel.image;
    
    if (self.imageView.image.renderingMode != UIImageRenderingModeAlwaysTemplate)
    {
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imageView.layer.borderWidth = 0.0f;
    }
    else
    {
        self.imageView.layer.borderWidth = 0.0;
    }
    
    //  Apply the title
    [self.actionButton setTitle:self.panel.buttonTitle forState:UIControlStateNormal];
    
    //  Hide the button on panels with no title.
    self.actionButton.hidden = (self.panel.buttonTitle == nil);
}

- (void)setPanel:(SRFSurfboardPanel *)panel
{
    _panel = panel;
    
    [self prepareForReuse];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.actionButton.layer.cornerRadius = 5.0f;
    self.actionButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    
    self.textView.textColor = self.tintColor;
    self.labelTitle.textColor = self.tintColor;
    
    if(self.panel.showsDevice == YES)
    {
        self.deviceImage.image = [self.deviceImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else
    {
        self.deviceImage.image = nil;
    }
    
    [self.actionButton setTitleColor:self.tintColor forState:UIControlStateNormal];
}

/**
 Customize the title text.
 */
- (NSString*) customizeText:(NSString*) text {
    NSArray* arrayStrings = [text componentsSeparatedByString:@"\n"];
    NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:text];
    NSInteger titleLength = [[arrayStrings firstObject] length];
    [attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Lato-Bold" size:17] range:NSMakeRange(0, titleLength)];
    
    return attributedTitle;
}

@end
