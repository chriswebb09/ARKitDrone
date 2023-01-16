//
//  UIFont+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/16/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

// https://stackoverflow.com/questions/48858930/set-specific-font-weight-for-uilabel-in-swift

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let newDescriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }
}

