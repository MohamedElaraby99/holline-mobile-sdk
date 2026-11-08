import React

@objc(HollineModule)
final class HollineModule: RCTEventEmitter {
    override static func requiresMainQueueSetup() -> Bool { true }

    override func supportedEvents() -> [String]! { ["hollinePhase"] }

    override func startObserving() {
        Task { @MainActor in
            Holline.onPhaseChanged = { [weak self] phase in
                self?.sendEvent(withName: "hollinePhase", body: phase)
            }
        }
    }

    override func stopObserving() {
        Task { @MainActor in
            Holline.onPhaseChanged = nil
        }
    }

    @objc(open:name:phone:source:baseUrl:resolve:reject:)
    func open(
        _ company: String,
        name: String?,
        phone: String?,
        source: String?,
        baseUrl: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task { @MainActor in
            if let baseUrl, let url = URL(string: baseUrl) { Holline.baseURL = url }
            Holline.open(company: company, name: name, phone: phone, source: source ?? "mobile_app")
            resolve(nil)
        }
    }

    @objc(joinMeeting:name:baseUrl:resolve:reject:)
    func joinMeeting(
        _ link: String,
        name: String?,
        baseUrl: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task { @MainActor in
            if let baseUrl, let url = URL(string: baseUrl) { Holline.baseURL = url }
            resolve(Holline.joinMeeting(link, name: name))
        }
    }

    @objc(isMeetingLink:baseUrl:resolve:reject:)
    func isMeetingLink(
        _ link: String,
        baseUrl: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task { @MainActor in
            if let baseUrl, let url = URL(string: baseUrl) { Holline.baseURL = url }
            resolve(Holline.isMeetingLink(link))
        }
    }

    @objc(isInCall:reject:)
    func isInCall(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        Task { @MainActor in
            resolve(Holline.isInCall)
        }
    }
}
