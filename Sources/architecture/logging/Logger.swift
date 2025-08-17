import Foundation

struct Logger {
    private static let resetColor = "\u{001B}[0;39m"
    private static let infoColor = "\u{001B}[0;34m"
    private static let errorColor = "\u{001B}[0;31m"
    private static let timestampColor = "\u{001B}[0;96m"

    static func messageWithTimestamp(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeStamp: String = "[\(dateFormatter.string(from: Date()))] - "

        guard !message.isEmpty else { return }

        print("\(timestampColor)\(timeStamp) \(message)")
    }

    static func logInfo(_ message: String) {
        messageWithTimestamp("\(infoColor)Info: \(resetColor)\(message)")
    }

    static func logParseError(_ error: ParseError) {
        messageWithTimestamp("\(errorColor)Error: \(resetColor)\(error.localizedDescription)")
    }
}
