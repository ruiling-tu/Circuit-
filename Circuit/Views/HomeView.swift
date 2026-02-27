import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var showReset = false
    @State private var showQuickPicker = false
    @State private var quickState: FeelingStateOption?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Spacer()

                BeginResetButton {
                    HapticsManager.shared.impact(.medium)
                    quickState = nil
                    showReset = true
                }

                Button("Quick Circuit") {
                    HapticsManager.shared.impact(.light)
                    showQuickPicker = true
                }
                .buttonStyle(.borderedProminent)

                Text("~90 seconds")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.55))

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showReset, onDismiss: { quickState = nil }) {
            ResetFlowView(quickMode: quickState != nil, preselectedState: quickState)
        }
        .sheet(isPresented: $showQuickPicker) {
            QuickStatePickerView { state in
                quickState = state
                showQuickPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showReset = true
                }
            }
        }
    }
}

private struct QuickStatePickerView: View {
    let onSelect: (FeelingStateOption) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                Text("Quick Circuit")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.75))

                Text("Pick how you feel right now")
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.6))

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ResetContent.states) { state in
                        StateCard(title: state.title) {
                            onSelect(state)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
