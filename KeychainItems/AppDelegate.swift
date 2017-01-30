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


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
      {
        // If the keychain doesn't exist the add a few items.
        if keychain.keys.count == 0 {
          keychain["greeting"] = "heynow" as AnyObject?
          keychain["disposition"] = "sunny" as AnyObject?
          keychain["opinion"] = "controversial" as AnyObject?
        }

        // The window's rootViewController is a navigation controller presenting a table view of keychain items
        let listViewController = ListViewController(keychain: keychain)
        let navigationController = UINavigationController(rootViewController: listViewController)
        navigationController.navigationBar.isTranslucent = false
        window!.rootViewController = navigationController
        window!.makeKey()

        #if false
        // To check for leaks, schedule a timer to perform various keychain operations repeatedly
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(AppDelegate.timerDidFire(_:)), userInfo: nil, repeats: true)
        #endif

        return true
      }


    func timerDidFire(_ sender: Timer)
      {
        // Update a keychain entry
        keychain["uuid"] = UUID().uuidString as AnyObject?

        // Retrieve the keychain entries
        for key in keychain.keys {
          let _ = keychain[key]
        }
      }

  }
