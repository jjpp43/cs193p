import Foundation

enum ConvertError: LocalizedError {
    case invalidVideoURL
    case cannotAccessSecurityScopedResource
    case exportSessionCreationFailed
    case exportFailed(String)
    case outputFileAlreadyExists
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidVideoURL:
            return "The selected file URL is invalid."
        case .cannotAccessSecurityScopedResource:
            return "Could not access the selected file. Try picking it again."
        case .exportSessionCreationFailed:
            return "Could not create an export session for this file."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .outputFileAlreadyExists:
            return "Output file already exists."
        case .unknown:
            return "Something went wrong."
        }
    }
}
