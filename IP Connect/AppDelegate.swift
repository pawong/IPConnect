//
//  AppDelegate.swift
//  IP Connect
//
//  Created by Paul Wong on 3/26/18.
//  Copyright © 2018 Mazookie, LLC. All rights reserved.
//

import Cocoa
import MapKit
import CoreLocation


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let timeInterval: Double = 60

    var timer: Timer!
    var preferenceController: NSWindowController!
    var aboutBoxController: NSWindowController!
    var aboutBoxView: MZAboutBoxViewController!
    var settings: Settings!

    var network = Network()
    var reachability: Reachability?
    var notification: NSUserNotification?
    
    var mapImage: NSImage? = nil
    var latitude: CLLocationDegrees? = nil
    var longitude: CLLocationDegrees? = nil
    var locationManager:CLLocationManager!
    
    let mapView = MKMapView(frame: CGRect(x:0, y:0, width:320, height:180))


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // load settings
        settings = Settings()
        processCommandLine()
        
        if settings.settings.showLocation == true {
            // get location
            determineMyCurrentLocation()
            setMapImage()
        }

        // get ip as fast as you can
        network.getPublicIPWait()

        statusItem.button?.image = settings.settings.useColorIcons
            ? NSImage(named:"StatusBarGray") : NSImage(named:"StatusBarChecking")
        startHost(at: 1)

        // Last things to do
        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(fireTimer(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // not needed for MacOS
        //if #available(OSX 10.15, *) {
        //    locationManager.requestAlwaysAuthorization()
        //} else {
        //    // Fallback on earlier versions
        //}
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.requestLocation() // 10.14 or newer
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes or more.
        locationManager.stopUpdatingLocation()
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
        latitude = userLocation.coordinate.latitude
        longitude = userLocation.coordinate.longitude
        setMapImage()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error: \(error)")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        stopNotifier()
    }

    @objc func fireTimer(_ sender: Any?) {
        update(false)
    }

    func startHost(at index: Int) {
        setupReachability("8.8.8.4")
        startNotifier()
    }

    func setupReachability(_ hostName: String?) {
        let reach: Reachability?
        if let hostName = hostName {
            reach = Reachability(hostname: hostName)
        } else {
            reach = Reachability()
        }
        reachability = reach

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged(_:)),
            name: .reachabilityChanged,
            object: reachability
        )
    }

    func startNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            let alert = NSAlert()
            alert.informativeText = "Please try to restart IP Connect, if issue persists please contact Mazookie."
            alert.messageText = "Unable to monitor network"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    func stopNotifier() {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
        reachability = nil
    }

    @objc func reachabilityChanged(_ note: Notification) {
        print("Reachability changed, \(reachability!.connection)...")
        reachability = (note.object as! Reachability)
        network.getPublicIPWait()
        if settings.settings.useNotifications {
            notify()
        }
        update(false)
    }

    func notify() {

        if notification != nil {
            NSUserNotificationCenter.default.removeDeliveredNotification(notification!)
        }

        var info: String

        if reachability?.connection == Reachability.Connection.none {
            info = "System has lost network connection."
        } else if network.externalIP == "N/A" {
            info = "System has no internet connection."
        } else {
            info = "System internet connection is now working."
        }

        notification = NSUserNotification()
        notification?.informativeText = info
        notification?.soundName = NSUserNotificationDefaultSoundName
        let center = NSUserNotificationCenter.default
        center.deliver(notification!)
    }

    func update(_ force: Bool) {
        print("Updating (force == \(force)), \(reachability!.connection)...")
        
        if force {
            if settings.settings.showLocation == true {
                locationManager.startUpdatingLocation()
            }
            network.getPublicIPWait()
        } else {
            network.getPublicIPNoWait()
            if settings.settings.showLocation == true && mapImage == nil {
                locationManager.startUpdatingLocation()
            }
            if network.getHasIpChanged() {
                network.setHasIpChanged(false)
            }
        }
        
        if reachability?.connection == Reachability.Connection.none {
            statusItem.button?.image = settings.settings.useColorIcons ?
                NSImage(named:"StatusBarRed") : NSImage(named:"StatusBarNotConnected")
        } else if reachability?.connection == Reachability.Connection.wifi && network.externalIP != "N/A" {
            statusItem.button?.image = settings.settings.useColorIcons
                ? NSImage(named:"StatusBarGreen") : NSImage(named:"StatusBarConnected")
        } else if reachability?.connection == Reachability.Connection.cellular && network.externalIP != "N/A" {
            statusItem.button?.image = settings.settings.useColorIcons
                ? NSImage(named:"StatusBarBlue") : NSImage(named:"StatusBarCell")
        } else {
            statusItem.button?.image = settings.settings.useColorIcons
                ? NSImage(named:"StatusBarOrange") : NSImage(named:"StatusBarWarning")
        }
        if settings.settings.showExternalIP == true {
            statusItem.button?.attributedTitle = NSAttributedString(
                string:  network.externalIP,
                attributes: [NSAttributedString.Key.font:  NSFont(name: "Helvetica Neue", size: 12)!]
            )
        } else {
            statusItem.button?.attributedTitle = NSAttributedString()
        }
        
        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let myAttribute = [NSAttributedString.Key.font: NSFont(name: "Andale Mono", size: 14.0)!]

        let hostnameMenuItem = NSMenuItem(title: "Hostname", action: #selector(AppDelegate.doNothing(_:)), keyEquivalent: "")
        hostnameMenuItem.isEnabled = false
        menu.addItem(hostnameMenuItem)

        let nameMenuItem = NSMenuItem(title: "", action: #selector(AppDelegate.copyTitle(_:)), keyEquivalent: "")
        nameMenuItem.indentationLevel = 1
        nameMenuItem.attributedTitle = NSAttributedString(string: Host.current().localizedName ?? "", attributes: myAttribute)
        menu.addItem(nameMenuItem)
        menu.addItem(NSMenuItem.separator())

        let externalMenuItem = NSMenuItem(title: "External", action: #selector(AppDelegate.doNothing(_:)), keyEquivalent: "")
        externalMenuItem.isEnabled = false
        menu.addItem(externalMenuItem)

        let externalIPMenuItem = NSMenuItem(title: "", action: #selector(AppDelegate.copyIp(_:)), keyEquivalent: "")
        externalIPMenuItem.indentationLevel = 1
        externalIPMenuItem.attributedTitle = NSAttributedString(string: network.externalIP, attributes: myAttribute)
        menu.addItem(externalIPMenuItem)
        
        if settings.settings.showLocation == true && mapImage != nil {
            let locationMenuItem = NSMenuItem(title: "", action: #selector(AppDelegate.openMaps(_:)), keyEquivalent: "")
            locationMenuItem.indentationLevel = 1
            locationMenuItem.image = mapImage
            menu.addItem(locationMenuItem)
        }
        
        menu.addItem(NSMenuItem.separator())

        let internalMenuItem = NSMenuItem(title: "Internal", action: #selector(AppDelegate.doNothing(_:)), keyEquivalent: "")
        internalMenuItem.isEnabled = false
        menu.addItem(internalMenuItem)

        for interface in Network().getIFAddresses(false) {
            var internalIP = NSMenuItem(title: "", action: #selector(AppDelegate.doNothing(_:)), keyEquivalent: "")
            internalIP.indentationLevel = 1
            internalIP.attributedTitle = NSAttributedString(
                string: "\(interface["type"]!) (\(interface["name"]!)):",
                attributes: myAttribute
            )
            menu.addItem(internalIP)
            internalIP = NSMenuItem(title: "", action: #selector(AppDelegate.copyTitle(_:)), keyEquivalent: "")
            internalIP.indentationLevel = 3
            internalIP.attributedTitle = NSAttributedString(
                string: "\(interface["ip_address"]!)",
                attributes: myAttribute
            )
            menu.addItem(internalIP)

            internalIP = NSMenuItem(title: "", action: #selector(AppDelegate.copyTitle(_:)), keyEquivalent: "")
            internalIP.indentationLevel = 3
            internalIP.attributedTitle = NSAttributedString(
                string: "\(interface["mac_address"]!)",
                attributes: myAttribute
            )
            menu.addItem(internalIP)
        }

        menu.addItem(NSMenuItem.separator())
        var showmenu = NSMenuItem(title: "Show External IP", action: #selector(AppDelegate.showExternalIP(_:)), keyEquivalent: "s")
        if settings.settings.showExternalIP == true {
            showmenu.state = NSControl.StateValue.on
        } else {
            showmenu.state = NSControl.StateValue.off
        }
        menu.addItem(showmenu)
        showmenu = NSMenuItem(title: "Use color icons", action: #selector(AppDelegate.useColorIcons(_:)), keyEquivalent: "c")
        if settings.settings.useColorIcons == true {
            showmenu.state = NSControl.StateValue.on
        } else {
            showmenu.state = NSControl.StateValue.off
        }
        menu.addItem(showmenu)
        showmenu = NSMenuItem(title: "Use notifications ", action: #selector(AppDelegate.useNotifications(_:)), keyEquivalent: "n")
        if settings.settings.useNotifications == true {
            showmenu.state = NSControl.StateValue.on
        } else {
            showmenu.state = NSControl.StateValue.off
        }
        menu.addItem(showmenu)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About...", action: #selector(AppDelegate.openAbout(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(AppDelegate.refresh(_:)), keyEquivalent: "r"))

        let historyMenu = NSMenu()
        historyMenu.autoenablesItems = false
        historyMenu.addItem(NSMenuItem(title: "Show", action: #selector(AppDelegate.showHistory(_:)), keyEquivalent: ""))
        historyMenu.addItem(NSMenuItem.separator())
        historyMenu.addItem(NSMenuItem(title: "Clear", action: #selector(AppDelegate.clearHistory(_:)), keyEquivalent: ""))

        let historyItem = NSMenuItem()
        historyItem.title = "History"
        menu.addItem(historyItem)
        menu.setSubmenu(historyMenu, for: historyItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Network Preferences...", action: #selector(AppDelegate.openNetworkPreferences(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func setMapImage() {
        let pin = NSImage(named:"StatusBarOrange")
        print("Getting map image")
        
        if (latitude != nil) && (latitude != nil) {
            
            let current_location = CLLocationCoordinate2DMake(latitude!, longitude!)
            var mapRegion = MKCoordinateRegion()
            //var mapView = MKMapView(frame: CGRect(x:0, y:0, width:320, height:180))
            
            // Set size
            let mapRegionSpan = 0.2
            mapRegion.center = current_location
            mapRegion.span.latitudeDelta = mapRegionSpan
            mapRegion.span.longitudeDelta = mapRegionSpan
            mapView.setRegion(mapRegion, animated: true)

            // Create a map annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = current_location
            annotation.title = "Here"
            annotation.subtitle = "Your current Public IP location"
            mapView.addAnnotation(annotation)

            let options = MKMapSnapshotter.Options()
            options.region = mapView.region;
            options.size = mapView.frame.size;
            let mapSnapshotter = MKMapSnapshotter(options: options)

            mapSnapshotter.start { (snapshot, error) -> Void in
                if error != nil {
                    self.mapImage = nil
                    print("Unable to create a map snapshot.")
                } else if let snapshot = snapshot {
                    self.mapImage = nil
                    self.mapImage = snapshot.image
                    self.mapImage!.lockFocus()
                    let visibleRect = CGRect(origin: CGPoint.zero, size: snapshot.image.size)
                    for annotation in self.mapView.annotations {
                        var point = snapshot.point(for: annotation.coordinate)
                        if visibleRect.contains(point) {
                            point.x = point.x - (pin!.size.width / 2)
                            point.y = point.y - (pin!.size.height / 2)
                            pin!.draw(at: point, from: CGRect(origin: CGPoint.zero, size: snapshot.image.size), operation: .sourceAtop, fraction: 1.0)
                        }
                    }
                    self.mapImage!.unlockFocus()
                    self.constructMenu()
                }
            }
            
        } else {
            print("Unable to get map image.")
        }
    }


    @objc func refresh(_ sender: Any?) {
        update(true)
    }

    @objc func showHistory(_ sender: Any?) {
        History.open()
    }

    @objc func clearHistory(_ sender: Any?) {
        History.reset()
        network.priorIP = "None"
        update(true)
    }

    @objc func openNetworkPreferences(_ sender: Any?) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Network.prefPane")
    }

    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    @objc func copyIp(_ sender: Any?) {
        let mi = sender as! NSMenuItem
        let matched = matches(for: "\\b[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}", in: mi.title)
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(matched[0], forType: NSPasteboard.PasteboardType.string)
        print("Copying \(matched[0]) to the clipboard...")
    }

    @objc func copyName(_ sender: Any?) {
        let mi = sender as! NSMenuItem
        let fullArr : [String] = mi.title.components(separatedBy: ": ")
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(fullArr[1], forType: NSPasteboard.PasteboardType.string)
        print("Copying \(fullArr[1]) to the clipboard...")
    }

    @objc func copyTitle(_ sender: Any?) {
        let mi = sender as! NSMenuItem
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(mi.title, forType: NSPasteboard.PasteboardType.string)
        print("Copying \(mi.title) to the clipboard...")
    }

    @objc func openMaps(_ sender: Any?) {
        _ = sender as! NSMenuItem
        let coordinate = CLLocationCoordinate2DMake(latitude ?? 45.5051, longitude ?? -0122.6750)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = "You are here!"
        mapItem.openInMaps(launchOptions: nil)
        print("Opening maps at (\(latitude ?? 0),\(longitude ?? 0))...")
    }

    @objc func doNothing(_ sender: Any?) {
    }

    @objc func showExternalIP(_ sender: Any?) {
        settings.settings.showExternalIP = !settings.settings.showExternalIP
        settings.archive()
        update(true)
    }

    @objc func useNotifications(_ sender: Any?) {
        settings.settings.useNotifications = !settings.settings.useNotifications
        settings.archive()
        update(true)
    }

    @objc func useColorIcons(_ sender: Any?) {
        settings.settings.useColorIcons = !settings.settings.useColorIcons
        settings.archive()
        update(true)
    }

    @objc func quit(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    @IBAction func openAbout(_ sender: Any?) {
        if aboutBoxController == nil {
            let mainStoryboard = NSStoryboard.init(name: "MZAboutBox", bundle: nil)
            aboutBoxController = (mainStoryboard.instantiateController(
                withIdentifier: "MZ About Box") as! NSWindowController)
            aboutBoxView = (mainStoryboard.instantiateController(
                withIdentifier: "MZ AboutBox Controller"
                ) as! MZAboutBoxViewController)
            aboutBoxController.contentViewController = aboutBoxView
            aboutBoxView.setMacId(newMacId: "id1368972441")
        }
        aboutBoxController.showWindow(self)
        aboutBoxController.window?.makeKeyAndOrderFront(self)
        aboutBoxView.forceHelp(force: false)
        NSApp.activate(ignoringOtherApps: true)
    }

    func processCommandLine() {
        let arguments = ProcessInfo.processInfo.arguments
        // reset takes takes priority
        for i in 0..<arguments.count {
            if (arguments[i] == "-R") {
                settings.reset()
                print("Reset configuration.")
            }
        }
        // now handle the rest
        for i in 0..<arguments.count {
            switch arguments[i] {
                case "-L:1":
                    settings.settings.showLocation = true
                    settings.archive()
                    print("Enable location services.")
                case "-L:0":
                    settings.settings.showLocation = false
                    settings.archive()
                    print("Disable location services.")
                case "-R":
                    print("Reset configuration, already handled.")
                default:
                    print("Unhandled argument: \(arguments[i])")
            }
        }
    }
}

