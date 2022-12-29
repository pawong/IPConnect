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
        do {
            let readData = try Data(contentsOf: archivePath())
            self.settings = try JSONDecoder().decode(Settings.self, from: readData)
        } catch {
            reset()
        }
        needsDisplay = true
    }

    func archive() {
        let jsonData = try! JSONEncoder().encode(self.settings)
        try! jsonData.write(to: archivePath())
        needsDisplay = true
    }

    func archivePath() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return URL(fileURLWithPath: paths[0].path + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String) + ".cfg")
    }

    func reset() {
        settings.showLocation = false
        settings.showExternalIP = false
        settings.useNotifications = false
        settings.useColorIcons = false
        archive()
    }
}

