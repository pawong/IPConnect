//
//  MZNESettings.swift
//  NextEvent
//
//  Created by Paul Wong on 2/4/18.
//  Copyright © 2018 Mazookie, LLC. All rights reserved.
//

import Foundation

class Settings: NSObject {

    struct Settings: Codable {
        // persistant
        var showLocation: Bool = false
        var showExternalIP: Bool = false
        var useNotifications: Bool = false
        var useColorIcons: Bool = false
    }

    var settings: Settings = Settings()
    var needsDisplay: Bool = false

    override init() {
        super.init()
        unarchive()
    }

    func unarchive() {
        let fileManager = FileManager()
        let jsonDecoder = JSONDecoder()
        if fileManager.fileExists(atPath: archivePath()) {
            let jsonData = NSKeyedUnarchiver.unarchiveObject(withFile: archivePath()) as! Data
            do {
                try settings = jsonDecoder.decode(Settings.self, from: jsonData)
            } catch {
                reset()
                settings = Settings()
            }
        } else {
            settings = Settings()
        }
        needsDisplay = true
    }

    func archive() {
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(settings)
        NSKeyedArchiver.archiveRootObject(jsonData, toFile: archivePath())
        needsDisplay = true
    }

    func archivePath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].path + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String) + ".cfg"
    }

    func reset() {
        settings.showLocation = false
        settings.showExternalIP = false
        settings.useNotifications = false
        settings.useColorIcons = false
        archive()
    }
}

