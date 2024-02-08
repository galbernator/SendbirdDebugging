//
//  ChatFile.swift
//  SendbirdDebugging
//
//  Created by Steve Galbraith on 2/7/24.
//

import Foundation

struct ChatFile: Decodable {
    let name: String
    let urlString: String

    var type: FileType? {
        FileType.from(urlString)
    }

    var url: URL? {
        URL(string: urlString)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case urlString = "url"
    }

    func temporaryDirectoryURL(for data: Data) -> URL? {
        let temporaryFileDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryFileDirectoryURL.appendingPathComponent(name)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Failed to write file data to temporary file for sharing")
            return nil
        }
    }
}

enum FileType {
    case image(String)
    case file(URL)

    static func from(_ urlString: String?) -> FileType? {
        guard let urlString = urlString, let url = URL(string: urlString) else { return nil }

        switch url.lastPathComponent.lowercased() {
        case let path where path.hasSuffix("pdf"),
             let path where path.hasSuffix("txt"): return .file(url)
        case let path where path.hasSuffix("jpg"),
             let path where path.hasSuffix("jpeg"),
             let path where path.hasSuffix("png"): return .image(urlString)
        default: return nil
        }
    }

    var name: String {
        switch self {
        case .file: return "file"
        case .image: return "image"
        }
    }
}
