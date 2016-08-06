/*

  Copyright (c) 2016 David Spooner; see License.txt

  A simple UIViewController to display and edit a keychain item.

*/

import UIKit


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
      }


    func show(sender: AnyObject?)
      {
        // The target of the show/hide button.

        // This can't happen while editing since the button is not visible.
        assert(!editing, "unexpected state")

        if mode == .None {
          // Update the value view and change mode to View
          valueTextView.text = keychain[key] as! String
          mode = .View
        }
        else {
          mode = .None
        }

        modeDidChange()
      }


    func edit(sender: AnyObject?)
      {
        // The action of the edit navbar button.

        assert(!editing, "invalid state")

        // Note that mode can be set to Create only on initialization, so if we're not currently
        // editing then we must represent an existing item; transition to Edit mode.
        mode = .Edit

        setEditing(true, animated: true)
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

        // Revert to initial state after editing.
        mode = .None

        setEditing(false, animated: true)
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


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        assert(keyLabel != nil && keyTextField != nil && valueLabel != nil && valueTextView != nil && showButton != nil, "unconnected outlets")

        super.viewDidLoad()

        // Present the item key
        keyTextField.text = key

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
