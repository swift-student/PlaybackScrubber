//
//  ExtensionTests.swift
//  PlaybackScrubberTests
//
//  Created by Shawn Gee on 5/1/22.
//

import XCTest
@testable import PlaybackScrubber

class ExtensionTests: XCTestCase {

	func testTouchTarget_WhenRectIsSmallerThanMinTouchTargetSize_ExpandsTo44x44() {
		let rect = CGRect(x: 100,
						  y: 100,
						  width: 20,
						  height: 20)
		let expectedTouchTarget = CGRect(x: 88,
										 y: 88,
										 width: 44,
										 height: 44)
		
		XCTAssertEqual(rect.touchTarget, expectedTouchTarget)
	}
	
	func testTouchTarget_WhenOnlyWidthIsSmallerThanMinTouchTargetSize_OnlyExpandsWidth() {
		let rect = CGRect(x: 100,
						  y: 100,
						  width: 20,
						  height: 50)
		let expectedTouchTarget = CGRect(x: 88,
										 y: 100,
										 width: 44,
										 height: 50)
		
		XCTAssertEqual(rect.touchTarget, expectedTouchTarget)
	}
	
	func testTouchTarget_WhenOnlyHeightIsSmallerThanMinTouchTargetSize_OnlyExpandsHeight() {
		let rect = CGRect(x: 100,
						  y: 100,
						  width: 50,
						  height: 20)
		let expectedTouchTarget = CGRect(x: 100,
										 y: 88,
										 width: 50,
										 height: 44)
		
		XCTAssertEqual(rect.touchTarget, expectedTouchTarget)
	}
	
	func testTouchTarget_WhenRectIsBiggerThanMinTouchTargetSize_ReturnsRect() {
		let rect = CGRect(x: 100,
						  y: 100,
						  width: 50,
						  height: 50)
		
		XCTAssertEqual(rect.touchTarget, rect)
	}
}
