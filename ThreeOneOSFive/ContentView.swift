import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-new-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-sources-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-installed-tab")
                    || arguments.contains("--simulate-patch-tab")
                    || arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-files-tab") {
            initialTab = 4
        } else if arguments.contains("--simulate-search-tab") {
            initialTab = 5
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(
            initialValue: arguments.contains("--simulate-settings")
        )
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil {
                tabNavigation.select(AppSection.installed.rawValue)
            }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil {
                tabNavigation.select(AppSection.installed.rawValue)
            }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showLogs) {
            LogView()
        }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach([AppSection.home, .installed]) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach([AppSection.home, .installed]) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(
                            language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                        .fontWeight(
                            section.rawValue == tabNavigation.selectedTab
                                ? .semibold
                                : .regular
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab
                            ? .isSelected
                            : []
                    )
                }
            }
            .navigationTitle("MISBAH PENAL")
            .navigationSplitViewColumnWidth(
                min: 210,
                ideal: 240,
                max: 300
            )
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            MisbahHomeView(onOpenSettings: openSettings)

        case .new:
            RepositoryNewView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )

        case .sources:
            RepositorySourcesView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )

        case .installed:
            PatchProjectsView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )

        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )

        case .search:
            RepositorySearchView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeActive)
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap {
            ([AppSection.home, .installed].contains($0)) ? $0 : nil
        } ?? .home
    }

    private func openSettings() {
        showSettings = true
    }

    private func openLogs() {
        showLogs = true
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: 17,
                weight: .medium
            )
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }

        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.fill"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}


// MARK: - MISBAH PENAL home dashboard

struct MisbahHomeView: View {
    @EnvironmentObject private var license: MisbahLicenseManager
    @EnvironmentObject private var appState: AppState

    let onOpenSettings: () -> Void

    private let blue = Color(
        red: 0.12,
        green: 0.47,
        blue: 0.82
    )

    private let paleBlue = Color(
        red: 0.90,
        green: 0.95,
        blue: 1.00
    )

    private let whatsappGroup = URL(
        string: "https://chat.whatsapp.com/GYAkNlKXIqB4i2FxOuLxQW?s=cl&p=i&mlu=4&ilr=4&iam=2"
    )!

    private let whatsappContact = URL(
        string: "https://wa.me/923009353079"
    )!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 3) {
                        Text("MISBAH PENAL")
                            .font(
                                .system(
                                    size: 28,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(blue)

                        Text("Developer Shafay")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(blue.opacity(0.78))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(blue)

                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let remaining = max(
                                0,
                                (license.expiresAt ?? context.date)
                                    .timeIntervalSince(context.date)
                            )

                            Text(Self.formatDuration(remaining))
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                    .monospacedDigit()
                                )
                                .foregroundStyle(blue)
                        }

                        Text("KEY LINK ACTIVE")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(blue.opacity(0.7))

                        Text("Linked to This Device")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(paleBlue, in: Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(blue.opacity(0.18), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Device Information")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(blue)
                            .padding(.bottom, 8)

                        deviceRow(
                            "Device Name",
                            value: UIDevice.current.name
                        )

                        deviceRow(
                            "Device Model",
                            value: UIDevice.current.model
                        )

                        deviceRow(
                            "iOS Version",
                            value: UIDevice.current.systemVersion
                        )

                        deviceRow(
                            "Source",
                            value: "MISBAH PENAL"
                        )

                        deviceRow(
                            "Supported",
                            value: appState.isSupported ? "Yes" : "Not supported",
                            good: appState.isSupported,
                            last: true
                        )
                    }
                    .padding(16)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(blue.opacity(0.15), lineWidth: 1)
                    )

                    VStack(spacing: 10) {
                        Text("Our Official Channel")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(blue)

                        Link(destination: whatsappGroup) {
                            Label(
                                "Join our WhatsApp group",
                                systemImage: "message.circle.fill"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(blue)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(14)
                            .background(
                                .white,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(blue.opacity(0.15), lineWidth: 1)
                            )
                        }

                        Link(destination: whatsappContact) {
                            Label(
                                "+92 300 9353079",
                                systemImage: "phone.circle.fill"
                            )
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(blue)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(14)
                            .background(
                                .white,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(blue.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(
                Color(red: 0.97, green: 0.99, blue: 1.0)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(blue)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .preferredColorScheme(ColorScheme.light)
        .onReceive(
            Timer.publish(
                every: 1,
                on: .main,
                in: .common
            ).autoconnect()
        ) { _ in
            license.checkExpiry()
        }
    }

    private func deviceRow(
        _ title: String,
        value: String,
        good: Bool = false,
        last: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(blue.opacity(0.72))

                Spacer(minLength: 12)

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(good ? Color.green : blue)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 11)

            if !last {
                Divider()
                    .overlay(blue.opacity(0.08))
            }
        }
    }

    private static func formatDuration(
        _ interval: TimeInterval
    ) -> String {
        let seconds = max(0, Int(interval))
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        return days > 0
            ? String(
                format: "%02d:%02d:%02d:%02d",
                days,
                hours,
                minutes,
                secs
            )
            : String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                secs
            )
    }
}


// MARK: - MISBAH PENAL license authorization

@MainActor
final class MisbahLicenseManager: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published private(set) var expiresAt: Date?
    @Published private(set) var isVerifying = false
    @Published var message: String?
    @Published var lastStatus: String?

    private let endpoint = URL(
        string: "https://shafaykeyauthadmin.lovable.app/api/public/v1/verify-license"
    )!

    private let savedKeyKey = "misbah.license.key"
    private let savedExpiryKey = "misbah.license.expires_at"
    private let deviceIDKey = "misbah.license.device_id"

    init() {
        if let savedKey = UserDefaults.standard.string(forKey: savedKeyKey),
           !savedKey.isEmpty {
            Task {
                await verify(key: savedKey, showErrors: false)
            }
        }
    }

    var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey) {
            return existing
        }

        let value = UIDevice.current.identifierForVendor?.uuidString
            ?? UUID().uuidString

        UserDefaults.standard.set(value, forKey: deviceIDKey)
        return value
    }

    func activate(key: String) async {
        await verify(
            key: key.trimmingCharacters(in: .whitespacesAndNewlines),
            showErrors: true
        )
    }

    func reverifySavedLicense() async {
        guard let key = UserDefaults.standard.string(forKey: savedKeyKey),
              !key.isEmpty else {
            isAuthorized = false
            return
        }

        await verify(key: key, showErrors: false)
    }

    func checkExpiry() {
        guard let expiresAt, expiresAt <= Date() else {
            return
        }

        isAuthorized = false
        self.expiresAt = nil

        UserDefaults.standard.removeObject(forKey: savedKeyKey)
        UserDefaults.standard.removeObject(forKey: savedExpiryKey)

        message = "This license key has expired."
    }

    private func verify(
        key: String,
        showErrors: Bool
    ) async {
        guard !key.isEmpty else {
            message = showErrors ? "Enter your license key first." : nil
            isAuthorized = false
            return
        }

        isVerifying = true
        defer {
            isVerifying = false
        }

        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.timeoutInterval = 20

            request.httpBody = try JSONSerialization.data(
                withJSONObject: [
                    "key": key,
                    "device_id": deviceID
                ]
            )

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            let payload = (
                try? JSONSerialization.jsonObject(with: data)
            ) as? [String: Any] ?? [:]

            let valid = payload["valid"] as? Bool == true
                && payload["success"] as? Bool == true

            let status = (
                payload["status"] as? String ?? "unknown"
            ).lowercased()

            guard (200..<300).contains(statusCode),
                  valid,
                  status == "active",
                  let expiryString = payload["expires_at"] as? String,
                  let expiry = Self.parseDate(expiryString),
                  expiry > Date() else {

                isAuthorized = false
                expiresAt = nil

                UserDefaults.standard.removeObject(forKey: savedKeyKey)
                UserDefaults.standard.removeObject(forKey: savedExpiryKey)

                let code = payload["code"] as? String

                switch code ?? status {
                case "not_found", "invalid":
                    message = "This license key is invalid."

                case "device_limit":
                    message = "This key has reached its device limit."

                case "expired":
                    message = "This license key has expired."

                default:
                    message = showErrors
                        ? (
                            payload["message"] as? String
                                ?? "License verification failed. Please try again."
                        )
                        : nil
                }

                lastStatus = status
                return
            }

            UserDefaults.standard.set(key, forKey: savedKeyKey)
            UserDefaults.standard.set(
                expiry.timeIntervalSince1970,
                forKey: savedExpiryKey
            )

            expiresAt = expiry
            isAuthorized = true
            message = nil
            lastStatus = "active"

        } catch {
            isAuthorized = false

            message = showErrors
                ? "Could not contact the license server. Check your internet and try again."
                : nil
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = fractional.date(from: value) {
            return date
        }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        return standard.date(from: value)
    }
}


struct MisbahAuthorizationView: View {
    @EnvironmentObject private var license: MisbahLicenseManager
    @State private var keyText = ""
    @State private var showSettingsInfo = false

    private let blue = Color(
        red: 0.12,
        green: 0.47,
        blue: 0.82
    )

    private let paleBlue = Color(
        red: 0.90,
        green: 0.95,
        blue: 1.00
    )

    private let whatsappGroup = URL(
        string: "https://chat.whatsapp.com/GYAkNlKXIqB4i2FxOuLxQW?s=cl&p=i&mlu=4&ilr=4&iam=2"
    )!

    private let whatsappContact = URL(
        string: "https://wa.me/923009353079"
    )!

    var body: some View {
        ZStack {
            Color(
                red: 0.97,
                green: 0.99,
                blue: 1.0
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Spacer()

                        Button {
                            showSettingsInfo = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(blue)
                                .padding(10)
                                .background(
                                    paleBlue,
                                    in: Circle()
                                )
                        }
                        .accessibilityLabel("Settings")
                    }

                    VStack(spacing: 5) {
                        Text("MISBAH PENAL")
                            .font(
                                .system(
                                    size: 32,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(blue)

                        Text("Developer Shafay")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(blue.opacity(0.78))
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 16) {
                        Label(
                            "Key Authorization",
                            systemImage: "key.horizontal"
                        )
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(blue)

                        HStack(spacing: 10) {
                            TextField(
                                "Enter or paste your key",
                                text: $keyText
                            )
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .foregroundStyle(
                                Color(
                                    red: 0.08,
                                    green: 0.22,
                                    blue: 0.38
                                )
                            )
                            .accessibilityLabel("License key")

                            Button {
                                if let pasted = UIPasteboard.general.string {
                                    keyText = pasted.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                }
                            } label: {
                                Label(
                                    "Paste",
                                    systemImage: "doc.on.clipboard"
                                )
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    paleBlue,
                                    in: RoundedRectangle(cornerRadius: 11)
                                )
                                .foregroundStyle(blue)
                            }
                        }
                        .padding(12)
                        .background(
                            .white,
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(blue.opacity(0.25), lineWidth: 1)
                        )

                        Button {
                            Task {
                                await license.activate(key: keyText)
                            }
                        } label: {
                            HStack(spacing: 9) {
                                if license.isVerifying {
                                    ProgressView()
                                        .tint(.white)
                                }

                                Text(
                                    license.isVerifying
                                        ? "Verifying..."
                                        : "Activate Key"
                                )
                                .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                blue.gradient,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .disabled(
                            license.isVerifying
                                || keyText.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ).isEmpty
                        )

                        if let message = license.message {
                            Text(message)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }
                    }
                    .padding(18)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(blue.opacity(0.13), lineWidth: 1)
                    )
                    .shadow(
                        color: blue.opacity(0.06),
                        radius: 15,
                        y: 6
                    )

                    VStack(spacing: 12) {
                        Text("Our Official Channel")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(blue)

                        Link(destination: whatsappGroup) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.circle.fill")
                                    .font(.system(size: 27))
                                    .foregroundStyle(
                                        Color(
                                            red: 0.10,
                                            green: 0.65,
                                            blue: 0.38
                                        )
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Join our WhatsApp group")
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(blue)

                                    Text("Official updates and announcements")
                                        .font(.system(size: 12))
                                        .foregroundStyle(blue.opacity(0.65))
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(blue)
                            }
                            .padding(14)
                            .background(
                                .white,
                                in: RoundedRectangle(cornerRadius: 15)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        blue.opacity(0.16),
                                        lineWidth: 1
                                    )
                            )
                        }

                        Link(destination: whatsappContact) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 27))
                                    .foregroundStyle(
                                        Color(
                                            red: 0.10,
                                            green: 0.65,
                                            blue: 0.38
                                        )
                                    )

                                Text("+92 300 9353079")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(blue)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(blue)
                            }
                            .padding(14)
                            .background(
                                .white,
                                in: RoundedRectangle(cornerRadius: 15)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        blue.opacity(0.16),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }

                    Text("MISBAH PENAL  •  Secure License Access")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(blue.opacity(0.55))
                        .padding(.top, 2)
                }
                .padding(20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(ColorScheme.light)
        .alert("Settings", isPresented: $showSettingsInfo) {
            Button("OK", role: ButtonRole.cancel) { }
        } message: {
            Text("MISBAH PENAL • Developer Shafay")
        }
    }
}
