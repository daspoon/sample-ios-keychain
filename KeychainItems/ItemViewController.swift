/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import UIKit


class ItemViewController : UIViewController
  {

    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var keyTextField: UITextField!
    @IBOutlet var valueTextView: UITextView!
    @IBOutlet var button: UIButton!


    init()
      {
        super.init(nibName: "ItemViewController", bundle: nil)

        title = NSLocalizedString("ITEM", comment:"ItemViewController title")
      }


    @IBAction func buttonPressed(sender: UIButton)
      {
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        assert(keyLabel != nil && keyTextField != nil && valueLabel != nil && valueTextView != nil && button != nil, "unconnected outlets")

        super.viewDidLoad()
      }


    // MARK: - NSCoding

    required init?(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
