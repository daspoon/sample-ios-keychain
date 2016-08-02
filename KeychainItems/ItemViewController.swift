/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import UIKit


class ItemViewController : UIViewController
  {

    enum Mode
      {
        case Create
        case Edit
        case View
      }


    let keychain: KeyChain
    var key: String
    var value: String
    var mode: Mode


    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var keyTextField: UITextField!
    @IBOutlet var valueTextView: UITextView!


    init(keychain: KeyChain, key: String? = nil)
      {
        self.keychain = keychain
        self.key = key ?? ""
        self.value = key != nil ? keychain[key!] as! String : ""
        self.mode = key == nil ? .Create : .View

        super.init(nibName: "ItemViewController", bundle: nil)

        title = NSLocalizedString("ITEM", comment:"ItemViewController title")

        self.editing = mode != .View
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        assert(keyLabel != nil && keyTextField != nil && valueLabel != nil && valueTextView != nil, "unconnected outlets")

        super.viewDidLoad()

        keyTextField.text = key
        valueTextView.text = value
      }


    // MARK: - NSCoding

    required init?(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
