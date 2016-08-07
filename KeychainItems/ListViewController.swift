/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import UIKit


class ListViewController: UITableViewController
  {

    let cellReuseIdentifier = "default"

    let keychain: KeyChain

    var keys: [String] = []


    init(keychain: KeyChain)
      {
        self.keychain = keychain

        super.init(style: .Plain)

        keychain.addObserver(self, forKeyPath: "keys", options: .Initial, context: nil)

        title = NSLocalizedString("ITEM LIST", comment: "ListViewController title")
      }


    deinit
      {
        keychain.removeObserver(self, forKeyPath: "keys")
      }


    func addEntry(sender: AnyObject?)
      {
        self.navigationController?.pushViewController(ItemViewController(keychain: keychain), animated: true)
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ListViewController.addEntry(_:)))
      }


    // MARK: - UITableViewDataSource

    override func tableView(sender: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        assert(section == 0, "unexpected argument")

        return keys.count
      }


    override func tableView(sender: UITableView, cellForRowAtIndexPath path: NSIndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath:path)
        cell.textLabel!.text = keys[path.row]
        return cell
      }


    override func tableView(sender: UITableView, editingStyleForRowAtIndexPath path: NSIndexPath) -> UITableViewCellEditingStyle
      {
        return .Delete
      }


    override func tableView(sender: UITableView, commitEditingStyle style: UITableViewCellEditingStyle, forRowAtIndexPath path: NSIndexPath)
      {
        keychain[keys[path.row]] = nil
      }


    // MARK: - UITableViewDelegate

    override func tableView(sender: UITableView, didSelectRowAtIndexPath path: NSIndexPath)
      {
        self.navigationController?.pushViewController(ItemViewController(keychain: keychain, key: keys[path.row]), animated: true)
      }


    // MARK: - NSKeyValueObserving

    override func observeValueForKeyPath(path: String?, ofObject sender: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
      {
        assert(sender === keychain && path == "keys")

        keys = Array(keychain.keys).sort()

        if isViewLoaded() {
          tableView.reloadData()
        }
      }


    // MARK: - NSCoding

    required init(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
