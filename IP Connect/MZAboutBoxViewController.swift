//
//  MZAboutBoxViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 2/10/18.
//  Copyright © 2018 Mazookie, LLC. All rights reserved.
//

import Cocoa


class MZAboutBoxViewController: NSViewController {

    @IBOutlet weak var appTitle: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet var appAcknowledgments: NSTextView!
    @IBOutlet weak var appCopyright: NSTextField!
    @IBOutlet weak var appIcon: NSImageView!

    @IBOutlet weak var helpView: NSView!
    @IBOutlet weak var aboutView: NSView!

    @IBOutlet var helpBox: NSTextView!
    @IBOutlet weak var helpButton: NSButton!

    var isHelpVisible: Bool!
    var macId: String?
    var text: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        isHelpVisible = false
        forceHelp(force: true)


        let infoDict = Bundle.main.infoDictionary
        appTitle.stringValue = (infoDict!["CFBundleExecutable"] as? String)!
        appVersion.stringValue = "Version \((infoDict!["CFBundleShortVersionString"] as? String)!) (Build \((infoDict!["CFBundleVersion"] as? String)!))"
        appCopyright.stringValue = (infoDict!["NSHumanReadableCopyright"] as? String)!
        appIcon.image = NSApp.applicationIconImage

        // Set help
        if let helpURL = Bundle.main.url(forResource: "help", withExtension: "rtfd") {
            helpBox.textStorage?.append(
                try! NSAttributedString(
                    url: helpURL,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil
                )
            )
        }

        // Set acknowledgements
        if let ackURL = Bundle.main.path(forResource: "acknowledgments", ofType: "txt") {
            try! appAcknowledgments.string = String(contentsOfFile: ackURL, encoding: String.Encoding.utf8)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.center()
        view.window?.level = .floating
    }
    
    func resizeWindow(size:(CGFloat,CGFloat)){
        view.window?.setFrame(NSRect(x:0,y:0,width:size.0,height:size.1), display: true)
    }
        
    @IBAction func toggleHelp(_ sender: Any?) {
        if isHelpVisible == true {
        // show about
            resizeWindow(size: (612, 312))
            isHelpVisible = false
            helpView.isHidden = true
            aboutView.isHidden = false
            helpButton.title = "Help"
        } else {
            // show help
            let screenSize = NSScreen.main!.frame
            let percent = CGFloat(0.80)
            resizeWindow(size: (612, screenSize.size.height * percent))
            view.window?.center()

            isHelpVisible = true
            helpView.isHidden = false
            aboutView.isHidden = true
            helpButton.title = "About"
        }
        view.window?.center()
    }

    @IBAction func visitWebsite(_ sender: Any?) {
        NSWorkspace.shared.open(NSURL(string: "https://github.com/pawong/IPConnect")! as URL)
    }

    func forceHelp(force: Bool) {
        if force == true {
            isHelpVisible = false
        } else {
            isHelpVisible = true
        }

        toggleHelp(nil)
    }

    func setMacId(newMacId: String) {
        macId = newMacId
    }

}

extension MZAboutBoxViewController {
    static func freshController() -> MZAboutBoxViewController {
        let storyboard = NSStoryboard(name: "MZAboutBox", bundle: nil)
        let identifier = "MZ AboutBox Controller"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? MZAboutBoxViewController else {
            fatalError("Why cant i find MZ AboutBox Controller? - Check MZAboutBox.storyboard")
        }
        return viewcontroller
    }
}
