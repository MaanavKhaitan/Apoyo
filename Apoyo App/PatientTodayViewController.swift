
import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase
import UserNotifications

class PatientTodayViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    // Array to store list of reminders from database
    var reminders : [FIRDataSnapshot] = []
    // Table View to show reminders
    @IBOutlet var table: UITableView!
    
    let locationManager = CLLocationManager()
    var patientLocation = CLLocationCoordinate2D()
    let center = UNUserNotificationCenter.current()
    
    // Schedules notification with specified name, date, and time
    @objc func scheduleNotification(taskName: String, hour: Int, minute: Int, day: Int, month: Int, year: Int) {
        
        // Set notification content
        let content = UNMutableNotificationContent()
        content.title = taskName
        content.body = "Remember to " + taskName + "!"
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        
        // If user's iOS version >= 12.0
        if #available(iOS 12.0, *) {
            content.sound = UNNotificationSound.defaultCritical
        } else {
            content.sound = UNNotificationSound.default
        }
        
        // Set notification date and time
        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        date.day = day
        date.month = month
        date.year = year
        
        // Create notification trigger and add request
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let request = UNNotificationRequest(identifier: taskName, content: content, trigger: trigger)
        center.add(request)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = UNUserNotificationCenter.current()
        
        // Request permission for notifications from user
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in }

        // Set up locationManager and begin location detection
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        // Add reminder to array of reminders and table view, and schedule reminder notification, when reminder is added to database
        FIRDatabase.database().reference().child("reminders").observe(.childAdded) { (snapshot) in
            if let reminderDictionary = snapshot.value as? [String:AnyObject] {
                // Add reminder to array of reminders
                self.reminders.append(snapshot)
    
                self.scheduleNotification(taskName: reminderDictionary["task"] as! String, hour: reminderDictionary["hour"] as! Int, minute: reminderDictionary["minute"] as! Int, day: reminderDictionary["day"] as! Int, month: reminderDictionary["month"] as! Int, year: (reminderDictionary["year"] as! Int?)!)
                
                self.table.reloadData()
                
            }
        }
        
        // Delete reminder from array of reminders and table view, and cancel reminder notification, when reminder is deleted from database
        FIRDatabase.database().reference().child("reminders").observe(.childRemoved) { (snapshot) in
            if let reminderDictionary = snapshot.value as? [String:AnyObject] {
                center.removePendingNotificationRequests(withIdentifiers: [reminderDictionary["task"] as! String])
                while self.reminders.contains(snapshot) {
                    if let itemToRemoveIndex = self.reminders.firstIndex(of: snapshot) {
                        // Delete reminder from array of reminders
                        self.reminders.remove(at: itemToRemoveIndex)
                    }
                }
                self.table.reloadData()

            }
            
        }
            
    }
    
    // Updates patient location on database when patient location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coord = manager.location?.coordinate {
            
            let locationDictionary : [String:Any] = ["latitude":coord.latitude,"longitude":coord.longitude]
            FIRDatabase.database().reference().child("location").setValue(locationDictionary)
            
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
    
}
