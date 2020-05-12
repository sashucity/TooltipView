//
//  TooltipView.swift
//  Sashucity
//
//  Created by Sasha Kozlov on 5/14/18.
//  Copyright © 2018 Sasha Kozlov, Inc. All rights reserved.
//

import Foundation
import UIKit

public enum TooltipElementPosition {
    case top
    case bottom
    case right
    case left
}

public class TooltipAppearance {
    //could be useful if there shouldn't be more than one tooltip on the screen at once
    static var visibleTooltipsCount = 0

    var shouldDismissOnTap = true

    struct Arrow {
        var width: CGFloat = 20
        var height: CGFloat = 20
        var position: TooltipElementPosition = .bottom
        ///distance between arrow and source view
        var offset: CGFloat = 6
    }

    struct Image {
        var width: CGFloat = 50
        var height: CGFloat = 50
        var position: TooltipElementPosition = .left
        var offset: CGFloat = 10
    }

    struct Style {
        var font: UIFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        var textColor: UIColor = .black
        var backgroundColor: UIColor = .white
        var cornerRadius: CGFloat = 10
        var shadowColor: UIColor = .black
        var shadowOpacity: Float = 0.8
        var shadowOffset: CGSize = CGSize(width: 0, height: 2)
        var textAlignment: NSTextAlignment = .left
        var textOffset: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        ///containerEdgeInsets is used to provide constants for constraints inside container view. optional
        var containerEdgeInsets: UIEdgeInsets?
        ///minContainerEdgeInsets is used to provide minimum offsets from container edges. optional
        var minContainerEdgeInsets: UIEdgeInsets?
        ///maxContainerEdgeInsets is used to provide maximum offsets from container edges. optional
        var maxContainerEdgeInsets: UIEdgeInsets?
    }

    struct Animation {
        var dismissTransform = CGAffineTransform.identity
        var showInitialTransform = CGAffineTransform.identity
        var showFinalTransform = CGAffineTransform.identity
        var springDamping: CGFloat = 0.7
        var springVelocity: CGFloat = 0.7
        var duration: TimeInterval = 0.3
        var dismissDuration: TimeInterval = 0.7
        var delay: TimeInterval = 1.2
    }

    var arrow = Arrow()
    var image = Image()
    var style = Style()
    var animation = Animation()
}

class TooltipView: UIView {
    /// can be used to move arrow by the source view
    private let offsetFromSourceView: CGFloat

    private let text: String
    private let image: UIImage?
    private let appearance: TooltipAppearance

    private var bubbleFrame = CGRect.zero
    private var imageView: UIImageView?

    private let sourceView: UIView
    private let containerView: UIView

    /// View that will be displayed above the tooltip, added so the view can follow the tooltip's animations.
    private let headerView: UIView?

    /// Reference to the header view's constraint kept for the dismiss animation.
    fileprivate var headerViewConstraint: NSLayoutConstraint?

    //Closure that will be called in any possible case after tooltip will get closed.
    var onDismiss: (() -> Void)?

    ///by default tooltip will appear from the center of the view side based on arrow direction
    init(sourceView: UIView,
         containerView: UIView,
         headerView: UIView? = nil,
         offsetFromSourceView: CGFloat = 0,
         text: String,
         image: UIImage? = nil,
         appearance: TooltipAppearance = TooltipAppearance()) {

        self.containerView = containerView
        self.sourceView = sourceView
        self.headerView = headerView
        self.text = text
        self.image = image
        self.appearance = appearance
        self.offsetFromSourceView = offsetFromSourceView

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        calculateConstraints()
    }

    required internal init?(coder aDecoder: NSCoder) {
        fatalError("initWithCoder is not supported by TooltipView class")
    }

    override func draw(_ rect: CGRect) {
        setupTooltipShape()
        positionImage()
        positionText()
    }

    private func calculateConstraints() {
        containerView.addSubview(self)

        let attributes = [NSAttributedString.Key.font: appearance.style.font]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        var height: CGFloat
        var width: CGFloat

        let arrowPosition = appearance.arrow.position
        let imagePosition = appearance.image.position
        let arrHeight = appearance.arrow.height

        //if image is on the left or on the right, text will layout in container which is based on image top and bottom anchors
        //if image is on the bottom or on the top, text will layout in container based on text size and image will be centered by this container
        switch imagePosition {
        case .left, .right:
            height = appearance.image.height + 2 * appearance.image.offset
            let textSize = attributedText.boundingRect(with: CGSize(width: 200, height: appearance.image.height + 50),
                                                       options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil).size
            width = appearance.image.width + appearance.image.offset * 2 + textSize.width + appearance.style.textOffset.left + appearance.style.textOffset.right

            width = (arrowPosition == .left || arrowPosition == .right) ? width + arrHeight : width
            height = (arrowPosition == .top || arrowPosition == .bottom) ? height + arrHeight : height

            heightAnchor.constraint(equalToConstant: height).isActive = true
        case .top, .bottom:
            width = appearance.image.width + 2 * appearance.image.offset
            let textSize = attributedText.boundingRect(with: CGSize(width: appearance.image.width, height: UIScreen.main.bounds.height),
                                                       options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil).size
            height = appearance.image.height + appearance.image.offset * 2 + textSize.height + appearance.style.textOffset.left + appearance.style.textOffset.right

            width = (arrowPosition == .left || arrowPosition == .right) ? width + arrHeight : width
            height = (arrowPosition == .top || arrowPosition == .bottom) ? height + arrHeight : height

            heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        }

        if let edgeInsets = appearance.style.containerEdgeInsets {
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets.left).isActive = true
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets.right).isActive = true
            topAnchor.constraint(equalTo: containerView.topAnchor, constant: edgeInsets.top).isActive = true
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -edgeInsets.bottom).isActive = true

            width = min(width, containerView.bounds.width - edgeInsets.left - edgeInsets.right)
        }

        if let minEdgeInsets = appearance.style.minContainerEdgeInsets {
            leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: minEdgeInsets.left).isActive = true
            trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: -minEdgeInsets.right).isActive = true
            topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: minEdgeInsets.top).isActive = true
            bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -minEdgeInsets.bottom).isActive = true

            width = min(width, containerView.bounds.width - minEdgeInsets.left - minEdgeInsets.right)
        }

        if let maxEdgeInsets = appearance.style.maxContainerEdgeInsets {
            leadingAnchor.constraint(lessThanOrEqualTo: containerView.leadingAnchor, constant: maxEdgeInsets.left).isActive = true
            trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor, constant: -maxEdgeInsets.right).isActive = true
            topAnchor.constraint(lessThanOrEqualTo: containerView.topAnchor, constant: maxEdgeInsets.top).isActive = true
            bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor, constant: -maxEdgeInsets.bottom).isActive = true

            width = min(width, containerView.bounds.width - maxEdgeInsets.left - maxEdgeInsets.right)
        }

        widthAnchor.constraint(equalToConstant: width).isActive = true

        switch arrowPosition {
        case .left:
            leadingAnchor.constraint(equalTo: sourceView.trailingAnchor, constant: appearance.arrow.offset).isActive = true
        case .right:
            trailingAnchor.constraint(equalTo: sourceView.leadingAnchor, constant: appearance.arrow.offset).isActive = true
        case .top:
            topAnchor.constraint(equalTo: sourceView.bottomAnchor, constant: appearance.arrow.offset).isActive = true
        case .bottom:
            bottomAnchor.constraint(equalTo: sourceView.topAnchor, constant: -appearance.arrow.offset).isActive = true
        }

        if let headerView = headerView {
            headerViewConstraint = topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8.0)
            headerViewConstraint?.isActive = true
        }
    }

    private func calculateBubbleFrame() {
        let arrowHeight = appearance.arrow.height

        switch appearance.arrow.position {
        case .top:
            bubbleFrame = CGRect(x: 0, y: arrowHeight, width: frame.width, height: frame.height - arrowHeight)
        case .bottom:
            bubbleFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - arrowHeight)
        case .right:
            bubbleFrame = CGRect(x: 0, y: 0, width: frame.width - arrowHeight, height: frame.height)
        case .left:
            bubbleFrame = CGRect(x: arrowHeight, y: 0, width: frame.width - arrowHeight, height: frame.height)
        }
    }

    private func setupTooltipShape() {
        let tooltipShape = CAShapeLayer()

        tooltipShape.path = createTooltipPath().cgPath
        tooltipShape.fillColor = appearance.style.backgroundColor.cgColor

        tooltipShape.shadowColor = appearance.style.shadowColor.cgColor
        tooltipShape.shadowOffset = appearance.style.shadowOffset
        tooltipShape.shadowOpacity = appearance.style.shadowOpacity

        layer.addSublayer(tooltipShape)
    }

    private func positionImage() {
        guard let image = image else { return }

        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.widthAnchor.constraint(lessThanOrEqualToConstant: appearance.image.width).isActive = true
        imageView.heightAnchor.constraint(lessThanOrEqualToConstant: appearance.image.height).isActive = true

        let offset = appearance.image.offset
        let arrowPos = appearance.arrow.position
        let arrowH = appearance.arrow.height

        switch appearance.image.position {
        case .left:
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: arrowPos == .left ? arrowH + offset : offset).isActive = true
            if arrowPos == .top {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: arrowH / 2).isActive = true
            } else if arrowPos == .bottom {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -arrowH / 2).isActive = true
            } else {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            }
        case .right:
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -offset).isActive = true
            if arrowPos == .top {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: arrowH / 2).isActive = true
            } else if arrowPos == .bottom {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -arrowH / 2).isActive = true
            } else {
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            }
        case .top:
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: offset + appearance.arrow.height).isActive = true
            if arrowPos == .left {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: arrowH / 2).isActive = true
            } else if arrowPos == .right {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -arrowH / 2).isActive = true
            } else {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            }
        case .bottom:
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset).isActive = true
            if arrowPos == .left {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: arrowH / 2).isActive = true
            } else if arrowPos == .right {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -arrowH / 2).isActive = true
            } else {
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            }
        }

        self.imageView = imageView
    }

    private func positionText() {
        let label = UILabel()
        label.font = appearance.style.font
        label.textColor = appearance.style.textColor
        label.textAlignment = appearance.style.textAlignment
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        let offset = appearance.style.textOffset
        addSubview(label)

        let arrowPos = appearance.arrow.position
        let arrowH = appearance.arrow.height
        guard let imageView = imageView else {
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: arrowPos == .right ? -offset.right - arrowH : -offset.right).isActive = true
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: arrowPos == .left ? arrowH + offset.left : offset.left).isActive = true
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: arrowPos == .bottom ? -offset.bottom - arrowH : -offset.bottom).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: arrowPos == .top ? offset.top + arrowH : offset.top).isActive = true
            return
        }

        switch appearance.image.position {
        case .left:
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -offset.right).isActive = true
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: offset.left).isActive = true
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset.bottom).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: offset.top).isActive = true
        case .right:
            label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -offset.right).isActive = true
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offset.left).isActive = true
            label.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
            label.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        case .top:
            label.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset.bottom).isActive = true
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: offset.top).isActive = true
        case .bottom:
            label.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -offset.bottom).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: offset.top).isActive = true
        }
    }

    @objc private func handleTap() {
        if appearance.shouldDismissOnTap {
            dismiss()
        }
    }
}

extension TooltipView {
    private func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return (CGFloat.pi * degrees) / 180
    }

    private func createTooltipPath() -> UIBezierPath {
        var origin: CGPoint

        calculateBubbleFrame()

        let arrowWidth = appearance.arrow.width
        let arrowHeight = appearance.arrow.height
        let radius = appearance.style.cornerRadius

        let relatedSourceFrame = containerView.convert(sourceView.frame, to: containerView)

        switch appearance.arrow.position {
        case .top:
            origin = CGPoint(x: relatedSourceFrame.origin.x + sourceView.bounds.width / 2 + offsetFromSourceView - frame.origin.x, y: 0)
            return pathForTopPosition(origin: origin, arrowWidth: arrowWidth, arrowHeight: arrowHeight, radius: radius)
        case .bottom:
            origin = CGPoint(x: relatedSourceFrame.origin.x + sourceView.bounds.width / 2 + offsetFromSourceView - frame.origin.x,
                             y: frame.height)
            return pathForBottomPosition(origin: origin, arrowWidth: arrowWidth, arrowHeight: arrowHeight, radius: radius)
        case .right:
            origin = CGPoint(x: frame.width, y: relatedSourceFrame.origin.y + sourceView.bounds.height / 2 + offsetFromSourceView - frame.origin.y)
            return pathForRightPosition(origin: origin, arrowWidth: arrowWidth, arrowHeight: arrowHeight, radius: radius)
        case .left:
            origin = CGPoint(x: 0, y: relatedSourceFrame.origin.y + sourceView.bounds.height / 2 + offsetFromSourceView - frame.origin.y)
            return pathForLeftPosition(origin: origin, arrowWidth: arrowWidth, arrowHeight: arrowHeight, radius: radius)
        }
    }

    private func pathForTopPosition(origin: CGPoint, arrowWidth: CGFloat, arrowHeight: CGFloat, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + arrowWidth / 2, y: origin.y + arrowHeight))
        path.addLine(to: CGPoint(x: bubbleFrame.width - radius, y: arrowHeight))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: arrowHeight + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 270),
                    endAngle: degreesToRadians(degrees: 0),
                    clockwise: true)
        path.addLine(to: CGPoint(x: bubbleFrame.width, y: arrowHeight + bubbleFrame.height - radius))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: arrowHeight + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 0),
                    endAngle: degreesToRadians(degrees: 90),
                    clockwise: true)
        path.addLine(to: CGPoint(x: radius, y: arrowHeight + bubbleFrame.height))
        path.addArc(withCenter: CGPoint(x: radius, y: arrowHeight + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 90),
                    endAngle: degreesToRadians(degrees: 180),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: arrowHeight + radius))
        path.addArc(withCenter: CGPoint(x: radius, y: arrowHeight + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 180),
                    endAngle: degreesToRadians(degrees: 270),
                    clockwise: true)
        path.addLine(to: CGPoint(x: origin.x - arrowWidth / 2, y: origin.y + arrowHeight))
        path.close()
        return path
    }

    private func pathForBottomPosition(origin: CGPoint, arrowWidth: CGFloat, arrowHeight: CGFloat, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()

        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + arrowWidth / 2, y: origin.y - arrowHeight))
        path.addLine(to: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + bubbleFrame.height))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 90),
                    endAngle: degreesToRadians(degrees: 0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: bubbleFrame.width, y: bubbleFrame.origin.y + radius))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 0),
                    endAngle: degreesToRadians(degrees: 270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: radius, y: bubbleFrame.origin.y))
        path.addArc(withCenter: CGPoint(x: radius, y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 270),
                    endAngle: degreesToRadians(degrees: 180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: bubbleFrame.origin.y + bubbleFrame.height - radius))
        path.addArc(withCenter: CGPoint(x: radius, y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 180),
                    endAngle: degreesToRadians(degrees: 90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: origin.x - arrowWidth / 2, y: origin.y - arrowHeight))
        path.close()
        return path
    }



    private func pathForRightPosition(origin: CGPoint, arrowWidth: CGFloat, arrowHeight: CGFloat, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x - arrowHeight, y: origin.y - arrowWidth / 2))
        path.addLine(to: CGPoint(x: bubbleFrame.width, y: bubbleFrame.origin.y + radius))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 0),
                    endAngle: degreesToRadians(degrees: 270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: radius, y: bubbleFrame.origin.y))
        path.addArc(withCenter: CGPoint(x: radius, y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 270),
                    endAngle: degreesToRadians(degrees: 180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: bubbleFrame.origin.y + bubbleFrame.height - radius))
        path.addArc(withCenter: CGPoint(x: radius, y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 180),
                    endAngle: degreesToRadians(degrees: 90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + bubbleFrame.height))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.width - radius, y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 90),
                    endAngle: degreesToRadians(degrees: 0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: origin.x - arrowHeight, y: origin.y + arrowWidth / 2))
        path.close()
        return path
    }

    private func pathForLeftPosition(origin: CGPoint, arrowWidth: CGFloat, arrowHeight: CGFloat, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + arrowHeight, y: origin.y - arrowWidth / 2))
        path.addLine(to: CGPoint(x: bubbleFrame.origin.x, y: bubbleFrame.origin.y + radius))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.origin.x + radius, y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 180),
                    endAngle: degreesToRadians(degrees: 270),
                    clockwise: true)
        path.addLine(to: CGPoint(x: bubbleFrame.origin.x + bubbleFrame.width - radius, y: bubbleFrame.origin.y))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.origin.x + bubbleFrame.width - radius,
                                        y: bubbleFrame.origin.y + radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 270),
                    endAngle: degreesToRadians(degrees: 0),
                    clockwise: true)
        path.addLine(to: CGPoint(x: bubbleFrame.origin.x + bubbleFrame.width, y: bubbleFrame.origin.y + bubbleFrame.height - radius))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.origin.x + bubbleFrame.width - radius,
                                        y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 0),
                    endAngle: degreesToRadians(degrees: 90),
                    clockwise: true)
        path.addLine(to: CGPoint(x: bubbleFrame.origin.x + radius, y: bubbleFrame.origin.y + bubbleFrame.height))
        path.addArc(withCenter: CGPoint(x: bubbleFrame.origin.x + radius,
                                        y: bubbleFrame.origin.y + bubbleFrame.height - radius),
                    radius: radius,
                    startAngle: degreesToRadians(degrees: 90),
                    endAngle: degreesToRadians(degrees: 180),
                    clockwise: true)
        path.addLine(to: CGPoint(x: origin.x + arrowHeight, y: origin.y + arrowWidth / 2))
        path.close()
        return path
    }
}

extension TooltipView {
    public func show(animated: Bool = true) {
        //Need to count shown tooltips
        TooltipAppearance.visibleTooltipsCount += 1

        let initialTransform = appearance.animation.showInitialTransform
        let finalTransform = appearance.animation.showFinalTransform
        let damping = appearance.animation.springDamping
        let velocity = appearance.animation.springVelocity

        transform = initialTransform
        alpha = 0
        containerView.layoutIfNeeded()

        let animation: () -> Void = {
            self.transform = finalTransform
            self.alpha = 1
            self.containerView.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: appearance.animation.duration,
                           delay: appearance.animation.delay,
                           usingSpringWithDamping: damping,
                           initialSpringVelocity: velocity,
                           options: [.curveEaseIn],
                           animations: {
                            animation()
            }) { _ in }
        } else {
            animation()
        }
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        //Need to count shown tooltips
        TooltipAppearance.visibleTooltipsCount -= 1

        headerViewConstraint?.isActive = false
        UIView.animate(withDuration: appearance.animation.dismissDuration,
                       delay: 0,
                       usingSpringWithDamping: appearance.animation.springDamping,
                       initialSpringVelocity: appearance.animation.springVelocity,
                       options: [.curveEaseOut],
                       animations: {
                        self.transform = self.appearance.animation.dismissTransform
                        self.alpha = 0
                        self.containerView.layoutIfNeeded()
        }, completion: { _ in
            completion?()
            self.removeFromSuperview()
            self.transform = CGAffineTransform.identity
            self.onDismiss?()
        })
    }
}
