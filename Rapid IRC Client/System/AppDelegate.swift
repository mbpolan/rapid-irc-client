//
//  AppDelegate.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(viewModel: ContentViewModel.viewModel(from: Store.instance))

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Rapid IRC Client")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func connectToServer(_ sender: AnyObject) {
        NotificationCenter.default.post(name: .connectToServer, object: nil)
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connect_to_server")
    static let doConnectToServer = Notification.Name("do_connect_to_server")
    static let sendMessage = Notification.Name("send_message")
    static let joinedChannel = Notification.Name("joined_channel")
}


struct AppDelegate_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
