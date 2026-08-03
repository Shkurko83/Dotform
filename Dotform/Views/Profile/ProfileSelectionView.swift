import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject private var appState: AppState
    var isOnboarding: Bool = false

    var body: some View {
        List {
            Section {
                Text("Профиль определяет тип обратной связи, структуру уроков и доступные настройки.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Выберите профиль") {
                ForEach(UserProfile.allCases) { profile in
                    ProfileRow(
                        profile: profile,
                        isSelected: appState.profile == profile,
                        onSelect: { selectProfile(profile) }
                    )
                }
            }
        }
        .navigationTitle("Профиль")
    }

    private func selectProfile(_ profile: UserProfile) {
        if isOnboarding {
            appState.completeOnboarding(profile: profile)
        } else {
            appState.selectProfile(profile)
        }
    }
}

private struct ProfileRow: View {
    let profile: UserProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(profile.accessibilityHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityLabel(profile.title)
        .accessibilityHint(profile.accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        ProfileSelectionView()
            .environmentObject(AppState())
    }
}
