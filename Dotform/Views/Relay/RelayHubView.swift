import SwiftUI

struct RelayHubView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var session = RelaySessionController()
    @StateObject private var playback = RelayPlaybackController()

    @State private var role: RelayRole = .receiver
    @State private var draftText = ""
    @State private var showScanner = false
    @State private var sentLog: [String] = []

    var body: some View {
        Group {
            if session.isConnected {
                connectedBody
            } else {
                pairingBody
            }
        }
        .navigationTitle("Связь")
        .onAppear {
            WatchConnectivityBridge.shared.activate()
            if role == .receiver, !session.isConnected {
                beginReceiver()
            }
        }
        .onDisappear {
            if !session.isConnected {
                session.stop()
            }
        }
        .onChange(of: session.connectionState) { _, state in
            if case .connected = state, role == .receiver {
                let name = appState.profile?.title ?? "Dotform"
                session.send(.hello(scriptID: appState.settings.activeScript, displayName: name))
            }
            if case .failed = state {
                playback.stop()
                appState.feedback.errorFeedback(settings: appState.settings)
            }
        }
        .onChange(of: session.lastIncoming) { _, envelope in
            guard let envelope else { return }
            handleIncoming(envelope)
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView(
                onCode: { code in
                    showScanner = false
                    if let payload = RelayPairingPayload.parse(code) {
                        session.startAsWriter(pairing: payload)
                    }
                },
                onClose: { showScanner = false }
            )
            .ignoresSafeArea()
        }
    }

    private var pairingBody: some View {
        List {
            Section {
                Picker("Роль", selection: $role) {
                    ForEach(RelayRole.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: role) { _, newValue in
                    session.stop()
                    if newValue == .receiver {
                        beginReceiver()
                    }
                }

                Text(role.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Статус") {
                Text(statusText)
                    .accessibilityLabel(statusText)
                if let error = session.lastError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if role == .receiver, let payload = session.pairingPayload {
                Section("QR для спаривания") {
                    HStack {
                        Spacer()
                        QRCodeImageView(string: payload.qrString)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    Button("Обновить QR") {
                        beginReceiver()
                    }
                }
            }

            if role == .writer {
                Section {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Сканировать QR", systemImage: "qrcode.viewfinder")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var connectedBody: some View {
        if role == .writer {
            writerBody
        } else {
            receiverBody
        }
    }

    private var writerBody: some View {
        VStack(spacing: 0) {
            connectionBanner
            Form {
                Section("Сообщение") {
                    TextEditor(text: $draftText)
                        .frame(minHeight: 120)
                        .accessibilityLabel("Текст для отправки")

                    Button {
                        sendText()
                    } label: {
                        Label("Отправить", systemImage: "paperplane.fill")
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Остановить воспроизведение", role: .destructive) {
                        session.send(.cancel())
                    }
                }

                if !sentLog.isEmpty {
                    Section("Отправлено") {
                        ForEach(sentLog.indices.reversed(), id: \.self) { index in
                            Text(sentLog[index])
                                .font(.body)
                        }
                    }
                }

                Section {
                    Button("Отключить", role: .destructive) {
                        session.stop()
                        playback.stop()
                    }
                }
            }
        }
    }

    private var receiverBody: some View {
        VStack(spacing: 0) {
            connectionBanner

            ZStack {
                if let glyph = playback.currentGlyph {
                    BrailleCellView(
                        letter: glyph,
                        mode: .explore,
                        selectedDots: [],
                        foundDots: [],
                        showFilledDots: appState.settings.showDotsVisually,
                        onDotTouch: { _ in }
                    )
                } else {
                    VStack(spacing: 12) {
                        Text(playback.isPlaying ? "…" : "Ожидание сообщения")
                            .font(.title2.weight(.semibold))
                        if playback.totalCount > 0 {
                            Text("\(playback.progressIndex)/\(playback.totalCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let status = playback.statusMessage {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .cardScreenChrome()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 16) {
                Button {
                    playback.stop()
                    session.send(.cancel())
                    appState.feedback.errorFeedback(settings: appState.settings)
                } label: {
                    Label("Стоп", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button(role: .destructive) {
                    playback.stop()
                    session.stop()
                } label: {
                    Label("Отключить", systemImage: "link.badge.minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private var connectionBanner: some View {
        HStack {
            Image(systemName: "link")
            Text(statusText)
                .font(.subheadline)
            Spacer()
            if WatchConnectivityBridge.shared.isWatchReachable {
                Image(systemName: "applewatch")
                    .accessibilityLabel("Apple Watch на связи")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var statusText: String {
        switch session.connectionState {
        case .idle: return "Не подключено"
        case .advertising: return "Ожидание сканирования QR…"
        case .browsing: return "Поиск устройства…"
        case .connecting: return "Подключение…"
        case .connected(let name): return "Связано: \(name)"
        case .failed(let message): return message
        }
    }

    private func beginReceiver() {
        let name = appState.profile?.title ?? "Dotform"
        session.startAsReceiver(displayName: name)
    }

    private func sendText() {
        let body = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        session.send(.text(body, scriptID: appState.settings.activeScript))
        sentLog.append(body)
        draftText = ""
        appState.feedback.shortSignal(settings: appState.settings)
    }

    private func handleIncoming(_ envelope: RelayEnvelope) {
        switch envelope.type {
        case .hello:
            break
        case .text:
            guard role == .receiver, let text = envelope.text else { return }
            let script = BrailleScriptID(rawValue: envelope.scriptID ?? "") ?? appState.settings.activeScript
            playback.play(
                text: text,
                scriptID: script,
                settings: appState.settings,
                feedback: appState.feedback
            )
        case .cancel:
            playback.stop()
            appState.feedback.errorFeedback(settings: appState.settings)
        case .ping, .ack:
            break
        }
    }
}

#Preview {
    NavigationStack {
        RelayHubView()
            .environmentObject(AppState())
    }
}
