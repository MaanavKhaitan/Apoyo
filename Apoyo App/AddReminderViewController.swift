
import UIKit
import FirebaseDatabase

class AddReminderViewController: UIViewController, UITextFieldDelegate {

    // Text Field to enter task name of reminder
    @IBOutlet var taskNameTextField: UITextField!
    
    // Date and Time Picker
    @IBOutlet var datePicker: UIDatePicker!
    
    // Adds reminder to database when 'Add Reminder' button clicked
    @IBAction func addTapped(_ sender: Any) {
        
        let components = datePicker.calendar.dateComponents([.hour, .minute, .day, .month, .year],from: datePicker.date)
        
        // Build dictionary with all details for reminder
        let reminderDictionary : [String:Any] = ["task":taskNameTextField.text,"hour":components.hour,"minute":components.minute,"day":components.day,"month":components.month,"year":components.year]

        // Save Reminder Dictionary to database
        FIRDatabase.database().reference().child("reminders").child(reminderDictionary["task"] as! String).setValue(reminderDictionary)

        taskNameTextField.text = ""
        
    }
    
    // Closes keyboard when screen tapped outside keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        
    }
    
    // Closes keyboard when 'Return' key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
        
    }

    
}
