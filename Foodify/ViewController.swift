//
//  ViewController.swift
//  Foodify
//
//  Created by Aahil Syed on 4/22/24.
//

import UIKit
import Vision
import GoogleGenerativeAI
import SwiftUI

class ViewController: UIViewController, UITextViewDelegate {

    
    
    var request = VNRecognizeTextRequest(completionHandler: nil)
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var preference = ""
    
    
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func tappedCheck(_ sender: Any) {
        fetchAI(ingredients:ingredientField?.text)
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        mainStackView.isHidden = true
        blurView.isHidden = true
    }
    
    @IBOutlet weak var ingredientField: UITextView?
    
    @IBAction func menuPressedSelect(_ sender: Any) {
        preference = "Select"
    }
    
    @IBAction func menuPressedVegan(_ sender: Any) {
        preference =  "Vegan"
        print("Vegan")
    }
    
    @IBAction func menuPressedVegetarian(_ sender: Any) {
        preference = "Vegetarian"
    }
    
    @IBAction func menuPressedHalal(_ sender: Any) {
        preference = "Halal"
    }
    
    @IBAction func menuPressedKosher(_ sender: Any) {
        preference = "Kosher"
    }
    
    @IBAction func menuPressedKeto(_ sender: Any) {
        preference = "fit for a Keto diet"
    }
    
    @IBAction func menuPressedPaleo(_ sender: Any) {
        preference = "fit for a Paleo diet"
    }
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)

    var aiResponse = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        ingredientField?.textColor = .white
        ingredientField?.backgroundColor = UIColor(cgColor: CGColor(red: 20/256, green: 78/256, blue: 35/256, alpha: 1))
        ingredientField?.layer.cornerRadius = 10
        mainStackView?.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
        self.ingredientField?.delegate = self
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        setupGallery()
    }
    
    func setupGallery() {
        preference = ""
        // Create Action Sheet and display it
        let ac = UIAlertController(title: "Select Image", message: "Select Image From...", preferredStyle: .actionSheet)
        let cameraButton = UIAlertAction(title: "Camera", style: .default) { [weak self] (_) in self?.showImagePicker(selectedSource: .camera)}
        let libraryButton = UIAlertAction(title: "Photo Library", style: .default) { [weak self] (_) in self?.showImagePicker(selectedSource: .photoLibrary)}
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel) { (_) in print("Cancel Press")}
        ac.addAction(cameraButton)
        ac.addAction(libraryButton)
        ac.addAction(cancelButton)
        present(ac, animated: true, completion: nil)
        
    }
    
    func showImagePicker(selectedSource: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(selectedSource) else {print("Selected Source Not Available")
        return
    }
        // Assign and present image picker
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = selectedSource
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    

    func fetchAI(ingredients:String?) {
        // Setup AI
        aiResponse = ""
        if (preference == "Select") {
            showAlert(response: "Alert|Please select a diet preference first")
            return
        }
        
        //AI request
        Task {
            do {
                let response = try await model.generateContent("Based on the ingredients, tell me if this item is \(preference). The only answer I want is 'Verified' (yes), 'Be careful!' (no), or 'Questionable' with a description as to why it is 'Questionable' or 'No'. No other answers are allowed. Do not use questionable for everything. Go through every ingredient and check if it is allowed in the diet. NO MISTAKES ARE ALLOWED. Make sure to check EVERY INGREDIENT induvidually before moving on to selecting questionable or no. THERE IS NO ROOM FOR ERROR. If found questionable, the description may be if the ingredient has multiple sources, such as whey, which may come from plant or animal sources. These are the ingredients \(String(describing: ingredients))). Remember, IF YOU RESPOND 'Questionable' OR 'Be careful!' GIVE A DESCRIPTION. INSERT THE '|' AS A DELIMITER IN BETWEEN THE ANSWER ('Be careful!', OR 'Questionable') AND DESCRIPTION, OR IF USING VERIFIED, USE VERIFIED THEN THE DELIMITER FOLLOWED BY 'This product fits your dietary needs'. THERE IS NO ROOM FOR ERROR. IF THE INGREDIENT HAS MULTIPLE SOURCES WHICH MAY OR MAY NOT FIT THE DIET, USE QUESTIONABLE, DO NOT SAY VERIFIED. THERE IS NO ROOM FOR ERROR. YOU MUST MAKE NO MISTAKES. Also, there may be some other information than ingredients, such as nutrition information of manufacturing information. Ignore this and focus on the ingredients. MAKE NO MISTAKES.")

                guard let text = response.text else {
                    
                    return
                }
                aiResponse = text
                showAlert(response: aiResponse)
            } catch {
                // error occured
                aiResponse = "error"
                showAlert(response:aiResponse)
            }
        }
    }
    
    func showAlert(response:String) {
        // Show result of API response
        let title = response.components(separatedBy: "|")
        let alert = UIAlertController(title: title[0], message: title[1], preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: {action in print("Tapped Dismiss")}))
        
        present(alert, animated: true)
    }

    
    private func setupVisionTextRecognizeImage(image: UIImage?) {
        
        //setupTextRecognition
        
        var textString = ""
        
        request = VNRecognizeTextRequest(completionHandler: {(request, error) in
        
            guard let observations = request.results as? [VNRecognizedTextObservation] else {fatalError("Recieved Invalid Observation")}
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else {
                    print ("No candidate")
                    continue}
                textString += "\n\(topCandidate.string)"
                
                DispatchQueue.main.async {
                     self.ingredientField?.text = textString
                }
            }
        })
        
        // Text recognition settings
        request.customWords = ["cust0m"]
        request.minimumTextHeight = 0.03215
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en_US", ""]
        request.usesLanguageCorrection = true
        
        let requests = [request]
        
        // Perform text recognition
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = image?.cgImage else {fatalError("Missing image to scan")}
                let handle = VNImageRequestHandler(cgImage: img, options: [:])
                try? handle.perform(requests)
        }
        
        
    }
    
    // Close text field on touch out
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.ingredientField?.endEditing(true)
    }
    
   
}

// Needed for camera pullup
extension ViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        self.ingredientField?.text = ""
        
        let image = info[UIImagePickerController.InfoKey.editedImage]as? UIImage
        
        
        
        self.imageView.image = image
        mainStackView.isHidden = false
        blurView.isHidden = false
        setupVisionTextRecognizeImage(image: image)
    }
}
