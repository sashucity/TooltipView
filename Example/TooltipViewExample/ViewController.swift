//
//  ViewController.swift
//  TooltipViewExample
//
//  Created by Sashucity on 12.05.2020.
//  Copyright © 2020 Sashucity. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet private weak var button1: UIButton!
    @IBOutlet private weak var button2: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func tapOnFirst() {
        let appearance = CustomAppearance()
        appearance.arrow.position = .left
        appearance.arrow.width = 10
        appearance.arrow.height = 10
        appearance.arrow.offset = 20
        appearance.style.textOffset.left = 20
        appearance.style.minContainerEdgeInsets = UIEdgeInsets(top: 90, left: 30, bottom: 30, right: 36)
        appearance.animation.showInitialTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        appearance.animation.dismissTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        appearance.animation.delay = 0.0

        let tooltip1 = TooltipView(sourceView: button1, containerView: view, text: "This is a tooltip with text", appearance: appearance)
        tooltip1.show()
    }

    @IBAction func tapOnSecond() {
        let appearance = CustomAppearance()
        appearance.image.position = .left
        appearance.image.offset = 15.0
        appearance.arrow.position = .bottom
        appearance.arrow.width = 15
        appearance.arrow.height = 10
        appearance.arrow.offset = 15
        appearance.style.maxContainerEdgeInsets = UIEdgeInsets(top: CGFloat.greatestFiniteMagnitude, left: 36, bottom: CGFloat.greatestFiniteMagnitude, right: 36)

        appearance.style.textOffset = UIEdgeInsets(top: -20, left: 10, bottom: 10, right: 10)
        appearance.animation.dismissTransform = CGAffineTransform(translationX: 0, y: 100)
        appearance.animation.showInitialTransform = CGAffineTransform(translationX: 0, y: 100)
        appearance.animation.duration = 0.3
        appearance.animation.delay = 0.1

        let tooltip2 = TooltipView(sourceView: button2, containerView: view, offsetFromSourceView: 0, text: "That is a tooltip with text and image", image: #imageLiteral(resourceName: "meteorology.png"), appearance: appearance)
        tooltip2.show()
    }

}

