/*

  Copyright (c) 2016 David Spooner; see License.txt

  A simple program demonstrating use of the KeyChain object.

*/

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
  {

    let keychain = KeyChain()

    @IBOutlet var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
      {
        // If the keychain doesn't exist the add a few items.
        if keychain.keys.count == 0 {
          keychain["greeting"] = "heynow"
          keychain["disposition"] = "sunny"
          keychain["opinion"] = "controversial"
        }

        // The window's rootViewController is a navigation controller presenting a table view of keychain items
        let listViewController = ListViewController(keychain: keychain)
        let navigationController = UINavigationController(rootViewController: listViewController)
        navigationController.navigationBar.translucent = false
        window!.rootViewController = navigationController
        window!.makeKeyWindow()

        #if false
        // To check for leaks, schedule a timer to perform various keychain operations repeatedly
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(AppDelegate.timerDidFire(_:)), userInfo: nil, repeats: true)
        #endif

        return true
      }


    func timerDidFire(sender: NSTimer)
      {
        // Update a keychain entry
        keychain["uuid"] = NSUUID().UUIDString

        // Retrieve the keychain entries
        for key in keychain.keys {
          let _ = keychain[key]
        }
      }

  }
