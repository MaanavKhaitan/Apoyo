
import UIKit

class LogInViewController: UIViewController {

    // Switch for user to select patient or caregiver role
    @IBOutlet var PatientCaregiverSwitch: UISwitch!
    
    // Navigate to Caregiver or Patient Today Screen when 'Log In' button tapped
    @IBAction func LogInTapped(_ sender: Any) {
        if PatientCaregiverSwitch.isOn {
            self.performSegue(withIdentifier: "CaregiverLogInSegue", sender: nil)
        } else {
            self.performSegue(withIdentifier: "PatientLogInSegue", sender: nil)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


}

