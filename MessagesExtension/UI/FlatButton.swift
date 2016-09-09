//
//  FlatButton.swift
//  GhostPics
//
//  Created by CRH on 9/9/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class FlatButton : UIButton {
    private var defaultEdgeInsets : UIEdgeInsets
    private var normalEdgeInsets : UIEdgeInsets
    private var highlightedEdgeInsets : UIEdgeInsets

    override init( frame : CGRect) {
        super.init(frame: frame)
        self.defaultEdgeInsets = self.titleEdgeInsets
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func buttonImageWithColor(color : UIColor, cornerRadius: CGFloat, shadowColor: UIColor, shadowInsets : UIEdgeInsets) -> UIImage {
        topImage = [self imageWithColor:color cornerRadius:cornerRadius];
        UIImage *bottomImage = [self imageWithColor:shadowColor cornerRadius:cornerRadius];
        CGFloat totalHeight = edgeSizeFromCornerRadius(cornerRadius) + shadowInsets.top + shadowInsets.bottom;
        CGFloat totalWidth = edgeSizeFromCornerRadius(cornerRadius) + shadowInsets.left + shadowInsets.right;
        CGFloat topWidth = edgeSizeFromCornerRadius(cornerRadius);
        CGFloat topHeight = edgeSizeFromCornerRadius(cornerRadius);
        CGRect topRect = CGRectMake(shadowInsets.left, shadowInsets.top, topWidth, topHeight);
        CGRect bottomRect = CGRectMake(0, 0, totalWidth, totalHeight);
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(totalWidth, totalHeight), NO, 0.0f);
        if (!CGRectEqualToRect(bottomRect, topRect)) {
        [bottomImage drawInRect:bottomRect];
        }
        [topImage drawInRect:topRect];
        UIImage *buttonImage = UIGraphicsGetImageFromCurrentImageContext();
        UIEdgeInsets resizeableInsets = UIEdgeInsetsMake(cornerRadius + shadowInsets.top,
        cornerRadius + shadowInsets.left,
        cornerRadius + shadowInsets.bottom,
        cornerRadius + shadowInsets.right);
        UIGraphicsEndImageContext();
        return [buttonImage resizableImageWithCapInsets:resizeableInsets];
    }

    func configureFlatButton(buttonColor : UIColor) {
        let normalBackgroundImage = UIImage.buttonImageWithColor(buttonColor)
        cornerRadius:self.cornerRadius
        shadowColor:self.shadowColor
        shadowInsets:UIEdgeInsetsMake(0, 0, self.shadowHeight, 0)];

        UIColor *highlightedColor = self.highlightedColor == nil ? self.buttonColor : self.highlightedColor;
        UIImage *highlightedBackgroundImage = [UIImage buttonImageWithColor:highlightedColor
        cornerRadius:self.cornerRadius
        shadowColor:[UIColor clearColor]
        shadowInsets:UIEdgeInsetsMake(self.shadowHeight, 0, 0, 0)];

        if (self.disabledColor) {
        UIColor *disabledShadowColor = self.disabledShadowColor == nil ? self.shadowColor : self.disabledShadowColor;
        UIImage *disabledBackgroundImage = [UIImage buttonImageWithColor:self.disabledColor
        cornerRadius:self.cornerRadius
        shadowColor:disabledShadowColor
        shadowInsets:UIEdgeInsetsMake(0, 0, self.shadowHeight, 0)];
        [self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
        }

        [self setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
    }
}

//    func setTitleEdgeInsets(titleEdgeInsets : UIEdgeInsets) {
//        super.setTitleEdgeInsets(titleEdgeInsets)
//        self.defaultEdgeInsets = titleEdgeInsets;
//        [self setShadowHeight:self.shadowHeight];
//        }
//
//        - (void) setHighlighted:(BOOL)highlighted {
//            UIEdgeInsets insets = highlighted ? self.highlightedEdgeInsets : self.normalEdgeInsets;
//            [super setTitleEdgeInsets:insets];
//            [super setHighlighted:highlighted];
//            }
//
//            - (void) setCornerRadius:(CGFloat)cornerRadius {
//                _cornerRadius = cornerRadius;
//                [self configureFlatButton];
//                }
//
//                - (void) setButtonColor:(UIColor *)buttonColor {
//                    _buttonColor = buttonColor;
//                    [self configureFlatButton];
//                    }
//
//                    - (void) setShadowColor:(UIColor *)shadowColor {
//                        _shadowColor = shadowColor;
//                        [self configureFlatButton];
//                        }
//
//                        - (void) setHighlightedColor:(UIColor *)highlightedColor {
//                            _highlightedColor = highlightedColor;
//                            [self configureFlatButton];
//                            }
//
//                            - (void) setDisabledColor:(UIColor *)disabledColor {
//                                _disabledColor = disabledColor;
//                                [self configureFlatButton];
//                                }
//
//                                - (void) setDisabledShadowColor:(UIColor *)disabledShadowColor {
//                                    _disabledShadowColor = disabledShadowColor;
//                                    [self configureFlatButton];
//                                    }
//
//                                    - (void) setShadowHeight:(CGFloat)shadowHeight {
//                                        _shadowHeight = shadowHeight;
//                                        UIEdgeInsets insets = self.defaultEdgeInsets;
//                                        insets.top += shadowHeight;
//                                        self.highlightedEdgeInsets = insets;
//                                        insets.top -= shadowHeight * 2.0f;
//                                        self.normalEdgeInsets = insets;
//                                        [super setTitleEdgeInsets:insets];
//                                        [self configureFlatButton];
//                                        }

