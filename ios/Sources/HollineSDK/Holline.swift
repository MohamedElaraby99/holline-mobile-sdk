import UIKit
import WebKit

/// Opens a company's Holline call screen, or one of its meetings, inside the host app.
///
///     Holline.open(company: "your-slug", name: user.name, phone: user.phone)
///     Holline.joinMeeting(link, name: user.name)
///
/// The host app's Info.plist must have `NSMicrophoneUsageDescription`, and
/// `NSCameraUsageDescription` for companies with video calls.
@MainActor
public enum Holline {
    /// Where the call screen is served from.
    public static var baseURL = URL(string: "https://holline.cloud")!

    /// Called when the call moves on. Phases: flow, form, ringing, connected, ended,
    /// missed, callback, moved, mic-error. A meeting reports meeting-ready,
    /// meeting-lobby, meeting-joined, meeting-left, meeting-ended, meeting-removed,
    /// meeting-denied, meeting-full and meeting-missing.
    public static var onPhaseChanged: ((String) -> Void)?

    /// The current phase, or nil while the call screen isn't open.
    public private(set) static var phase: String?

    /// True while a call is ringing or connected, or a meeting is joined, even if the screen is hidden.
    public static var isInCall: Bool { phase == "ringing" || phase == "connected" || phase == "meeting-joined" }

    private static var controller: HollineViewController?

    /// Opens the call screen, or brings back the one that's already open. A call in
    /// progress is never replaced, even when the arguments differ.
    ///
    /// - Parameters:
    ///   - company: The company's slug, from its Holline call link.
    ///   - name: Fills in the customer's name on the form.
    ///   - phone: Fills in the customer's phone number on the form.
    ///   - source: Shown as the call's source in analytics.
    ///   - presenter: Presents the screen. Defaults to the app's topmost view controller.
    public static func open(
        company: String,
        name: String? = nil,
        phone: String? = nil,
        source: String = "mobile_app",
        from presenter: UIViewController? = nil
    ) {
        guard let url = callURL(company: company, name: name, phone: phone, source: source) else {
            assertionFailure("Holline: company must not be empty")
            return
        }
        show(url, from: presenter)
    }

    /// Opens a Holline meeting from its link (https://holline.cloud/m/abcd-efgh-ijkl,
    /// or /a/<company>/m/… when your app opens your company's links) or its bare code.
    /// Like a call, a meeting in progress is never replaced.
    ///
    /// - Parameters:
    ///   - link: The meeting link, as received (a Universal Link, a notification, a message).
    ///   - name: Fills in the person's name, so they only tap to join.
    ///   - presenter: Presents the screen. Defaults to the app's topmost view controller.
    /// - Returns: false when `link` isn't a Holline meeting link.
    @discardableResult
    public static func joinMeeting(_ link: String, name: String? = nil, from presenter: UIViewController? = nil) -> Bool {
        guard let url = meetingURL(link, name: name) else { return false }
        show(url, from: presenter)
        return true
    }

    /// Whether `link` is a Holline meeting link this SDK can open, for routing incoming links.
    public static func isMeetingLink(_ link: String) -> Bool { meetingPath(link) != nil }

    private static func show(_ url: URL, from presenter: UIViewController?) {
        if let current = controller, current.url != url, !isInCall {
            current.presentingViewController?.dismiss(animated: false)
            closed()
        }
        let screen = controller ?? HollineViewController(url: url, site: baseURL)
        controller = screen
        guard screen.presentingViewController == nil, let top = presenter ?? topViewController() else { return }
        top.present(screen, animated: true)
    }

    static func update(phase next: String) {
        guard next != phase else { return }
        phase = next
        controller?.syncCallState()
        onPhaseChanged?(next)
    }

    /// The screen was closed outside a call, so its page isn't needed any more.
    static func closed() {
        controller?.stop()
        controller = nil
        phase = nil
    }

    /// The meeting's path on the site, from a link to it or its bare code; nil if it isn't one.
    static func meetingPath(_ link: String) -> String? {
        let text = link.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = "[a-z]{4}-[a-z]{4}-[a-z]{4}"
        if text.lowercased().range(of: "^\(code)$", options: .regularExpression) != nil { return "/m/" + text.lowercased() }
        guard let url = URL(string: text),
              url.scheme?.lowercased() == baseURL.scheme?.lowercased(),
              url.host?.lowercased() == baseURL.host?.lowercased(),
              url.port == baseURL.port else { return nil }
        var path = url.path.lowercased()
        while path.hasSuffix("/") { path.removeLast() }
        return path.range(of: "^/(a/[a-z0-9-]+/)?m/\(code)$", options: .regularExpression) != nil ? path : nil
    }

    /// The person's name goes in the fragment, which is never sent to the server.
    static func meetingURL(_ link: String, name: String?) -> URL? {
        guard let path = meetingPath(link) else { return nil }
        var text = baseURL.absoluteString
        while text.hasSuffix("/") { text.removeLast() }
        text += path + "?sdk=1"
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            text += "#name=" + encode(name.trimmingCharacters(in: .whitespaces))
        }
        return URL(string: text)
    }

    /// Closes the screen when the page asks ("back to the app" after a meeting).
    static func closeRequested() {
        guard let screen = controller else { return }
        screen.presentingViewController?.dismiss(animated: true) { closed() }
    }

    /// The customer's details go in the fragment, which is never sent to the server.
    static func callURL(company: String, name: String?, phone: String?, source: String) -> URL? {
        let slug = company.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !slug.isEmpty else { return nil }
        var fragment: [String] = []
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            fragment.append("name=\(encode(name))")
        }
        if let phone, !phone.trimmingCharacters(in: .whitespaces).isEmpty {
            fragment.append("phone=\(encode(phone))")
        }
        var text = baseURL.absoluteString
        while text.hasSuffix("/") { text.removeLast() }
        text += "/c/\(encode(slug))?sdk=1&src=\(encode(source))"
        if !fragment.isEmpty { text += "#" + fragment.joined(separator: "&") }
        return URL(string: text)
    }

    private static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = (scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Keeps the page from retaining its controller through the content controller.
private final class PhaseHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame,
              let text = message.body as? String,
              let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["source"] as? String == "holline" else { return }
        if json["type"] as? String == "close" {
            Holline.closeRequested()
            return
        }
        guard json["type"] as? String == "phase", let phase = json["phase"] as? String else { return }
        Holline.update(phase: phase)
    }
}

/// The call page in a web view locked to the Holline site.
final class HollineViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private static let callBackground = UIColor(red: 0, green: 18 / 255, blue: 63 / 255, alpha: 1)
    private static let externalSchemes: Set<String> = ["http", "https", "tel", "mailto", "sms", "whatsapp", "maps"]

    let url: URL
    private let site: URL
    private lazy var webView = makeWebView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let offline = UIStackView()

    init(url: URL, site: URL) {
        self.url = url
        self.site = site
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        Holline.isInCall ? .lightContent : .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
        syncCallState()
        webView.load(URLRequest(url: url))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncCallState()
    }

    /// Ends the page, which disconnects anything still running in it.
    func stop() {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "holline")
        webView.removeFromSuperview()
    }

    private func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Without inline playback, the call audio and video don't play in the page.
        configuration.allowsInlineMediaPlayback = true
        // The ringback tone and the agent's voice start without a tap on them.
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(PhaseHandler(), name: "holline")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.scrollView.bounces = false
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    private func layoutViews() {
        let guide = view.safeAreaLayoutGuide
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        view.addSubview(spinner)

        let title = UILabel()
        title.text = "مفيش اتصال بالإنترنت"
        title.font = .preferredFont(forTextStyle: .headline)
        let retry = UIButton(type: .system)
        retry.setTitle("حاول تاني", for: .normal)
        retry.addAction(UIAction { [weak self] _ in self?.retry() }, for: .touchUpInside)
        offline.axis = .vertical
        offline.alignment = .center
        offline.spacing = 16
        offline.addArrangedSubview(title)
        offline.addArrangedSubview(retry)
        offline.isHidden = true
        offline.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offline)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 0.45)
        close.layer.cornerRadius = 18
        close.accessibilityLabel = "اقفل"
        close.addAction(UIAction { [weak self] _ in self?.leave() }, for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: guide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            offline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            offline.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            close.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            close.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            close.widthAnchor.constraint(equalToConstant: 36),
            close.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    /// Hides the screen. During a call the page stays alive, so the call keeps running.
    private func leave() {
        let keep = Holline.isInCall
        dismiss(animated: true) {
            if !keep { Holline.closed() }
        }
    }

    private func retry() {
        offline.isHidden = true
        spinner.startAnimating()
        webView.load(URLRequest(url: url))
    }

    private func showLoadFailure() {
        spinner.stopAnimating()
        offline.isHidden = false
    }

    /// Matches the screen lock and the system bars to whether a call is live.
    func syncCallState() {
        let inCall = Holline.isInCall
        UIApplication.shared.isIdleTimerDisabled = inCall
        view.backgroundColor = inCall ? Self.callBackground : .white
        setNeedsStatusBarAppearanceUpdate()
    }

    private func isSite(_ candidate: URL) -> Bool {
        candidate.scheme == site.scheme && candidate.host == site.host && candidate.port == site.port
    }

    private func openExternally(_ link: URL) {
        guard let scheme = link.scheme?.lowercased(), Self.externalSchemes.contains(scheme) else { return }
        UIApplication.shared.open(link)
    }

    // MARK: WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let target = action.request.url else {
            decisionHandler(.cancel)
            return
        }
        if action.targetFrame?.isMainFrame == false || isSite(target) {
            decisionHandler(.allow)
            return
        }
        openExternally(target)
        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor response: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if response.isForMainFrame, let http = response.response as? HTTPURLResponse, http.statusCode >= 500 {
            showLoadFailure()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        offline.isHidden = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { showLoadFailure() }
    }

    /// The saved call on the page puts the customer back in their place after the reload.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: WKUIDelegate

    /// A link for a new window, in case the navigation policy above didn't catch it.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for action: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let target = action.request.url {
            if isSite(target) { webView.load(action.request) } else { openExternally(target) }
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        let isSiteOrigin = origin.protocol == site.scheme && origin.host == site.host && origin.port == (site.port ?? 0)
        // iOS kills an app that uses the mic or camera without declaring why.
        guard isSiteOrigin, Self.declaresUsage(for: type) else {
            decisionHandler(.deny)
            return
        }
        decisionHandler(.grant)
    }

    private static func declaresUsage(for type: WKMediaCaptureType) -> Bool {
        let info = Bundle.main
        let mic = info.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
        let camera = info.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
        switch type {
        case .microphone: return mic
        case .camera: return camera
        case .cameraAndMicrophone: return mic && camera
        @unknown default: return false
        }
    }
}
