//
//  ViewController.swift
//  WhatFlower
//
//  Created by Konstantin on 22/03/2019.
//  Copyright © 2019 Konstantin. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var infoTextViewHeight: NSLayoutConstraint!
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        //imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        imageView.contentMode = .scaleAspectFit
        
        infoTextViewHeight.constant = 0
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            imageView.image = userPickedImage
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert CIImage")
            }
            
            detect(image: convertedCIImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            
            if let firstResult = results.first {
                
                let flowerName = firstResult.identifier.capitalized
                
                self.navigationItem.title = flowerName
                self.requestInfo(flowerName: flowerName);
            }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("Error \(error.localizedDescription)")
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON
            { (response) in
            if response.result.isSuccess {
                print("Sucess! Got the wikipedia info")
                //print(response)
                
                let wikiJSON: JSON = JSON(response.result.value!)
                print(wikiJSON)
                self.updateInfo(json: wikiJSON)
                
            }
            else {
                print("Error \(response.result.error!)")
            }
        }
        
    }
    
    func updateInfo(json: JSON) {
        
        let pageid = json["query"]["pageids"][0].stringValue
        
        guard pageid != "" else {
            return
        }
        
        let textInfo = json["query"]["pages"][pageid]["extract"].stringValue
        
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: nil)
        
        infoTextViewHeight.constant = 228
        infoTextView.text = textInfo
        
    }
    
}



