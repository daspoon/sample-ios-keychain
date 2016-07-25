/*

  Copyright (c) 2016 David Spooner; see License.txt

*/

import UIKit


class ListViewController: UITableViewController
  {

    let cellReuseIdentifier = "default"

    var things: [String] = ["one", "two", "three"]


    init()
      {
        super.init(style: .Plain)

        title = NSLocalizedString("ITEM LIST", comment: "ListViewController title")
      }


    // MARK: - UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
      }


    // MARK: - UITableViewDataSource

    override func tableView(sender: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        return things.count
      }


    override func tableView(sender: UITableView, cellForRowAtIndexPath path: NSIndexPath) -> UITableViewCell
      {
        assert(path.section == 0, "unexpected argument")

        let cell = sender.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath:path)
        cell.textLabel!.text = things[path.row]
        return cell
      }


    // MARK: - UITableViewDelegate

    override func tableView(sender: UITableView, didSelectRowAtIndexPath path: NSIndexPath)
      {
        self.navigationController?.pushViewController(ItemViewController(), animated: true)
      }


    // MARK: - NSCoding

    required init(coder: NSCoder)
      {
        fatalError("not supported")
      }

  }
