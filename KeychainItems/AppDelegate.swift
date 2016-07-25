/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
  {

    @IBOutlet var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
      {
        let rootViewController = ListViewController()

        let navigationController = UINavigationController(rootViewController:rootViewController)
        navigationController.navigationBar.translucent = false

        window!.rootViewController = navigationController
        window!.makeKeyWindow()

        return true
      }

  }
