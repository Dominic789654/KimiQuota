import Cocoa
import Foundation

// MARK: - Models

struct QuotaData: Codable {
    let limit: Int
    let used: Int
    let remaining: Int
    let resetTime: String?
    
    enum CodingKeys: String, CodingKey {
        case limit, used, remaining
        case resetTime = "resetTime"
    }
}

struct UsageResponse: Codable {
    let usage: QuotaData?
    let limits: [LimitItem]?
}

struct LimitItem: Codable {
    let window: TimeWindow?
    let detail: QuotaData?
}

struct TimeWindow: Codable {
    let duration: Int
    let timeUnit: String
}

// MARK: - Quota Manager

@MainActor
class QuotaManager: ObservableObject {
    static let shared = QuotaManager()
    
    @Published var currentQuota: QuotaData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    private var credentialsPath: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kimi")
            .appendingPathComponent("credentials")
            .appendingPathComponent("kimi-code.json")
    }
    
    struct Credentials: Codable {
        let accessToken: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
    
    func startAutoRefresh() {
        // Initial fetch
        Task {
            await fetchQuota()
        }
        
        // Setup timer
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task {
                await self.fetchQuota()
            }
        }
    }
    
    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchQuota() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let credentials = try? loadCredentials() else {
                errorMessage = "未找到凭证，请先运行: kimi login"
                isLoading = false
                return
            }
            
            let data = try await fetchUsageData(token: credentials.accessToken)
            currentQuota = data.usage
            isLoading = false
            
            // Update menu bar title
            await MainActor.run {
                AppDelegate.shared?.updateStatusItem()
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func loadCredentials() throws -> Credentials {
        let data = try Data(contentsOf: credentialsPath)
        let decoder = JSONDecoder()
        return try decoder.decode(Credentials.self, from: data)
    }
    
    private func fetchUsageData(token: String) async throws -> UsageResponse {
        let url = URL(string: "https://api.kimi.com/coding/v1/usages")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "KimiQuota", code: 1, userInfo: [NSLocalizedDescriptionKey: "API 请求失败"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(UsageResponse.self, from: data)
    }
    
    var menuBarTitle: String {
        guard let quota = currentQuota else {
            return "⏳"
        }
        
        let remaining = quota.remaining
        let limit = quota.limit
        let percentage = limit > 0 ? Double(remaining) / Double(limit) : 0
        
        let icon: String
        if percentage >= 0.5 {
            icon = "🟢"
        } else if percentage >= 0.2 {
            icon = "🟡"
        } else {
            icon = "🔴"
        }
        
        return "\(icon) \(remaining)"
    }
    
    var statusText: String {
        guard let quota = currentQuota else {
            return "加载中..."
        }
        
        let percentage = quota.limit > 0 ? Double(quota.remaining) / Double(quota.limit) : 0
        if percentage >= 0.5 {
            return "状态: 充足"
        } else if percentage >= 0.2 {
            return "状态: 一般"
        } else {
            return "状态: 紧张"
        }
    }
    
    var resetTimeText: String? {
        guard let resetTime = currentQuota?.resetTime else {
            return nil
        }
        return formatResetTime(resetTime)
    }
    
    private func formatResetTime(_ isoString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds
            let simpleFormatter = ISO8601DateFormatter()
            simpleFormatter.formatOptions = [.withInternetDateTime]
            guard let simpleDate = simpleFormatter.date(from: isoString) else {
                return nil
            }
            return timeUntil(simpleDate)
        }
        
        return timeUntil(date)
    }
    
    private func timeUntil(_ date: Date) -> String {
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff <= 0 {
            return "即将重置"
        }
        
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        if days > 0 {
            return "\(days)天\(hours)小时后重置"
        } else if hours > 0 {
            return "\(hours)小时\(minutes)分钟后重置"
        } else {
            return "\(minutes)分钟后重置"
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        setupStatusItem()
        setupMenu()
        
        // Start auto refresh
        QuotaManager.shared.startAutoRefresh()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        QuotaManager.shared.stopAutoRefresh()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⏳"
        statusItem?.button?.action = #selector(showMenu)
        statusItem?.button?.target = self
    }
    
    func setupMenu() {
        menu = NSMenu()
        
        // Status
        let statusItem = NSMenuItem(title: "🟢 加载中...", action: nil, keyEquivalent: "")
        statusItem.tag = 1
        menu?.addItem(statusItem)
        
        // Remaining
        let remainingItem = NSMenuItem(title: "💚 剩余: --", action: nil, keyEquivalent: "")
        remainingItem.tag = 2
        menu?.addItem(remainingItem)
        
        // Used
        let usedItem = NSMenuItem(title: "📊 已用: --", action: nil, keyEquivalent: "")
        usedItem.tag = 3
        menu?.addItem(usedItem)
        
        // Reset time
        let resetItem = NSMenuItem(title: "⏰ --", action: nil, keyEquivalent: "")
        resetItem.tag = 4
        menu?.addItem(resetItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Refresh
        let refreshItem = NSMenuItem(title: "🔄 立即刷新", action: #selector(refreshQuota), keyEquivalent: "r")
        refreshItem.target = self
        menu?.addItem(refreshItem)
        
        // Auto refresh toggle
        let autoRefreshItem = NSMenuItem(title: "✅ 自动刷新", action: #selector(toggleAutoRefresh), keyEquivalent: "")
        autoRefreshItem.tag = 5
        autoRefreshItem.target = self
        menu?.addItem(autoRefreshItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Open Kimi
        let openItem = NSMenuItem(title: "🌙 打开 Kimi", action: #selector(openKimi), keyEquivalent: "")
        openItem.target = self
        menu?.addItem(openItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "👋 退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        // Setup KVO
        Task {
            await observeQuotaChanges()
        }
    }
    
    func observeQuotaChanges() async {
        // Initial update
        updateMenuItems()
        
        // Use timer to periodically update menu
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateMenuItems()
            }
        }
    }
    
    func updateMenuItems() {
        let manager = QuotaManager.shared
        
        // Update status item title
        statusItem?.button?.title = manager.menuBarTitle
        
        // Update menu items
        if let statusMenuItem = menu?.item(withTag: 1) {
            statusMenuItem.title = manager.statusText
        }
        
        if let remainingMenuItem = menu?.item(withTag: 2) {
            if let quota = manager.currentQuota {
                remainingMenuItem.title = "💚 剩余: \(quota.remaining) / \(quota.limit)"
            } else {
                remainingMenuItem.title = "💚 剩余: --"
            }
        }
        
        if let usedMenuItem = menu?.item(withTag: 3) {
            if let quota = manager.currentQuota {
                let percentage = quota.limit > 0 ? (100 - Int(Double(quota.remaining) / Double(quota.limit) * 100)) : 0
                usedMenuItem.title = "📊 已用: \(quota.used) (\(percentage)%)"
            } else {
                usedMenuItem.title = "📊 已用: --"
            }
        }
        
        if let resetMenuItem = menu?.item(withTag: 4) {
            if let resetTime = manager.resetTimeText {
                resetMenuItem.title = "⏰ \(resetTime)"
                resetMenuItem.isHidden = false
            } else {
                resetMenuItem.isHidden = true
            }
        }
        
        if let autoRefreshMenuItem = menu?.item(withTag: 5) {
            autoRefreshMenuItem.title = "✅ 自动刷新"
        }
    }
    
    func updateStatusItem() {
        statusItem?.button?.title = QuotaManager.shared.menuBarTitle
    }
    
    @objc func showMenu() {
        guard let menu = menu, let button = statusItem?.button else { return }
        
        // Update menu items before showing
        updateMenuItems()
        
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY), in: button)
    }
    
    @objc func refreshQuota() {
        Task {
            await QuotaManager.shared.fetchQuota()
        }
    }
    
    @objc func toggleAutoRefresh() {
        // Toggle logic here
    }
    
    @objc func openKimi() {
        NSWorkspace.shared.open(URL(string: "https://kimi.com")!)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Menu bar only app
app.run()
