//
//  ViewController.swift
//  PlaybackScrubber
//
//  Created by Shawn Gee on 4/29/22.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

	let scrubber = PlaybackScrubber()
	var displayLink: CADisplayLink?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		scrubber.duration = 100
		scrubber.sectionMarkers = [
			PlaybackScrubber.SectionMarker(time: 30.3),
			PlaybackScrubber.SectionMarker(time: 50.4),
			PlaybackScrubber.SectionMarker(time: 60.5),
		]
		displayLink = CADisplayLink(target: self, selector: #selector(update))
		displayLink?.add(to: .current, forMode: .common)
		
		view.addSubview(scrubber)
		scrubber.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			scrubber.widthAnchor.constraint(equalToConstant: 400),
			scrubber.heightAnchor.constraint(equalToConstant: 40),
			scrubber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			scrubber.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}
	
	private var lastUpdateTime: CFTimeInterval?
	
	/// Simulates playing media by moving the playhead by the amount of time elapsed since the last call.
	@objc
	func update() {
		let updateTime = CACurrentMediaTime()
		if let lastUpdateTime = lastUpdateTime {
			scrubber.currentTime += updateTime - lastUpdateTime
		}
		lastUpdateTime = updateTime
	}
}

// MARK: - SwiftUI Previews

struct ViewWrapper: UIViewRepresentable {
	
	func makeUIView(context: Context) -> some UIView {
		ViewController().view
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) { }
}

struct ViewWrapper_Previews: PreviewProvider {
	static var previews: some View {
		ViewWrapper().previewLayout(.fixed(width: 500, height: 500))
	}
}
