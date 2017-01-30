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
        case none
          // Item value is not visible.
        case view
          // Item value is visible, but not editable.
        case edit
          // Editing an existing item.
        case create
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
        mode = k == nil ? .create : .none

        super.init(nibName: "ItemViewController", bundle: nil)

        title = NSLocalizedString("ITEM", comment:"ItemViewController title")

        isEditing = mode == .edit || mode == .create

        // Register to observe the application losing foreground status
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
      }


    deinit
      {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
      }


    func show(_ sender: AnyObject?)
      {
        // The target of the show/hide button.

        // This can't happen while editing since the button is not visible.
        assert(!isEditing, "unexpected state")

        if mode == .none {
          authenticateWithContinuation {
            self.valueTextView.text = self.keychain[self.key] as! String
            self.mode = .view
            self.modeDidChange()
          }
        }
        else {
          mode = .none
          modeDidChange()
        }
      }


    func edit(_ sender: AnyObject?)
      {
        // The action of the edit navbar button.

        assert(!isEditing, "invalid state")

        authenticateWithContinuation {
          self.mode = .edit
          self.setEditing(true, animated: true)
        }
      }


    func done(_ sender: AnyObject?)
      {
        // The action of the done navbar button.

        assert(isEditing, "invalid state")

        // Get the content of the key field, stripped of enclosing whitespace
        let newKey = keyTextField.text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""

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
        keychain[key] = valueTextView.text as AnyObject?

        // Revert to viewable state after editing.
        mode = .view

        setEditing(false, animated: true)
      }


    func authenticateWithContinuation(_ continuation: @escaping () -> Void)
      {
        // Authenticate using biometrices, or by falling-back to passcode if necessary.
        // If successful, execute the given block on the main thread; otherwise report
        // an error (if the request was not cancelled).

        // For modes other than None just execute the completion and return, because we must
        // already have authenticated in order to present the value. Note that authentication
        // is not required for entry creation.
        guard mode == .none else { continuation(); return }

        // Skip authentication while testing, since those apis aren't UI-testable.
        guard enableAuthentication else { continuation(); return }

        let context = LAContext()
        let reason = NSLocalizedString("AUTHENTICATE TO REVEAL KEYCHAIN ITEM", comment: "Authentication reason")

        var done = false
        for policy in [LAPolicy.deviceOwnerAuthenticationWithBiometrics, .deviceOwnerAuthentication] {
          context.evaluatePolicy(policy, localizedReason: reason)
            { (success, error) in
                if success {
                  DispatchQueue.main.async(execute: continuation)
                  done = true
                }
                else {
                  switch LAError.Code(rawValue: error!._code)! {
                    case .userFallback, .touchIDNotAvailable, .touchIDNotEnrolled, .touchIDLockout, .systemCancel :
                      // Keep trying...
                      break
                    case .userCancel :
                      // The user has cancelled the request; stop trying.
                      done = true
                    case .passcodeNotSet :
                      // No passcode required; succeed.
                      DispatchQueue.main.async(execute: continuation)
                      done = true
                    default :
                      // Some other error; report it and stop trying.
                      DispatchQueue.main.async {
                        self.presentAlertWithTitle("AUTHENTICATION FAILED", message: (error as? String) ?? "")
                      }
                      done = true
                  }
                }
            }
          guard !done else { break }
        }
      }


    func presentAlertWithTitle(_ title: String, message: String)
      {
        // Present a UIAlertController with the given (unlocalized) title and message. The alert
        // has a single dismiss button and no completion block.

        let alert = UIAlertController(
            title: NSLocalizedString(title, comment: "Alert title"),
            message: NSLocalizedString(message, comment: "Alert message"),
            preferredStyle: .alert
          )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: "Alert dismiss title"),
            style: .default,
            handler: nil
          ))

        present(alert, animated: true, completion: nil)
      }


    func modeDidChange()
      {
        // Update the UI state to match our mode.

        // Determine editability of the key
        keyTextField.isEnabled = isEditing

        // Determine visibility/editability of the value
        valueLabel.isHidden = mode == .none
        valueTextView.isHidden = mode == .none
        valueTextView.isEditable = isEditing

        // Determine title and visibility of the show button
        let showButtonTitle = mode == .none ? "SHOW" : "HIDE"
        showButton.setTitle(showButtonTitle, for: UIControlState())
        showButton.isHidden = isEditing

        // Determine the form of the edit button
        navigationItem.rightBarButtonItem = isEditing
          ? UIBarButtonItem(barButtonSystemItem:.done, target:self, action:#selector(ItemViewController.done(_:)))
          : UIBarButtonItem(barButtonSystemItem:.edit, target:self, action:#selector(ItemViewController.edit(_:)))

        // Set the first responder appropriately
        switch mode {
          case .create :
            keyTextField.becomeFirstResponder()
          case .edit :
            valueTextView.becomeFirstResponder()
          default :
            break
        }
      }


    var invariant: Bool
      {
        // Ensure our mode is consistent with the editing state
        guard isEditing == (mode == .edit || mode == .create) else { return false }

        return true
      }

    // MARK: - NSNotification

    func applicationDidEnterBackground(_ notification: Notification)
      {
        // Hide our value when the application loses foreground status.

        mode = .none
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
        valueTextView.layer.borderColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1).cgColor
        valueTextView.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)

        // Set the target/action of the show button
        showButton.addTarget(self, action: #selector(ItemViewController.show(_:)), for: .touchUpInside)

        // Sync UI elements with our mode
        modeDidChange()
      }


    override func setEditing(_ state: Bool, animated: Bool)
      {
        super.setEditing(state, animated:animated)

        if isViewLoaded {
          modeDidChange()
        }
      }


    // MARK: - NSCoding

    required init?(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
