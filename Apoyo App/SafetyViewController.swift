
import UIKit
import MapKit
import FirebaseDatabase
import CoreLocation
import UserNotifications

class SafetyViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    
    // Presents notification with specified title and message to user
    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        // If user's iOS version >= 12.0
        if #available(iOS 12.0, *) {
            content.sound = UNNotificationSound.defaultCritical
        } else {
            content.sound = UNNotificationSound.default
        }
        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Request permission for notifications from user
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
      
        // Update home location longitude stored locally with home location longitude stored in database
    FIRDatabase.database().reference().child("homeLocation").child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() { return }
            UserDefaults.standard.set(snapshot.value, forKey: "homeLon")
            FIRDatabase.database().reference().child("homeLocation").removeAllObservers()
            
        })
        
        // Update home location latitude stored locally with home location latitude stored in database
    FIRDatabase.database().reference().child("homeLocation").child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() { return }
            UserDefaults.standard.set(snapshot.value, forKey: "homeLat")
            FIRDatabase.database().reference().child("homeLocation").removeAllObservers()
            
        })
        
        
        // Show safety perimeter centered at home location coordinate on map
        let homeCoordinate = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "homeLat"), longitude: UserDefaults.standard.double(forKey: "homeLon"))
        self.mapView.removeOverlays(self.mapView.overlays)
        let circle = MKCircle(center: homeCoordinate, radius: 100)
        self.mapView.addOverlay(circle)
        

        // Code within Timer is executed every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
        
            // Update patient location latitude stored locally with patient location latitude (real-time) stored in database
        FIRDatabase.database().reference().child("location").child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
            

                if !snapshot.exists() { return }
                UserDefaults.standard.set(snapshot.value, forKey: "lat")
                FIRDatabase.database().reference().child("location").removeAllObservers()


            })
            
            // Update patient location longitude stored locally with patient location longitude (real-time) stored in database
        FIRDatabase.database().reference().child("location").child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
            
            
                if !snapshot.exists() { return }
                UserDefaults.standard.set(snapshot.value, forKey: "lon")
                FIRDatabase.database().reference().child("location").removeAllObservers()
            
            
            })
        
            // Set region to be displayed on map
            let center = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "lat"), longitude: UserDefaults.standard.double(forKey: "lon"))
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
            self.mapView.setRegion(region, animated: true)
            
            // Show patient real-time location on map
            self.mapView.removeAnnotations(self.mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            annotation.title = "Patient Location"
            self.mapView.addAnnotation(annotation)
            
            var patientLocation = CLLocation(latitude: UserDefaults.standard.double(forKey: "lat"), longitude: UserDefaults.standard.double(forKey: "lon"))
            var homeLocation = CLLocation(latitude: UserDefaults.standard.double(forKey: "homeLat"), longitude: UserDefaults.standard.double(forKey: "homeLon"))
            // Calculate distance between patient real-time location and home location
            var distance = patientLocation.distance(from: homeLocation)


            if let patientInHome = UserDefaults.standard.bool(forKey: "patientInHome") as? Bool {
                // If patient was inside safety perimeter 5 seconds ago
                if UserDefaults.standard.bool(forKey: "patientInHome") == true {
                    // If patient is more than 100m away from home location (outside perimeter)
                    if distance > 100 {
                        // Notify caregiver of patient exit from perimeter
                        let title = "Exit Alert"
                        let message = "Patient exited the safety perimeter"
                        UserDefaults.standard.set(false, forKey: "patientInHome")
                        self.showNotification(title: title, message: message)
                    }
                }
                // If patient was outside safety perimeter 5 seconds ago
                else {
                    // If patient is less than 100m away from home location (inside perimeter)
                    if distance < 100 {
                        // Notify caregiver of patient entry into perimeter
                        let title = "Entry Alert"
                        let message = "Patient entered the safety perimeter"
                        UserDefaults.standard.set(true, forKey: "patientInHome")
                        self.showNotification(title: title, message: message)
                    }
                }
            }

        

        }
        

    }


    // Executed when 'Set Home Location' button clicked
    @IBAction func setHomeLocationTapped(_ sender: Any) {
        // Find coordinates of location at center of map
        let homeCoordinate = mapView.centerCoordinate
        var homeLatitude = homeCoordinate.latitude
        var homeLongitude = homeCoordinate.longitude
        
        // Build dictionary with home location coordinates
        let homeLocationDictionary : [String:Any] = ["latitude":homeLatitude,"longitude":homeLongitude]
        
        // Save home location in database and local storage
        FIRDatabase.database().reference().child("homeLocation").setValue(homeLocationDictionary)
        UserDefaults.standard.set(homeLongitude, forKey: "homeLon")
        UserDefaults.standard.set(homeLatitude, forKey: "homeLat")
        
        // Patient is now inside safety perimeter
        UserDefaults.standard.set(true, forKey: "patientInHome")
        
        // Show safety perimeter centered at home location on map
        self.mapView.removeOverlays(self.mapView.overlays)
        let circle = MKCircle(center: homeCoordinate, radius: 100)
        self.mapView.addOverlay(circle)
    }
    
}


extension SafetyViewController: MKMapViewDelegate {
    // Returns visual representation of circle showing safety perimeter on map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.strokeColor = .red
        circleRenderer.fillColor = .green
        circleRenderer.alpha = 0.5
        return circleRenderer
    }
}
