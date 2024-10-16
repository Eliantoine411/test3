import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class PostViewController: UIViewController, PHPickerViewControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!
    
    private var pickedImage: UIImage?
    private var pickedImageLocation: CLLocation?
    private var locationManager: CLLocationManager?
    private var locationString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLocationManager()
    }

    // MARK: - Configure CLLocationManager
    private func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    // CLLocationManagerDelegate method to get the current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        // Only use device location if we don't have an image location
        if pickedImageLocation == nil {
            convertLocationToCityAndState(location: currentLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)
        
        guard let image = pickedImage, let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        let imageFile = ParseFile(name: "image.jpg", data: imageData)
        var post = Post()
        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.user = User.current
        post.locationString = locationString
        post.timestamp = Date() // Set the timestamp to the current date

        post.save { [weak self] result in
            switch result {
            case .success(let post):
                print("✅ Post Saved! \(post)")
                DispatchQueue.main.async {
                    self?.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }


    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: description ?? "Please try again...", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

    // MARK: - Convert CLLocation to city and state using CLGeocoder
    private func convertLocationToCityAndState(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            let city = placemark.locality ?? ""
            let state = placemark.administrativeArea ?? ""
            self?.locationString = "\(city), \(state)"
            print("Location: \(self?.locationString ?? "No location found")")
        }
    }

    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(description: error.localizedDescription)
                }
                return
            }

            DispatchQueue.main.async {
                self?.previewImageView.image = image
                self?.pickedImage = image

                // Extract location metadata
                if let assetIdentifier = results.first?.assetIdentifier {
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                    if let asset = fetchResult.firstObject {
                        if let location = asset.location {
                            self?.pickedImageLocation = location  // Store the image's location
                            print("Image Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
                            
                            // Convert location to city and state
                            self?.convertLocationToCityAndState(location: location)
                        } else {
                            print("No location metadata found for this image")
                            // Use device location as fallback
                            if let deviceLocation = self?.locationManager?.location {
                                self?.convertLocationToCityAndState(location: deviceLocation)
                            } else {
                                self?.locationString = "No location available"
                            }
                        }
                    }
                }
            }
        }
    }
}
