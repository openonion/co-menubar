import Foundation

// Tails a log file and calls a callback with new lines
class LogTailer {
    private var fileHandle: FileHandle?
    private var timer: Timer?
    private var lastPosition: UInt64 = 0

    var onNewLines: ((String) -> Void)?

    func start(path: String) {
        let url = URL(fileURLWithPath: path)

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        fileHandle = handle

        // Seek to end
        lastPosition = handle.seekToEndOfFile()

        // Poll every 0.5 seconds for new content
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForNewContent()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        fileHandle?.closeFile()
        fileHandle = nil
    }

    private func checkForNewContent() {
        guard let handle = fileHandle else { return }

        let currentSize = handle.seekToEndOfFile()
        guard currentSize > lastPosition else { return }

        handle.seek(toFileOffset: lastPosition)
        let data = handle.readData(ofLength: Int(currentSize - lastPosition))
        lastPosition = currentSize

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            onNewLines?(text)
        }
    }
}
