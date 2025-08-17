enum ParseError: Error {
    case invalidFilePath(String)
    case fileNotFound(String)
    case jsonParsingError(String)
    case unknownError(String)

    var localizedDescription: String {
        switch self {
        case .invalidFilePath(let path):
            return "Invalid file path: \(path)"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .jsonParsingError(let message):
            return "JSON parsing error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}