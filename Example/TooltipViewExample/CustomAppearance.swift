//
//  CustomAppearance.swift
//  TooltipViewExample
//
//  Created by Sashucity on 12.05.2020.
//  Copyright © 2020 Sashucity. All rights reserved.
//

import UIKit

///this class is used to specify consistent appearance for all tooltips in this example project
class CustomAppearance: TooltipAppearance {
    override init() {
        super.init()

        style.font = UIFont.systemFont(ofSize: 14)
        style.textColor = .darkGray
        style.shadowColor = UIColor.black.withAlphaComponent(0.8)
        style.shadowOpacity = 0.2
        style.shadowOffset = CGSize(width: 0, height: 1)
        style.backgroundColor = .white
        style.cornerRadius = 5
        shouldDismissOnTap = true
    }
}
