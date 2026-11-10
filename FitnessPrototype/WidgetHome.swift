import SwiftUI

enum WidgetKind: String, CaseIterable {
    case fitness = "Fitness"
    case stocks = "Stocks"

    var order: Int { self == .stocks ? 1 : 0 }

    var identifier: String { rawValue.lowercased() }
}

@MainActor
struct WidgetHome: View {
    let select: (WidgetKind) -> Bool
    @State private var selected: WidgetKind = .fitness
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let segmentWidth: CGFloat = 70

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let gridWidth = size.width * 0.895
            let iconSize = min(64, size.width * 0.155)

            ZStack {
                Image("StockWallpaper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(["Calendar", "Photos", "Settings"], id: \.self) { name in
                            VStack(spacing: 5) {
                                icon(name, size: iconSize)
                                Text(name)
                                    .font(.system(size: 12, weight: .medium))
                                    .shadow(color: .black.opacity(0.65), radius: 2, y: 1)
                            }
                            .frame(width: gridWidth / 4)
                        }
                        Color.clear.frame(width: gridWidth / 4, height: 1)
                    }
                    .padding(.top, size.height * 0.328)
                    .accessibilityHidden(true)

                    Spacer(minLength: 0)

                    HStack(spacing: 0) {
                        ForEach(WidgetKind.allCases, id: \.self) { kind in
                            Button {
                                guard select(kind) else { return }
                                let animation: Animation? = reduceMotion ? nil : .easeInOut(duration: WidgetSwitch.duration)
                                withAnimation(animation) { selected = kind }
                            } label: {
                                Text(kind.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .frame(width: segmentWidth, height: 30)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected == kind ? .isSelected : [])
                            .accessibilityIdentifier("select-\(kind.identifier)")
                        }
                    }
                    .background(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.17))
                            .frame(width: segmentWidth, height: 30)
                            .offset(x: CGFloat(selected.order) * segmentWidth)
                            .allowsHitTesting(false)
                    }
                    .padding(2)
                    .glassEffect(.regular)
                    .padding(.bottom, 18)

                    HStack(spacing: 28) {
                        icon("Messages", size: iconSize)
                        icon("Safari", size: iconSize)
                    }
                    .frame(width: gridWidth, height: iconSize + 35)
                    .glassEffect(.regular, in: .rect(cornerRadius: 32))
                    .padding(.bottom, size.height * 0.029)
                    .accessibilityHidden(true)
                }
                .frame(width: size.width, height: size.height)
                .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func icon(_ name: String, size: CGFloat) -> some View {
        Image("Stock\(name)")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.227))
    }
}
