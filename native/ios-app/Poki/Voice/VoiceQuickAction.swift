import Foundation

/// A deliberately small, exact-match low-latency route for reversible phone
/// navigation. Multi-step requests always go through the configured model.
/// The route never taps a purchase, sends a message or changes phone data.
struct VoiceQuickAction: Equatable {
    let actions: [[String: String]]
    let response: String

    static func match(_ utterance: String) -> VoiceQuickAction? {
        let spoken = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "。！？.!?，, "))
        let normalized = spoken.replacingOccurrences(of: " ", with: "")
        let app: (bundle: String, name: String)? = switch normalized {
        case "打开微信": ("com.tencent.xin", "微信")
        case "打开备忘录": ("com.apple.mobilenotes", "备忘录")
        case "打开设置": ("com.apple.Preferences", "设置")
        case "打开相机": ("com.apple.camera", "相机")
        case "打开Safari", "打开浏览器": ("com.apple.mobilesafari", "Safari")
        case "打开短信": ("com.apple.MobileSMS", "短信")
        default: nil
        }
        if let app {
            return VoiceQuickAction(actions: [["launch": app.bundle]], response: "已打开\(app.name)")
        }
        switch normalized {
        case "返回", "后退":
            return VoiceQuickAction(actions: [["back": "true"]], response: "已返回")
        case "回主屏幕", "返回主屏幕", "回到桌面":
            return VoiceQuickAction(actions: [["button": "home"]], response: "已返回主屏幕")
        default: return nil
        }
    }

    var toolArguments: String? {
        // PokiCore's do tool accepts boolean `back`, not a string.
        let values: [[String: Any]] = actions.map { item in
            if item["back"] == "true" { return ["back": true] }
            return item.mapValues { $0 as Any }
        }
        guard JSONSerialization.isValidJSONObject(["actions": values]),
              let data = try? JSONSerialization.data(withJSONObject: ["actions": values], options: [.sortedKeys]) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
}
