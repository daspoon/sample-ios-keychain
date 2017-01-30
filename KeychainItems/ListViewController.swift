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

        super.init(style: .plain)

        keychain.addObserver(self, forKeyPath: "keys", options: .initial, context: nil)

        title = NSLocalizedString("ITEM LIST", comment: "ListViewController title")
      }


    deinit
      {
        keychain.removeObserver(self, forKeyPath: "keys")
      }


    func addEntry(_ sender: AnyObject?)
      {
        self.navigationController?.pushViewController(ItemViewController(keychain: keychain), animated: true)
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ListViewController.addEntry(_:)))
      }


    // MARK: - UITableViewDataSource

    override func tableView(_ sender: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        assert(section == 0, "unexpected argument")

        return keys.count
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for:path)
        cell.textLabel!.text = keys[path.row]
        return cell
      }


    override func tableView(_ sender: UITableView, editingStyleForRowAt path: IndexPath) -> UITableViewCellEditingStyle
      {
        return .delete
      }


    override func tableView(_ sender: UITableView, commit style: UITableViewCellEditingStyle, forRowAt path: IndexPath)
      {
        keychain[keys[path.row]] = nil
      }


    // MARK: - UITableViewDelegate

    override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        self.navigationController?.pushViewController(ItemViewController(keychain: keychain, key: keys[path.row]), animated: true)
      }


    // MARK: - NSKeyValueObserving

    override func observeValue(forKeyPath path: String?, of sender: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
      {
        keys = Array(keychain.keys).sorted()

        if isViewLoaded {
          tableView.reloadData()
        }
      }


    // MARK: - NSCoding

    required init(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
