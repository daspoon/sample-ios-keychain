/*

  Copyright (c) 2016 David Spooner; see License.txt

  UI test cases for KeychainItems app

*/

import XCTest


class KeychainItemsUITests: XCTestCase
  {

    var app: XCUIApplication { return XCUIApplication(); }


    // XCTestCase

    override func setUp()
      {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        XCUIDevice.sharedDevice().orientation = .Portrait
      }
    

    // Auxiliary methods

    func addEntry(key: String, value: String, existing: Bool=false) -> XCUIElement
      {
        // A helper method to create an entry for the given key/value pair. The 'existing' argument indicates whether or not an entry is expected to exist for the given key and thus whether or not the creation attempt should fail with an alert.

        // First assert that a table cell for the specified entry exists iff expected.
        XCTAssert(app.tables.staticTexts[key].exists == existing)

        // Note the table cell count
        let tableCellCount = app.tables.cells.count

        // Navigate to the item addition view
        app.navigationBars["Items"].buttons["Add"].tap()

        // Locate the superview containing the key and value views
        let contentView = app.otherElements.containingType(.NavigationBar, identifier:"Item").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
        XCTAssert(contentView.exists)

        // Assign the specified key to the appropriate TextField
        let keyField = contentView.childrenMatchingType(.TextField).element
        XCTAssert(keyField.hittable)
        keyField.tap()
        keyField.typeText(key)

        // Assign the specified value to the appropriate TextView
        let valueView = contentView.childrenMatchingType(.TextView).element
        XCTAssert(valueView.hittable)
        valueView.tap()
        valueView.typeText(value)

        // Attempt to commit the change
        let itemNavigationBar = app.navigationBars["Item"]
        itemNavigationBar.buttons["Done"].tap()

        // Ensure the 'key exists' alert is present iff the entry is expected to exist; dismiss the alert if necessary
        let alertDismiss = app.alerts["Key Exists"].collectionViews.buttons["OK"]
        XCTAssert(alertDismiss.exists == existing)
        if existing {
          alertDismiss.tap()
        }

        // Navigate back to the table view
        itemNavigationBar.buttons["Items"].tap()

        // Ensure the table has the expected cell count and has a cell for the specified entry
        let entryCell = app.tables.staticTexts[key]
        XCTAssert(entryCell.exists)
        XCTAssert(app.tables.cells.count == tableCellCount + (existing ? 0 : 1))

        return entryCell
      }


    // Test cases

    func testEntryAddition()
      {
        // Generate a key for an entry which doesn't already exist in the table.
        let uniqueKey = NSUUID().UUIDString

        // Add an entry for that key
        addEntry(uniqueKey, value: "some secret")
      }


    func testMultipleEntryAddition()
      {
        // Generate a key for an entry which doesn't already exist in the table.
        let uniqueKey = NSUUID().UUIDString

        // Add an entry for that key
        addEntry(uniqueKey, value: "some secret", existing: false)

        // Attempt to add another entry with the same key.
        addEntry(uniqueKey, value: "another secret", existing: true)
      }


    func testShowDetail()
      {
        let uniqueKey = NSUUID().UUIDString
        let secretValue = NSUUID().UUIDString

        let entryCell = addEntry(uniqueKey, value: secretValue)

        // Navigate to the detail for the new entry
        entryCell.tap()

        // Locate the superview containing the key and value views
        let contentView = app.otherElements.containingType(.NavigationBar, identifier:"Item").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element

        // Ensure key field contains the expected value
        let keyField = contentView.childrenMatchingType(.TextField).element
        XCTAssert(keyField.visible == true)
        XCTAssert(keyField.value as? String == .Some(uniqueKey))

        // Ensure the value view is not visible
        let valueView = contentView.childrenMatchingType(.TextView).element
        XCTAssert(valueView.visible == false)

        // Tapping the show button reveals the text view with the expected vaue
        let showButton = app.buttons["SHOW"]
        showButton.tap()
        XCTAssert(valueView.visible)
        XCTAssert(valueView.value as? String == Optional.Some(secretValue))

        // Tapping the hide button hides the text view again
        let hideButton = app.buttons["HIDE"]
        hideButton.tap()
        XCTAssert(valueView.visible == false)

        // Navigate back to the table view
        app.navigationBars["Item"].buttons["Items"].tap()
      }

  }
