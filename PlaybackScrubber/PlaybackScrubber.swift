//
//  PlaybackScrubber.swift
//  PlaybackScrubber
//
//  Created by Shawn Gee on 4/30/22.
//

import UIKit

class PlaybackScrubber: UIControl {
	struct SectionMarker {
		var time: TimeInterval
		var title: String?
		var description: String?
	}
	// MARK: - Public Properties
	
	/// The overall duration of the media this scrubber represents in seconds.
	/// The default value of this property is 1.0
	public var duration: TimeInterval = 1.0 {
		didSet {
			// Clamp playhead position within new duration
			playheadPosition = playheadPosition
			setNeedsLayout()
		}
	}
	
	/// The current playback time of the media in seconds.
	/// This value is always clamped to the range of `0...duration`.
	/// The default value of this property is 0.0.
	public var currentTime: TimeInterval {
		set {
			switch interactionState {
			case .scrubbing:
				// We don't want to allow setting the playhead position while the user is actively scrubbing.
				return
			case .none:
				break
			}
			playheadPosition = newValue
		}
		
		get { playheadPosition }
	}
	
	public var sectionMarkers: [SectionMarker] = [] {
		didSet {
			updateTrackTickMarks()
			track.setNeedsLayout()
		}
	}
	
	public var trackHeight: CGFloat = Layout.defaultTrackHeight
	public var playheadSize: CGSize = Layout.defaultPlayheadSize {
		didSet {
			updateTrackInset()
			track.setNeedsDisplay()
		}
	}
	
	// MARK: - Private Properties
	
	/// The location of the playhead in seconds.
	private var playheadPosition: TimeInterval {
		set { _clampedPlayheadPosition = min(duration, max(0, newValue)) }
		get { _clampedPlayheadPosition }
	}
	
	/// Do not set this value directly, instead use `playheadPosition` which clamps new values based on the current duration.
	private var _clampedPlayheadPosition: TimeInterval = 0 {
		didSet {
			setNeedsLayout()
		}
	}
	
	/// The playhead position as a percentage of the overall duration.
	private var playheadProgress: Double {
		guard duration != 0 else { return 0 } // Avoid dividing by zero
		return playheadPosition / duration
	}
	
	private enum Layout {
		static let defaultTrackHeight: CGFloat = 6
		static let defaultPlayheadSize = CGSize(width: 14, height: 14)
	}
	
	private let track = Track()
	private let playhead = Playhead()
	
	// MARK: - Init
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	func commonInit() {
		addSubview(track)
		track.translatesAutoresizingMaskIntoConstraints = false
		updateTrackInset()
		
		addSubview(playhead)
		playhead.translatesAutoresizingMaskIntoConstraints = false
	}
	
	override func layoutSubviews() {
		// Center the track vertically
		track.frame = CGRect(x: 0,
							 y: (frame.height - trackHeight) / 2,
							 width: frame.width,
							 height: trackHeight)
		
		track.progress = playheadProgress
		updateTrackTickMarks()
		track.setNeedsLayout()
		
		// Center playhead vertically, position x based on progress
		playhead.frame = CGRect(x: (frame.width - playheadSize.width) * playheadProgress,
								y: (frame.height - playheadSize.height) / 2,
								width: playheadSize.width,
								height: playheadSize.height)
	}
	
	private func updateTrackTickMarks() {
		guard duration != 0 else { return } // Avoid dividing by zero
		track.tickMarks = sectionMarkers.map {
			Track.TickMark(location: $0.time / duration, style: .occlusion)
		}
	}
	
	private func updateTrackInset() {
		track.insetDistance = playheadSize.width / 2
	}
	
	// MARK: - Touch Handling
	
	enum InteractionState {
		case none
		case scrubbing(initialPlayheadPosition: TimeInterval)
	}
	
	private var interactionState: InteractionState = .none
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let touchLocation = touch.location(in: self)
		// See if the touch is within the playhead with some margin
		// TODO: Calculate this outset
		guard playhead.frame.insetBy(dx: -20, dy: -20).contains(touchLocation) else { return }

		interactionState = .scrubbing(initialPlayheadPosition: playheadPosition)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let touchLocation = touch.location(in: self)
		
		switch interactionState {
		case .none:
			// Nothing to do, the user hasn't initiated a scrub.
			return
		case .scrubbing:
			playheadPosition = (touchLocation.x - track.insetDistance) / track.usableWidth * duration
		}
		
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		interactionState = .none
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if case .scrubbing(let initialPlayheadPosition) = interactionState {
			playheadPosition = initialPlayheadPosition
		}
		interactionState = .none
	}
	
}

// MARK: - Track

extension PlaybackScrubber {
	class Track: UIView {
		
		/// The portion of the track at either end that is not usable due to the width of the playhead.
		var insetDistance: CGFloat = 0
		
		var usableWidth: CGFloat { bounds.width - insetDistance * 2 }
		
		/// The percentage of progress to indicate visually via the `elapsedTintColor`.
		/// Must be in the range of 0...1
		var progress: Double = 0.5
		
		/// The color of the portion of the track that represents the elapsed time.
		var elapsedTintColor: UIColor = .systemGreen {
			didSet {
				elapsedLayer.fillColor = elapsedTintColor.cgColor
			}
		}
		
		/// The color of the portion of the track that represents the remaining time.
		var remainingTintColor: UIColor = UIColor(white: 0.7, alpha: 0.5) {
			didSet {
				baseLayer.fillColor = remainingTintColor.cgColor
			}
		}
		
		var tickMarks: [TickMark] = []
		
		var shouldRoundCorners = true
		
		struct TickMark {
			enum Style: Equatable {
				case color(UIColor) // TODO: Handle drawing colored tick marks
				case occlusion
			}
			var location: Double
			var style: Style
		}
		
		// MARK: - Private Properties

		private static var tickMarkWidth: CGFloat = 2
		
		override class var layerClass: AnyClass { CAShapeLayer.self }
		private var baseLayer: CAShapeLayer { layer as! CAShapeLayer }
		
		private var elapsedLayer = CAShapeLayer()
		
		private var cornerRadius: CGFloat { shouldRoundCorners ? bounds.height / 2 : 0 }
		
		// MARK: - Init
		
		override init(frame: CGRect) {
			super.init(frame: frame)
			configureLayers()
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("Use `init(frame:)`")
		}
		
		private func configureLayers() {
			// Setting the fill rule to `.evenOdd` allows us to mask off the occlusion tick marks
			baseLayer.fillRule = .evenOdd
			elapsedLayer.fillRule = .evenOdd
			baseLayer.fillColor = remainingTintColor.cgColor
			elapsedLayer.fillColor = elapsedTintColor.cgColor
			baseLayer.addSublayer(elapsedLayer)
		}
		
		override func layoutSubviews() {
			setPathForLayer(baseLayer, withRect: bounds)
			let elapsedRect = CGRect(x: 0,
									 y: 0,
									 width: insetDistance + usableWidth * CGFloat(progress),
									 height: frame.height)
			setPathForLayer(elapsedLayer, withRect: elapsedRect)
		}
		
		private func setPathForLayer(_ layer: CAShapeLayer, withRect rect: CGRect) {
			let path = CGMutablePath(roundedRect: rect,
									 cornerWidth: cornerRadius,
									 cornerHeight: cornerRadius,
									 transform: nil)
			
			for tickMark in tickMarks where tickMark.style == .occlusion {
				let tickMarkRect = CGRect(x: insetDistance + (usableWidth - Self.tickMarkWidth) * tickMark.location,
										  y: 0,
										  width: Self.tickMarkWidth,
										  height: bounds.height)
				let rect = tickMarkRect.intersection(rect)
				guard rect != .null else { continue }
				path.addRect(rect)
			}
	
			layer.path = path
		}
	}
	
}

// MARK: - Playhead

extension PlaybackScrubber {
	
	class Playhead: UIView {
		
		// MARK: - Public Properties
		
		var color: UIColor = UIColor(white: 0.98, alpha: 1.0) {
			didSet {
				shapeLayer.fillColor = color.cgColor
			}
		}
		
		// MARK: - Private Properties
		
		override class var layerClass: AnyClass { CAShapeLayer.self }
		private var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
		
		// MARK: - Init
		
		override init(frame: CGRect) {
			super.init(frame: frame)
			shapeLayer.fillColor = color.cgColor
			configureShadow()
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("Use `init(frame:)`")
		}
		
		override func layoutSubviews() {
			shapeLayer.path = CGPath(ellipseIn: bounds, transform: nil)
		}
		
		private func configureShadow() {
			shapeLayer.shadowRadius = 3
			shapeLayer.shadowOffset = CGSize(width: 0, height: 1)
			shapeLayer.shadowColor = UIColor.black.cgColor
			shapeLayer.shadowOpacity = 0.3
		}
	}
}
