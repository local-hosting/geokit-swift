#if os(iOS) || os(visionOS) || os(tvOS) || os(macOS)

//
//  PlacePinView.swift
//  Places
//
//  Created by Dinesh Gajjar on 22/11/24.
//

import GeoKitContract
import SwiftUI

public enum PinStyle {
    case primary
    case secondary
}

private enum PinCalloutLayout {
    static let cornerRadius: CGFloat = 8
    static let tailSize: Double = 8
    static let borderWidth: CGFloat = 2
    static let contentPadding: CGFloat = 4
    static let rowSpacing: CGFloat = 4
    static let iconGlyphSize: CGFloat = 16
    static let iconPadding: CGFloat = 4
    static let textTrailingPadding: CGFloat = 4
    static let dotDiameter: CGFloat = 12
    static let dotTouchPadding: CGFloat = 10
    /// Map annotations anchor the view bottom to the coordinate; lift callouts so the tail points at the collapsed dot center.
    static var mapPointAnchorLift: CGFloat { dotTouchPadding + dotDiameter / 2 }
    /// Reserve layout space above the callout bubble for shadow — ``View.offset`` does not expand annotation bounds.
    static let calloutShadowBleed: CGFloat = 4
}

public struct GeoKitPlacePinView: View {
    @Environment(\.geokitMapIsTransitioning) private var mapIsTransitioning
    let pin: MapPin
    public let zoom: CGFloat
    public var tap: GeoKitTap
    var color: Color = GeoKitMapTheme.ink
    var pinStyle: PinStyle = .primary
    public var onTap: (MapPin, Bool, Bool) -> Void
    public var onInteractionBegan: (() -> Void)?
    @State var appeared = false
    var selected: Bool
    @State private var opacity: Double = 0.0
    @State     var visible: Bool = false
    var allowCallout: Bool = true
    var showText: Bool = false
    

    public init(
        pin: MapPin,
        zoom: CGFloat,
        tap: GeoKitTap,
        color: Color = GeoKitMapTheme.ink,
        pinStyle: PinStyle = .primary,
        onTap: @escaping (MapPin, Bool, Bool) -> Void,
        onInteractionBegan: (() -> Void)? = nil,
        selected: Bool,
        visible: Bool = false,
        allowCallout: Bool = true,
        showText: Bool = false
    ) {
        self.pin = pin
        self.zoom = zoom
        self.tap = tap
        self.color = color
        self.pinStyle = pinStyle
        self.onTap = onTap
        self.onInteractionBegan = onInteractionBegan
        self.selected = selected
        self._visible = State(initialValue: visible)
        self.allowCallout = allowCallout
        self.showText = showText
    }

    private var headingText: String { pin.pinHeading }
    
    private var subHeadingText: String {
        let subheading = pin.pinSubheading
        return subheading.isEmpty ? " " : subheading
    }
    
    public var body: some View {
        
        let shouldShowCallout = allowCallout && zoom >= 10
        let accentColor = pin.isPrimary ? GeoKitMapTheme.accent : GeoKitMapTheme.secondary
        
        if !shouldShowCallout {
            let (size, borderWidth, borderShadowRadius): (CGFloat, CGFloat, CGFloat) = {
                if zoom == 0 {
                    return (2, 1, 1)
                } else if zoom > 0 && zoom <= 2 {
                    return (3, 1, 1)
                } else if zoom > 2 && zoom <= 5 {
                    return (5, 1.2, 1.2)
                } else if zoom > 5 && zoom <= 8 {
                    return (10, 2, 2)
                } else if zoom > 8 && zoom <= 10 {
                    return (15, 2, 2)
                }
                return (3, 1, 1)
            }()

            CirclePinAnnotation(
                size: size,
                color: accentColor,
                borderWidth: borderWidth,
                borderShadowRadius: borderShadowRadius,
                selected: selected,
                icon: pin.icon,
                heading: headingText,
                subHeading: subHeadingText,
                pinStyle: pin.isPrimary ? .primary : .secondary,
                tap: tap,
                showText: false
            ).onTapGesture {
                onTap(pin, !selected, true)
            }
            .pinTouchShield(onInteractionBegan: onInteractionBegan)
        }

        if shouldShowCallout {
            ViewAnnotationCallOutView(
                icon: pin.icon,
                tap: tap,
                heading: headingText,
                subHeading: subHeadingText,
                pinStyle: pin.isPrimary ? .primary : .secondary,
                color: accentColor,
                selected: selected,
                showText: showText,
                visible: visible,
                skipIntroAnimation: mapIsTransitioning
            )
            .fixedSize(horizontal: true, vertical: true)
            .opacity(mapIsTransitioning ? 1.0 : opacity)
            .onTapGesture {
                onTap(pin, !selected, false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
                    visible = !selected
                }
            }
            .pinTouchShield(onInteractionBegan: onInteractionBegan)
            .onAppear {
                opacity = 1.0
            }
        }
    }
    
    struct CirclePinAnnotation: View {
        let size: CGFloat
        let color: Color
        let radius: Float = 2
        let borderWidth: CGFloat
        let borderShadowRadius: CGFloat
        var selected: Bool = false
        var icon: String
        var heading: String?
        var subHeading: String?
        var pinStyle: PinStyle = .primary
        public var tap: GeoKitTap
        var showText: Bool
        
        public var body: some View {
            if selected && showText {
                HStack(spacing: PinCalloutLayout.rowSpacing) {
                    GeoKitPinIcon.image(named: icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: PinCalloutLayout.iconGlyphSize, height: PinCalloutLayout.iconGlyphSize)
                        .foregroundColor(.white)
                        .padding(PinCalloutLayout.iconPadding)
                        .background(Circle().fill(color))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(heading ?? "NA")
                            .font(GeoKitMapTheme.calloutHeadingFont)

                        Text(subHeading ?? "NA")
                            .font(GeoKitMapTheme.calloutSubheadingFont)
                    }
                    .padding(.trailing, PinCalloutLayout.textTrailingPadding)
                }
                .padding(PinCalloutLayout.contentPadding)
                .foregroundColor(.white)
                .geoKitCallout(
                    anchor: tap.selectedAnchor ?? .center,
                    color: color,
                    borderColor: .white,
                    tailSize: PinCalloutLayout.tailSize,
                    cornerRadius: PinCalloutLayout.cornerRadius,
                    borderWidth: PinCalloutLayout.borderWidth
                )
                .padding(.top, PinCalloutLayout.calloutShadowBleed)
                .padding(.bottom, size / 1.6)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: borderWidth)
                    )
                    .shadow(color: color.opacity(0.3), radius: borderShadowRadius)
                    .padding(10)
            }
        }
    }
    
    struct ViewAnnotationCallOutView: View {
        var icon: String
        public var tap: GeoKitTap
        var heading: String?
        var subHeading: String?
        var pinStyle: PinStyle = .secondary
        var color: Color
        var selected: Bool = false
        var showText: Bool
        var visible: Bool = false
        var skipIntroAnimation: Bool = false

        public var body: some View {
            if selected {
                emphasizedPinCallout(
                    isEmphasized: showText,
                    showNameLabel: showText,
                    skipIntroAnimation: skipIntroAnimation
                )
            } else {
                unselectedDot
            }
        }

        private var unselectedDot: some View {
            Circle()
                .fill(color)
                .frame(width: PinCalloutLayout.dotDiameter, height: PinCalloutLayout.dotDiameter)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: color.opacity(0.3), radius: 2)
                .padding(PinCalloutLayout.dotTouchPadding)
        }

        @ViewBuilder
        private func emphasizedPinCallout(
            isEmphasized: Bool,
            showNameLabel: Bool,
            skipIntroAnimation: Bool = false
        ) -> some View {
            HStack(spacing: PinCalloutLayout.rowSpacing) {
                if isEmphasized {
                    GeoKitPinIcon.image(named: icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: PinCalloutLayout.iconGlyphSize, height: PinCalloutLayout.iconGlyphSize)
                        .foregroundColor(.white)
                        .padding(PinCalloutLayout.iconPadding)
                        .background(Circle().fill(color))
                } else {
                    GeoKitPinIcon.image(named: icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: PinCalloutLayout.iconGlyphSize, height: PinCalloutLayout.iconGlyphSize)
                        .foregroundColor(selected ? .white : color)
                        .padding(PinCalloutLayout.iconPadding)
                        .background(selected ? color : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                if showNameLabel {
                    Text(heading ?? "NA")
                        .font(GeoKitMapTheme.emphasisFont(size: isEmphasized ? 12 : 10))
                        .lineLimit(1)
                        .padding(.trailing, PinCalloutLayout.textTrailingPadding)
                }
            }
            .opacity(showNameLabel ? 1 : 0)
            .animation(
                skipIntroAnimation
                    ? nil
                    : .easeIn(duration: 0.3).delay(isEmphasized ? 0.27 : 0),
                value: isEmphasized
            )
            .padding(PinCalloutLayout.contentPadding)
            .foregroundColor(isEmphasized ? .white : color)
            .geoKitCallout(
                anchor: tap.selectedAnchor ?? .bottom,
                color: isEmphasized ? color : (selected ? color : .white),
                borderColor: isEmphasized ? .white : (selected ? .white : color),
                tailSize: PinCalloutLayout.tailSize,
                cornerRadius: PinCalloutLayout.cornerRadius,
                borderWidth: PinCalloutLayout.borderWidth
            )
            .padding(.top, PinCalloutLayout.calloutShadowBleed)
            .padding(.bottom, PinCalloutLayout.mapPointAnchorLift)
        }
    }
}

private extension View {
    /// Blocks host tap overlays from treating pin touches as background taps.
    func pinTouchShield(onInteractionBegan: (() -> Void)?) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onInteractionBegan?() }
        )
    }
}
#endif
