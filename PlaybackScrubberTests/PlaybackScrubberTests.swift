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
}
