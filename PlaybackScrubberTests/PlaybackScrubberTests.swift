//
//  PlaybackScrubberTests.swift
//  PlaybackScrubberTests
//
//  Created by Shawn Gee on 4/29/22.
//

import XCTest
@testable import PlaybackScrubber

class PlaybackScrubberTests: XCTestCase {

	let playbackScrubber = PlaybackScrubber()
	
    func testPlaybackScrubber_WhenInitialized_HasExpectedDefaults() {
		XCTAssertEqual(playbackScrubber.duration, 1)
		XCTAssertEqual(playbackScrubber.currentTime, 0)
    }

	func testPlaybackScrubber_WhenSettingCurrentTimeToNegativeValue_CurrentTimeIsZero() {
		playbackScrubber.currentTime = -100
		XCTAssertEqual(playbackScrubber.currentTime, 0)
	}
	
	func testPlaybackScrubber_WhenSettingCurrentTimeToValueLargerThanDuration_CurrentTimeIsDuration() {
		playbackScrubber.duration = 100
		playbackScrubber.currentTime = 200
		XCTAssertEqual(playbackScrubber.currentTime, 100)
	}
	
	func testPlaybackScrubber_WhenSettingDurationToValueLessThanCurrentTime_CurrentTimeIsDuration() {
		playbackScrubber.duration = 400
		playbackScrubber.currentTime = 200
		playbackScrubber.duration = 100
		XCTAssertEqual(playbackScrubber.currentTime, 100)
	}
	
	func testPlaybackScrubber_SettingCurrentTimeWhileScrubbing_DoesNotChangeCurrentTIme() {
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 10, y: 10))
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		
		playbackScrubber.currentTime = 1
		
		XCTAssertEqual(playbackScrubber.currentTime, 0)
	}
	
	// MARK: - Delegate Tests
	
	func testPlaybackScrubber_WhenTouchesBegin_CallsDidBeginScrubbingOnDelegate() {
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 10, y: 10))
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		
		XCTAssertEqual(delegate.didBeginScrubbingTimes, [0])
		XCTAssertTrue(delegate.didScrubToTimes.isEmpty)
		XCTAssertTrue(delegate.didEndScrubbingTimes.isEmpty)
		XCTAssertEqual(delegate.didBeginScrubbingTimes[0], playbackScrubber.currentTime)
	}
	
	func testPlaybackScrubber_WhenTouchesMove_CallsDidScrubOnDelegate() {
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 10, y: 10))
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		
		touch.location.x += 5
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		
		XCTAssertEqual(delegate.didBeginScrubbingTimes.count, 1)
		XCTAssertEqual(delegate.didScrubToTimes.count, 1)
		XCTAssertTrue(delegate.didScrubToTimes[0] > 0)
		XCTAssertTrue(delegate.didEndScrubbingTimes.isEmpty)
		XCTAssertEqual(delegate.didScrubToTimes[0], playbackScrubber.currentTime)
	}
	
	func testPlaybackScrubber_WhenTouchesEnd_CallsDidEndScrubbingOnDelegate() {
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 10, y: 10))
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		
		playbackScrubber.touchesEnded(Set([touch]), with: nil)
		
		XCTAssertEqual(delegate.didBeginScrubbingTimes.count, 1)
		XCTAssertTrue(delegate.didScrubToTimes.isEmpty)
		XCTAssertEqual(delegate.didEndScrubbingTimes, [0]) // Should not have changed the current time
		XCTAssertEqual(delegate.didEndScrubbingTimes[0], playbackScrubber.currentTime)
	}
	
	func testPlaybackScrubber_WhenTouchesAreCancelled_CallsDidEndScrubbingOnDelegateWithUnchangedTime() {
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 10, y: 10))
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		touch.location.x += 5
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		
		playbackScrubber.touchesCancelled(Set([touch]), with: nil)
		
		XCTAssertEqual(delegate.didBeginScrubbingTimes.count, 1)
		XCTAssertEqual(delegate.didScrubToTimes.count, 1)
		XCTAssertEqual(delegate.didEndScrubbingTimes, [0])
		XCTAssertEqual(delegate.didEndScrubbingTimes[0], playbackScrubber.currentTime)
	}
	
	func testPlaybackScrubber_WhenAllowsScrubbingFromAnyTouchLocation_DraggingInitiatesScrub() {
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 100, y: 10)) // Touch is NOT on playhead
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		touch.location.x += PlaybackScrubber.InteractionState.minXDistanceToInitiateScrub - 1 // Just short of initiating scrub
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		
		XCTAssertTrue(delegate.didBeginScrubbingTimes.isEmpty)
		
		touch.location.x += 1 // Now at min distance
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		playbackScrubber.touchesEnded(Set([touch]), with: nil)
		
		XCTAssertEqual(delegate.didBeginScrubbingTimes, [0])
		XCTAssertEqual(delegate.didScrubToTimes.count, 1)
		XCTAssertTrue(delegate.didScrubToTimes[0] > 0)
		XCTAssertEqual(delegate.didScrubToTimes[0], playbackScrubber.currentTime)
		XCTAssertEqual(delegate.didEndScrubbingTimes.count, 1)
	}
	
	func testPlaybackScrubber_WhenDoesNotAllowScrubbingFromAnyTouchLocation_DraggingDoesNotInitiateScrub() {
		playbackScrubber.allowScrubbingFromAnyTouchLocation = false
		let delegate = MockPlaybackScrubberDelegate()
		playbackScrubber.delegate = delegate
		playbackScrubber.frame = .init(x: 0, y: 0, width: 400, height: 40)
		playbackScrubber.layoutSubviews()
		
		let touch = MockTouch(location: CGPoint(x: 300, y: 10)) // Touch is NOT on playhead
		playbackScrubber.touchesBegan(Set([touch]), with: nil)
		touch.location.x += 100
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		touch.location.x -= 400
		playbackScrubber.touchesMoved(Set([touch]), with: nil)
		playbackScrubber.touchesEnded(Set([touch]), with: nil)
		
		XCTAssertTrue(delegate.didBeginScrubbingTimes.isEmpty)
		XCTAssertTrue(delegate.didScrubToTimes.isEmpty)
		XCTAssertTrue(delegate.didEndScrubbingTimes.isEmpty)
	}
}

class MockPlaybackScrubberDelegate: PlaybackScrubberDelegate {
	var didBeginScrubbingTimes: [TimeInterval] = []
	var didScrubToTimes: [TimeInterval] = []
	var didEndScrubbingTimes: [TimeInterval] = []
	
	func scrubber(_ playbackScrubber: PlaybackScrubber, didBeginScrubbingAtTime time: TimeInterval) {
		didBeginScrubbingTimes.append(time)
	}
	
	func scrubber(_ playbackScrubber: PlaybackScrubber, didScrubToTime time: TimeInterval) {
		didScrubToTimes.append(time)
	}
	
	func scrubber(_ playbackScrubber: PlaybackScrubber, didEndScrubbingAtTime time: TimeInterval) {
		didEndScrubbingTimes.append(time)
	}
}

class MockTouch: UITouch {
	var location: CGPoint = .zero
	
	override func location(in view: UIView?) -> CGPoint {
		location
	}
	
	convenience init(location: CGPoint) {
		self.init()
		self.location = location
	}
}
