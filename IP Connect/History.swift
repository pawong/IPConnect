//
//  History.swift
//  IP Connect
//
//  Created by Paul Wong on 7/18/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Foundation
import Cocoa

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        //let data = data(using: String.Encoding.utf8)!
        //try data.append(fileURL: fileURL)
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            // file exist
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            let data = self.data(using: String.Encoding.utf8)!
            fileHandle.write(data)
        }
        else {
            // new file
            var data = "Current IP, Prior IP, Date\n".data(using: String.Encoding.utf8)!
            data.append(self.data(using: String.Encoding.utf8)!)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}

class History {

    class func getFileURL() -> URL {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
        let url = dir.appendingPathComponent("ip_history.txt")
        return url
    }

    class func reset() {
        let url = getFileURL()
        do {
            try FileManager.default.removeItem(at: url)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }

    class func append(_ newLine: String) {
        do {
            let url = getFileURL()
            try "\(newLine), \(Date())".appendLineToURL(fileURL: url as URL)
        }
        catch let error as NSError {
            print("Ooops! Could not write to file: \(error)")
        }
    }

    class func open() {
        NSWorkspace.shared.open(getFileURL())
    }

}
