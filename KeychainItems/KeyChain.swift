/*

  Copyright (c) 2016 David Spooner; see License.txt

  A simple abstraction for use of the generic password keychain.

  Note: I had expected that the objects returned by SecItemCopyMatching would need to
  be explicitly released, as was necessary in ObjC. However, use of Instruments shows
  no leaks; perhaps 'withUnsafeMutablePointer' performs some magic not made explicit
  in its documentation...

*/

import Foundation


public class KeyChain : NSObject
  {

    public let service: String


    public init(service id: String)
      {
        // Initialize a new instance with the given service identifier.

        assert(id != "", "invalid argument")

        service = id
      }


    public override convenience init()
      {
        // Initialize a new instance using the application bundle identifier of as service identifier.

        self.init(service: NSBundle.mainBundle().bundleIdentifier!)
      }


    public var keys: Set<String>
      {
        // Return the names of all keychain entries for the associated service.

        // Build a query to retrieve the attributes of all entries for our service.
        let query: NSDictionary = [
            kSecClass as NSString: kSecClassGenericPassword,
            kSecAttrService as NSString: service,
            kSecReturnAttributes as NSString: kCFBooleanTrue,
            kSecMatchLimit as NSString: kSecMatchLimitAll,
          ]

        // Perform the search, returning an empty list on failure.
        var result: AnyObject?
        let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, $0) }
        if status != errSecSuccess {
          assert(status == errSecItemNotFound, "SecItemCopyMatching returned \(status)")
          return []
        }

        // The result is a CFArray containing the attributes (as CFDictionary) of each
        // matching entry; return the corresponding set of keys, each given by the account
        // attribute.
        var set = Set<String>()
        for entry in result as! NSArray {
          let attrs = entry as! NSDictionary
          let key = attrs[kSecAttrAccount as NSString] as! String
          set.insert(key)
        }
        return set
      }


    public func dataForKey(key: String) -> NSData?
      {
        // Return the data associated with the given key.

        assert(key != "", "invalid argument")

        // Build a query to return the data for a single entry matching the given key.
        let query: NSDictionary = [
            kSecClass as NSString: kSecClassGenericPassword,
            kSecAttrService as NSString: service,
            kSecAttrAccount as NSString: key,
            kSecReturnData as NSString: kCFBooleanTrue,
            kSecMatchLimit as NSString: kSecMatchLimitOne,
          ]

        // Perform the search, returning nil on failure.
        var result: AnyObject?
        let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(query, $0) }
        if status != errSecSuccess {
          assert(status == errSecItemNotFound, "SecItemCopyMatching returned \(status)")
          return nil
        }

        // The result is CFData, return it.
        return result as! NSData
      }


    public func setData(data: NSData!, forKey key: String)
      {
        // Set the data for the given key, removing the entry if data is nil.

        assert(key != "", "invalid argument")

        // Build a query to return the data for a single entry matching the given key.
        let query: NSDictionary = [
            kSecClass as NSString: kSecClassGenericPassword,
            kSecAttrService as NSString: service,
            kSecAttrAccount as NSString: key,
            kSecReturnAttributes as NSString: kCFBooleanTrue,
            kSecMatchLimit as NSString: kSecMatchLimitOne,
          ]

        // Perform the search...
        var status = SecItemCopyMatching(query, nil)
        switch status {
          case errSecSuccess:
            // If successful then either update the data for the entry (viz. data != nil)
            // or delete the entry (viz. data == nil)
            let update: NSMutableDictionary = [
                kSecClass as NSString: kSecClassGenericPassword,
                kSecAttrService as NSString: service,
                kSecAttrAccount as NSString: key,
              ]
            if data != nil {
              status = SecItemUpdate(update, [kSecValueData as NSString: data])
              assert(status == errSecSuccess, "SecItemUpdate returned \(status)")
            }
            else {
              willChangeValueForKey("keys", withSetMutation: .MinusSetMutation, usingObjects: [key])
              status = SecItemDelete(update)
              assert(status == errSecSuccess, "SecItemDelete returned \(status)")
              didChangeValueForKey("keys", withSetMutation: .MinusSetMutation, usingObjects: [key])
            }
            break
          case errSecItemNotFound:
            // If there is no matching entry then create one, provided the given data is non-nil.
            if data != nil {
              willChangeValueForKey("keys", withSetMutation: .UnionSetMutation, usingObjects: [key])
              status = SecItemAdd([
                  kSecClass as NSString: kSecClassGenericPassword,
                  kSecAttrService as NSString: service,
                  kSecAttrAccount as NSString: key,
                  kSecValueData as NSString: data,
                ], nil)
              assert(status == errSecSuccess, "SecItemAdd returned \(status)")
              didChangeValueForKey("keys", withSetMutation: .UnionSetMutation, usingObjects: [key])
            }
            break
          default:
            assert(false, "SecItemCopyMatching returned \(status)")
        }
      }


    public func removeDataForKey(key: String)
      {
        // Remove the data for the given key.

        setData(nil, forKey: key)
      }


    public func removeAll()
      {
        // Remove all entries.

        for key in keys {
          setData(nil, forKey: key)
        }
      }

  }


public extension KeyChain
  {
    // Add methods to simplify storing and retrieving archived objects.

    public subscript(key: String) -> AnyObject?
      {
        get {
          guard let data = dataForKey(key) else { return nil }
          return NSKeyedUnarchiver.unarchiveObjectWithData(data)!
        }

        set(newObject) {
          if let object = newObject {
            setData(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
          }
          else {
            setData(nil, forKey: key)
          }
        }
      }

  }
