import AccordDesignSystem
import GeoKitContract
import SwiftUI

struct GeoKitDemoRootView: View {
    @StateObject private var deck = GeoKitDemoDeck()
    @Namespace private var cardNamespace

    var body: some View {
        AXBackdropShell {
            AX.Stack(
                viewModel: deck,
                cardNamespace: cardNamespace,
                stackPadding: EdgeInsets(top: 24, leading: 32, bottom: 0, trailing: 32),
                paging: AX.StackPaging(
                    pageCount: deck.cards.count,
                    currentIndex: deck.currentIndex,
                    dotColor: AX.Colors.whiteSmoke,
                    canSelectPage: { _ in !deck.isTransitioning },
                    onPageSelected: { index in
                        if deck.isExpanded {
                            deck.switchToCardWhileExpanded(index: index)
                        } else {
                            deck.jumpToCard(index: index)
                        }
                    }
                )
            ) { card, isExpanded in
                GeoKitDemoCardContent(card: card, isExpanded: isExpanded)
            } headerContent: { card in
                AXBadge(title: card.title, subtitle: card.subtitle, placement: .cardFooter)
            }
        }
        .accessibilityIdentifier("geokit-test-app.root")
    }
}

private struct GeoKitDemoCardContent: View {
    let card: GeoKitDemoCard
    let isExpanded: Bool

    var body: some View {
        Group {
            if let mapContent = GeoKitRuntime.mapContent {
                mapContent(card.mapRequest(isExpanded: isExpanded))
                .preference(key: AXCardLiveRenderingKey.self, value: isExpanded)
            } else {
                ZStack {
                    AX.Colors.darkBackground
                    Text("GeoKit map content not registered")
                        .font(AX.Typography.cardTitleFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("geokit-test-app.card")
    }
}
