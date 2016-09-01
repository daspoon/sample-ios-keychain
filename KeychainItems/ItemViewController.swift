/*

  Copyright (c) 2016 David Spooner; see License.txt

  A simple UIViewController to display and edit a keychain item.

*/

import UIKit
import LocalAuthentication


// Disable authentication (via the Testing configuration) while running UI tests
#if TESTING
let enableAuthentication = false
#else
let enableAuthentication = true
#endif


class ItemViewController : UIViewController
  {

    enum Mode
      {
        // Possible modes of interaction...
        case None
          // Item value is not visible.
        case View
          // Item value is visible, but not editable.
        case Edit
          // Editing an existing item.
        case Create
          // Creating a new item.
      }


    let keychain: KeyChain
    var key: String
    var mode: Mode


    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var keyTextField: UITextField!
      // Present the item key

    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var valueTextView: UITextView!
      // Present the item value; conditionally visible

    @IBOutlet var showButton: UIButton!
      // Toggle visibility of value views


    init(keychain kc: KeyChain, key k: String? = nil)
      {
        keychain = kc
        key = k ?? ""
        mode = k == nil ? .Create : .None

        super.init(nibName: "ItemViewController", bundle: nil)

        title = NSLocalizedString("ITEM", comment:"ItemViewController title")

        editing = mode == .Edit || mode == .Create

        // Register to observe the application losing foreground status
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
      }


    deinit
      {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
      }


    func show(sender: AnyObject?)
      {
        // The target of the show/hide button.

        // This can't happen while editing since the button is not visible.
        assert(!editing, "unexpected state")

        if mode == .None {
          authenticateWithContinuation {
            self.valueTextView.text = self.keychain[self.key] as! String
            self.mode = .View
            self.modeDidChange()
          }
        }
        else {
          mode = .None
          modeDidChange()
        }
      }


    func edit(sender: AnyObject?)
      {
        // The action of the edit navbar button.

        assert(!editing, "invalid state")

        authenticateWithContinuation {
          self.mode = .Edit
          self.setEditing(true, animated: true)
        }
      }


    func done(sender: AnyObject?)
      {
        // The action of the done navbar button.

        assert(editing, "invalid state")

        // Get the content of the key field, stripped of enclosing whitespace
        let newKey = keyTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) ?? ""

        // Ensure the new key is not empty
        guard newKey != "" else { return presentAlertWithTitle("KEY REQUIRED", message: "PLEASE PROVIDE A KEY FOR THIS ENTRY") }

        // If the key has changed then some extra validation and cleanup is required...
        if newKey != key {
          // Ensure the specified key does not already exist
          guard keychain[newKey] == nil else { return presentAlertWithTitle("KEY EXISTS", message: "AN ENTRY FOR THIS KEY ALREADY EXISTS") }
          // Remove the old entry, if any
          if key != "" {
            keychain[key] = nil
          }
          // Update our key
          key = newKey
        }

        // Add or update the new entry
        keychain[key] = valueTextView.text

        // Revert to viewable state after editing.
        mode = .View

        setEditing(false, animated: true)
      }


    func authenticateWithContinuation(continuation: () -> Void)
      {
        // Authenticate using biometrices, or by falling-back to passcode if necessary.
        // If successful, execute the given block on the main thread; otherwise report
        // an error (if the request was not cancelled).

        // For modes other than None just execute the completion and return, because we must
        // already have authenticated in order to present the value. Note that authentication
        // is not required for entry creation.
        guard mode == .None else { continuation(); return }

        // Skip authentication while testing, since those apis aren't UI-testable.
        guard enableAuthentication else { continuation(); return }

        let context = LAContext()
        let reason = NSLocalizedString("AUTHENTICATE TO REVEAL KEYCHAIN ITEM", comment: "Authentication reason")

        var done = false
        for policy in [LAPolicy.DeviceOwnerAuthenticationWithBiometrics, .DeviceOwnerAuthentication] {
          context.evaluatePolicy(policy, localizedReason: reason)
            { (success, error) in
                if success {
                  dispatch_async(dispatch_get_main_queue(), continuation)
                  done = true
                }
                else {
                  switch LAError(rawValue: error!.code)! {
                    case .UserFallback, .TouchIDNotAvailable, .TouchIDNotEnrolled, .TouchIDLockout, .SystemCancel :
                      // Keep trying...
                      break
                    case .UserCancel :
                      // The user has cancelled the request; stop trying.
                      done = true
                    case .PasscodeNotSet :
                      // No passcode required; succeed.
                      dispatch_async(dispatch_get_main_queue(), continuation)
                      done = true
                    default :
                      // Some other error; report it and stop trying.
                      dispatch_async(dispatch_get_main_queue()) {
                        self.presentAlertWithTitle("AUTHENTICATION FAILED", message: error!.localizedFailureReason ?? "code \(error!.code)")
                      }
                      done = true
                  }
                }
            }
          guard !done else { break }
        }
      }


    func presentAlertWithTitle(title: String, message: String)
      {
        // Present a UIAlertController with the given (unlocalized) title and message. The alert
        // has a single dismiss button and no completion block.

        let alert = UIAlertController(
            title: NSLocalizedString(title, comment: "Alert title"),
            message: NSLocalizedString(message, comment: "Alert message"),
            preferredStyle: .Alert
          )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: "Alert dismiss title"),
            style: .Default,
            handler: nil
          ))

        presentViewController(alert, animated: true, completion: nil)
      }


    func modeDidChange()
      {
        // Update the UI state to match our mode.

        // Determine editability of the key
        keyTextField.enabled = editing

        // Determine visibility/editability of the value
        valueLabel.hidden = mode == .None
        valueTextView.hidden = mode == .None
        valueTextView.editable = editing

        // Determine title and visibility of the show button
        let showButtonTitle = mode == .None ? "SHOW" : "HIDE"
        showButton.setTitle(showButtonTitle, forState: .Normal)
        showButton.hidden = editing

        // Determine the form of the edit button
        navigationItem.rightBarButtonItem = editing
          ? UIBarButtonItem(barButtonSystemItem:.Done, target:self, action:#selector(ItemViewController.done(_:)))
          : UIBarButtonItem(barButtonSystemItem:.Edit, target:self, action:#selector(ItemViewController.edit(_:)))

        // Set the first responder appropriately
        switch mode {
          case .Create :
            keyTextField.becomeFirstResponder()
          case .Edit :
            valueTextView.becomeFirstResponder()
          default :
            break
        }
      }


    var invariant: Bool
      {
        // Ensure our mode is consistent with the editing state
        guard editing == (mode == .Edit || mode == .Create) else { return false }

        return true
      }

    // MARK: - NSNotification

    func applicationDidEnterBackground(notification: NSNotification)
      {
        // Hide our value when the application loses foreground status.

        mode = .None
        modeDidChange()
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        assert(keyLabel != nil && keyTextField != nil && valueLabel != nil && valueTextView != nil && showButton != nil, "unconnected outlets")

        super.viewDidLoad()

        // Localize labels
        keyLabel.text = NSLocalizedString("KEY", comment: "Item key label")
        valueLabel.text = NSLocalizedString("VALUE", comment: "Item value label")

        // Present the item key
        keyTextField.text = key

        // Give the value view a border and a slightly darker background color.
        valueTextView.layer.cornerRadius = 8
        valueTextView.layer.borderWidth = 1
        valueTextView.layer.borderColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1).CGColor
        valueTextView.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)

        // Set the target/action of the show button
        showButton.addTarget(self, action: #selector(ItemViewController.show(_:)), forControlEvents: .TouchUpInside)

        // Sync UI elements with our mode
        modeDidChange()
      }


    override func setEditing(state: Bool, animated: Bool)
      {
        super.setEditing(state, animated:animated)

        if isViewLoaded() {
          modeDidChange()
        }
      }


    // MARK: - NSCoding

    required init?(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
