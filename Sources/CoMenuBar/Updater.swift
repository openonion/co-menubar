import Foundation

struct Updater {
    static func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    // Checks the GitHub releases API for a newer version.
    // Calls back with (tag, releasePageURL) if a newer version exists, or (nil, nil).
    static func checkForUpdate(completion: @escaping (String?, URL?) -> Void) {
        let url = URL(string: "https://api.github.com/repos/openonion/co-menubar/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let tag = json["tag_name"] as? String,
                let htmlURL = json["html_url"] as? String,
                let releaseURL = URL(string: htmlURL),
                tag != currentVersion()
            else {
                completion(nil, nil)
                return
            }
            completion(tag, releaseURL)
        }.resume()
    }
}
