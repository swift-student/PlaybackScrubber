//
//  Extensions.swift
//  PlaybackScrubber
//
//  Created by Shawn Gee on 5/1/22.
//

import UIKit

extension CGRect {
	static let minTouchTargetSize = CGSize(width: 44, height: 44) // per Apple's HIG
	
	/// Returns the smallest rect encompassing this rect that is of the minimum touch target size or larger.
	var touchTarget: CGRect {
		return self.insetBy(dx: width >= Self.minTouchTargetSize.width ? 0 : -(Self.minTouchTargetSize.width - width) / 2,
							dy: height >= Self.minTouchTargetSize.height ? 0 : -(Self.minTouchTargetSize.height - height) / 2)
	}
}
