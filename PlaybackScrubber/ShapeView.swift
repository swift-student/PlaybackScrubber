//
//  ShapeView.swift
//  PlaybackScrubber
//
//  Created by Shawn Gee on 5/2/22.
//

import UIKit

/// A `UIView` that uses a `CAShapeLayer` as it's layer.
class ShapeView: UIView {
	override class var layerClass: AnyClass { CAShapeLayer.self }
	var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
}
