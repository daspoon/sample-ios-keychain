/*

  Copyright (c) 2016 David Spooner; see License.txt

  Utility methods added to XCUIElement.

*/

import XCTest


extension XCUIElement
  {

    var window: XCUIElement!
      {
        // Return the application window.

        let windows = XCUIApplication().windows
        for i in 0 ..< windows.count {
          let window = windows.element(boundBy: i)
          if window.isHittable {
            return window
          }
        }
        return nil
      }


    var visible: Bool
      {
        // Determine whether or not the receiver is visible. Adapted from http://stackoverflow.com/a/33538255/6566144

        guard exists && isHittable else { return false }

        return !frame.isEmpty && window.frame.intersects(frame)
      }

  }

