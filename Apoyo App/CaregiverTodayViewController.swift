
import UIKit
import FirebaseDatabase

class CaregiverTodayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Array to store list of reminders from database
    var reminders : [FIRDataSnapshot] = []
    // Table View to show reminders
    @IBOutlet var table: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add reminder to list of reminders and table view when reminder is added to database
        FIRDatabase.database().reference().child("reminders").observe(.childAdded) { (snapshot) in
            if let reminderDictionary = snapshot.value as? [String:AnyObject] {
                self.reminders.append(snapshot)
                self.table.reloadData()
            }
        }
            
    }
        
    
    // Sets number of rows in table to number of reminders
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    // Sets text label in each row of table view to task name of each reminder
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath)
        
        // Get reminder from reminder array at index of row index
        let snapshot = reminders[indexPath.row]
        
        if let reminderDictionary = snapshot.value as? [String:AnyObject] {
            
            if let task = reminderDictionary["task"] as? String {
                // Set text label in table row to reminder task name
                cell.textLabel?.text = (reminderDictionary["task"] as! String)
            }
        }
        
        return cell
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        table.reloadData()
    }
    
    // Deletes reminder from database and list of reminders, when user deletes reminder
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // If user swipes left on reminder in table view and clicks 'Delete'
        if editingStyle == UITableViewCell.EditingStyle.delete {
            if let snapshot = reminders[indexPath.row].value as? [String:AnyObject] {
                FIRDatabase.database().reference().child("reminders").child((snapshot["task"]) as! String).removeValue()
                reminders.remove(at: indexPath.row)
                }
            table.reloadData()
            }
        }
        
    }


