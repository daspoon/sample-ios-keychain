/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import XCTest


// Convenience methods for testing

extension KeyChain
  {

    public var keysAndObjects: [String: NSObject]
      {
        // Return the keychain content as a dictionary subject to comparison...

        var result: [String: NSObject] = [:]
        for key in keys {
          guard let value = self[key] as? NSObject else { fatalError("no object value for key: \(key)") }
          result[key] = value
        }
        return result
      }

  }


class KeychainItemsTests: XCTestCase
  {

    func testEmpty()
      {
        // Ensure that accessing a non-existent key results in nil

        let keychain = KeyChain()

        keychain.removeAll()

        XCTAssert(keychain["whatever"] == nil)
      }


    func testMultipleInsertionAndRemoval()
      {
        // Add and remove multiple entries, using a dictionary to maintain the expected keychain content.

        let keychain = KeyChain()

        keychain.removeAll()

        // Populate the keychain and dictionary
        var dict: [String: NSObject] = [:]
        for i in 0 ..< 10 {
          let key = "\(i)"
          let value = NSNumber(integer: i)
          keychain[key] = value
          XCTAssert(keychain[key] as! NSNumber == value)
          dict[key] = value
        }

        // Ensure both have the same sorted list of keys
        XCTAssert(keychain.keys.sort() == dict.keys.sort())

        // Iteratively remove elements, ensuring the contents remain equal
        for i in 0 ..< 10 {
          XCTAssert(keychain.keysAndObjects == dict)
          let key = "\(i)"
          keychain[key] = nil
          XCTAssert(keychain[key] == nil)
          dict.removeValueForKey(key)
        }

        XCTAssert(keychain.keys == [] && Array(dict.keys) == [])
      }


    func testRepeatedUpdate()
      {
        // Ensure that repeatedly updating an entry does not result in multiple keys

        let keychain = KeyChain()

        keychain.removeAll()
        XCTAssert(keychain.keys == [])

        for _ in 0 ..< 20 {
          let uuid = NSUUID().UUIDString
          keychain["uuid"] = uuid
          XCTAssert(keychain["uuid"] as! String == uuid)
        }

        XCTAssert(keychain.keys == ["uuid"])
      }

  }
