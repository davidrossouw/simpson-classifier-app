//
//  ViewController.swift
//  SwiftImageAPI
//
//  Created by David Rossouw on 2019-08-23.
//  Copyright © 2019 David Rossouw. All rights reserved.
//

import UIKit


struct simpsonResults: Decodable {
    let y_pred: String
    let y_prob: String
}


extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imgGuess: UIImageView!
    @IBOutlet weak var lblGuess: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if var pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            pickedImage = resizeImage(image: pickedImage, newWidth: 64)!
            print(pickedImage.size)
            
            // Set the image view
            imgGuess.contentMode = .scaleToFill
            imgGuess.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)

    }
    
    
    func uploadImage(paramName: String, fileName: String, image: UIImage) {
        let url = URL(string: "http://159.203.45.61:5000/upload")
        print(image.size)
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        let session = URLSession.shared
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        
        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        let login = "david"
        let password = "cookiesandcream"
        let credentialData = "\(login):\(password)".data(using: .utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        let authString = "Basic \(base64Credentials)"
        
        urlRequest.addValue(authString, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(image.pngData()!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            if error == nil {

                let result = try? JSONDecoder().decode(simpsonResults.self, from: responseData!)
                print(result!.y_pred)
                
                print(result!.y_prob)
                if result!.y_prob.toDouble()! >= 0.8 {
                    DispatchQueue.main.async {
                        self.lblGuess.text = result?.y_pred
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.lblGuess.text = "Not recognized by model"
                    }
                }

            }
        }).resume()
    }
    
    @IBAction func sendRequest(_ sender: Any) {
        
        guard let image = imgGuess.image else { return }
        lblGuess.text = "Thinking..."
        uploadImage(paramName: "file", fileName: "filename", image: image)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func takePhotoFromCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
}

