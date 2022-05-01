//
//  PlaybackScrubber.swift
//  PlaybackScrubber
//
//  Created by Shawn Gee on 4/30/22.
//

import UIKit

public protocol PlaybackScrubberDelegate: AnyObject {
	func scrubber(_ playbackScrubber: PlaybackScrubber, didBeginScrubbingAtTime time: TimeInterval)
	func scrubber(_ playbackScrubber: PlaybackScrubber, didScrubToTime time: TimeInterval)
	func scrubber(_ playbackScrubber: PlaybackScrubber, didEndScrubbingAtTime time: TimeInterval)
}

public class PlaybackScrubber: UIControl {
	public struct SectionMarker {
		var time: TimeInterval
		var title: String?
		var description: String?
	}
	// MARK: - Public Properties
	
	public weak var delegate: PlaybackScrubberDelegate?
	
	/// The overall duration of the media this scrubber represents in seconds.
	/// The default value of this property is 1.0
	public var duration: TimeInterval = 1.0 {
		didSet {
			clampPlayheadPosition()
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
			case .mayScrub, .none:
				break
			}
			playheadPosition = newValue
		}
		
		get { playheadPosition }
	}
	
	public var isHapticFeedbackEnabled: Bool = true
	
	/// An array of markers that denote sections within the media. These markers will be indicated visually,
	/// and haptic feedback (if enabled) will let the user know when they have changed sections while scrubbing.
	public var sectionMarkers: [SectionMarker] = [] {
		didSet {
			updateTrackTickMarks()
			track.setNeedsLayout()
		}
	}
	
	/// The height of the track that the playhead moves along.
	/// The default value of this property is 6 pt.
	public var trackHeight: CGFloat = 6
	
	/// True if the corners of the track and the elapsed time fill should be rounded, false otherwise.
	public var shouldRoundTrackCorners: Bool {
		set { track.shouldRoundCorners = newValue }
		get { track.shouldRoundCorners }
	}
	
	/// The color of the portion of the track that represents the elapsed time.
	/// The default value of this property is `.systemGreen`.
	public var elapsedTrackTintColor: UIColor {
		set { track.elapsedTintColor = newValue }
		get { track.elapsedTintColor }
	}
	
	/// The color of the portion of the track that represents the remaining time.
	/// The default value of this property is a light gray with 50% opacity.
	public var remainingTrackTintColor: UIColor {
		set { track.remainingTintColor = newValue }
		get { track.remainingTintColor }
	}
	
	
	/// The size of the playhead (a.k.a. thumb, knob, handle) that indicates the `currentTime` of the scrubber.
	/// The default value of this property is 14x14 pt.
	public var playheadSize: CGSize = CGSize(width: 14, height: 14) {
		didSet {
			updateTrackInset()
			setNeedsLayout()
		}
	}
	
	/// The fill color of the playhead.
	/// The default value of this property is a very light gray.
	public var playheadColor: UIColor {
		set { playhead.color = newValue }
		get { playhead.color }
	}
	
	/// When true, the user can initiate a scrub by dragging on the track at any location, not just where the playhead is.
	/// The touch must move a certain amount before the playhead will snap to the touch's location.
	/// When false, the user must touch within the playhead's frame (plus some margin) in order to initiate a scrub.
	public var allowScrubbingFromAnyTouchLocation = true
	
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
	
	private let track = Track()
	private let playhead = Playhead()
	
	enum InteractionState {
		case none
		case mayScrub(initialTouchLocation: CGPoint)
		case scrubbing(initialPlayheadPosition: TimeInterval)
		
		/// The minimum amount a touch must move to initiate a scrub when dragging at a point not within the playhead's touch target.
		static let minXDistanceToInitiateScrub: CGFloat = 10
	}

	/// Used to track the user's interaction with the control.
	private var interactionState: InteractionState = .none
	
	/// Provides haptic feedback to the user as they drag the playhead.
	private var feedbackGenerator : UIImpactFeedbackGenerator?
	private static let markerImpactIntensity = 0.6
	
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
	
	/// Clamps the playhead position within the range of `0...duration`.
	private func clampPlayheadPosition() {
		// Position is clamped in the setter for `playheadPosition`
		playheadPosition = _clampedPlayheadPosition
	}
	
	public override func layoutSubviews() {
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

	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let touchLocation = touch.location(in: self)
		
		if playhead.frame.touchTarget.contains(touchLocation) {
			interactionState = .scrubbing(initialPlayheadPosition: playheadPosition)
			delegate?.scrubber(self, didBeginScrubbingAtTime: playheadPosition)
		} else if allowScrubbingFromAnyTouchLocation {
			interactionState = .mayScrub(initialTouchLocation: touchLocation)
		}
		
		if isHapticFeedbackEnabled {
			feedbackGenerator = UIImpactFeedbackGenerator()
			feedbackGenerator?.prepare()
		}
	}
	
	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		let touchLocation = touch.location(in: self)
		
		switch interactionState {
		case .none:
			// Nothing to do, the user hasn't initiated a scrub.
			break
		case .mayScrub(let initialTouchLocation):
			if abs(touchLocation.x - initialTouchLocation.x) >= InteractionState.minXDistanceToInitiateScrub {
				delegate?.scrubber(self, didBeginScrubbingAtTime: playheadPosition)
				interactionState = .scrubbing(initialPlayheadPosition: playheadPosition)
				fallthrough
			}
		case .scrubbing:
			let newPlayheadPosition = playheadPosition(forTouchLocation: touchLocation)
			
			if sectionMarkerExistsBetween(playheadPosition, newPlayheadPosition) {
				feedbackGenerator?.impactOccurred(intensity: Self.markerImpactIntensity)
				feedbackGenerator?.prepare()
			}
			
			playheadPosition = newPlayheadPosition
			delegate?.scrubber(self, didScrubToTime: playheadPosition)
		}
	}
	
	private func sectionMarkerExistsBetween(_ timeA: TimeInterval, _ timeB: TimeInterval) -> Bool {
		return sectionMarkers.contains(where: { marker in
			timeA < marker.time && timeB >= marker.time ||
			timeA > marker.time && timeB <= marker.time
		})
	}
	
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch interactionState {
		case .none, .mayScrub:
			// Nothing to do, the user hasn't initiated a scrub.
			break
		case .scrubbing:
			delegate?.scrubber(self, didEndScrubbingAtTime: playheadPosition)
		}

		interactionState = .none
		feedbackGenerator = nil
	}
	
	private func playheadPosition(forTouchLocation touchLocation: CGPoint) -> TimeInterval {
		(touchLocation.x - track.insetDistance) / track.usableWidth * duration
	}
	
	public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch interactionState {
		case .none, .mayScrub:
			// Nothing to do, the user hasn't initiated a scrub.
			break
		case .scrubbing(let initialPlayheadPosition):
			// Reset playhead position in the case that touches were cancelled.
			playheadPosition = initialPlayheadPosition
			delegate?.scrubber(self, didEndScrubbingAtTime: playheadPosition)
		}
		
		interactionState = .none
		feedbackGenerator = nil
	}
}

// MARK: - Track

extension PlaybackScrubber {
	class Track: UIView {
		
		/// The width of the portion of the track at either end that is not usable due to the width of the playhead.
		var insetDistance: CGFloat = 0
		
		/// The width portion of the track that is usable, calculated based on the width of the track and the `insetDistance`.
		var usableWidth: CGFloat { frame.width - insetDistance * 2 }
		
		/// The percentage of progress to indicate visually via the `elapsedTintColor`.
		/// Must be in the range of 0...1
		var progress: Double = 0.5
		
		/// The color of the portion of the track that represents the elapsed time. Defaults to `.systemGreen`.
		var elapsedTintColor: UIColor = .systemGreen {
			didSet {
				elapsedLayer.fillColor = elapsedTintColor.cgColor
			}
		}
		
		/// The color of the portion of the track that represents the remaining time. Defaults to a light gray with 50% opacity.
		var remainingTintColor: UIColor = UIColor(white: 0.7, alpha: 0.5) {
			didSet {
				baseLayer.fillColor = remainingTintColor.cgColor
			}
		}
		
		/// An array of tick marks to be represented on the track visually.
		var tickMarks: [TickMark] = []
		
		/// True if the corners of the track and the elapsed time fill should be rounded, false otherwise.
		var shouldRoundCorners = true
		
		struct TickMark {
			enum Style: Equatable {
				case occlusion
//				case color(UIColor) // TODO: Handle drawing colored tick marks
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
		
		/// The fill color of the playhead. Defaults to a very light gray.
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
