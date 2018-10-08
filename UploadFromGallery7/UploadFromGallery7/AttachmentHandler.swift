//
//  AttachmentHandler.swift
//  UploadFromGallery7
//
//  Created by yeganeh on 5/20/18.
//  Copyright © 2018 yeganeh. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import AVFoundation
import Foundation
import Alamofire
import SwiftyJSON

class AttachmentHandler: NSObject {

    static let shared = AttachmentHandler()
    fileprivate var currentVC: UIViewController?
    
    //MARK: - Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    var videoPickedBlock: ((NSURL) -> Void)?
    var filePickedBlock: ((URL) -> Void)?
    
    
    enum AttachmentType: String{
        case camera, video, photoLibrary
    }
    
    
    //MARK: - Constants
    struct Constants {
        static let actionFileTypeHeading = "Add a File"
        static let actionFileTypeDescription = "Choose a filetype to add..."
        static let camera = "Camera"
        static let phoneLibrary = "Phone Library"
        static let video = "Video"
        static let file = "File"
        
        
        static let alertForPhotoLibraryMessage = "App does not have access to your photos. To enable access, tap settings and turn on Photo Library Access."
        
        static let alertForCameraAccessMessage = "App does not have access to your camera. To enable access, tap settings and turn on Camera."
        
        static let alertForVideoLibraryMessage = "App does not have access to your video. To enable access, tap settings and turn on Video Library Access."
        
        
        static let settingsBtnTitle = "Settings"
        static let cancelBtnTitle = "Cancel"
        
    }
    
    
    
    //MARK: - showAttachmentActionSheet
    // This function is used to show the attachment sheet for image, video, photo and file.
    func showAttachmentActionSheet(vc: UIViewController) {
        currentVC = vc
        let actionSheet = UIAlertController(title: Constants.actionFileTypeHeading, message: Constants.actionFileTypeDescription, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: Constants.camera, style: .default, handler: { (action) -> Void in
            self.authorisationStatus(attachmentTypeEnum: .camera, vc: self.currentVC!)
        }))
        
        actionSheet.addAction(UIAlertAction(title: Constants.phoneLibrary, style: .default, handler: { (action) -> Void in
            self.authorisationStatus(attachmentTypeEnum: .photoLibrary, vc: self.currentVC!)
        }))
        
        actionSheet.addAction(UIAlertAction(title: Constants.video, style: .default, handler: { (action) -> Void in
            self.authorisationStatus(attachmentTypeEnum: .video, vc: self.currentVC!)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: Constants.file, style: .default, handler: { (action) -> Void in
            self.documentPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: Constants.cancelBtnTitle, style: .cancel, handler: nil))
        
        vc.present(actionSheet, animated: true, completion: nil)
    }
    
    //MARK: - Authorisation Status
    // This is used to check the authorisation status whether user gives access to import the image, photo library, video.
    // if the user gives access, then we can import the data safely
    // if not show them alert to access from settings.
    func authorisationStatus(attachmentTypeEnum: AttachmentType, vc: UIViewController){
        currentVC = vc
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            if attachmentTypeEnum == AttachmentType.camera{
                openCamera()
            }
            if attachmentTypeEnum == AttachmentType.photoLibrary{
                photoLibrary()
            }
            if attachmentTypeEnum == AttachmentType.video{
                videoLibrary()
            }
        case .denied:
            print("permission denied")
            self.addAlertForSettings(attachmentTypeEnum)
        case .notDetermined:
            print("Permission Not Determined")
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized{
                    // photo library access given
                    print("access given")
                    if attachmentTypeEnum == AttachmentType.camera{
                        self.openCamera()
                    }
                    if attachmentTypeEnum == AttachmentType.photoLibrary{
                        self.photoLibrary()
                    }
                    if attachmentTypeEnum == AttachmentType.video{
                        self.videoLibrary()
                    }
                }else{
                    print("restriced manually")
                    self.addAlertForSettings(attachmentTypeEnum)
                }
            })
        case .restricted:
            print("permission restricted")
            self.addAlertForSettings(attachmentTypeEnum)
        default:
            break
        }
    }
    
    
    //MARK: - CAMERA PICKER
    //This function is used to open camera from the iphone and
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .camera
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - PHOTO PICKER
    func photoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    //MARK: - VIDEO PICKER
    func videoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            myPickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    //MARK: - FILE PICKER
    func documentPicker(){
        let importMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        currentVC?.present(importMenu, animated: true, completion: nil)
    }
    
    //MARK: - SETTINGS ALERT
    func addAlertForSettings(_ attachmentTypeEnum: AttachmentType){
        var alertTitle: String = ""
        if attachmentTypeEnum == AttachmentType.camera{
            alertTitle = Constants.alertForCameraAccessMessage
            print(alertTitle)
        }
        if attachmentTypeEnum == AttachmentType.photoLibrary{
            alertTitle = Constants.alertForPhotoLibraryMessage
        }
        if attachmentTypeEnum == AttachmentType.video{
            alertTitle = Constants.alertForVideoLibraryMessage
        }
        
        let cameraUnavailableAlertController = UIAlertController (title: alertTitle , message: nil, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: Constants.settingsBtnTitle, style: .destructive) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: Constants.cancelBtnTitle, style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(cancelAction)
        cameraUnavailableAlertController .addAction(settingsAction)
        currentVC?.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }
    
}

//MARK: - IMAGE PICKER DELEGATE
// This is responsible for image picker interface to access image, video and then responsibel for canceling the picker
extension AttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    //MARK: - IMAGE PICKER
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var Manager : Alamofire.SessionManager = {
            // Create the server trust policies
            let serverTrustPolicies: [String: ServerTrustPolicy] = [
                "your domain goes here": .disableEvaluation
            ]
            // Create custom manager
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
            let man = Alamofire.SessionManager(
                configuration: URLSessionConfiguration.default,
                serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
            )
            return man
        }()
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print("image:\(image)")
            self.imagePickedBlock?(image)
            print("imagePickBlock:\(String(describing: imagePickedBlock))")
            let imageToUploadURL = UIImagePNGRepresentation(image)
            print("imageToUpload:\(String(describing: imageToUploadURL))")
            // your server Upload Address
            let url = "https://217.218.171.90:8444/app_dev.php/telegram/upload"
            let parameters = ["MyPhone" : "*********"]
            
            //MARK: _Upload Code
            // Use Alamofire to upload the image
            
            Alamofire.upload(
                    multipartFormData: { multipartFormData in
//                             On the PHP side you can retrive the image using $_FILES["image"]["tmp_name"]
//                                multipartFormData.append(imageToUploadURL!, withName: "image")
                        if (imageToUploadURL == nil){
                             print("+++imageTo Upload Url is nil+++")
                        }else{print("###imageToUploadURL is not nil###")}
                        multipartFormData.append(imageToUploadURL!, withName: "file", fileName: "file.png", mimeType: "image/png")
                                 for (key, val) in parameters {
                                         multipartFormData.append(val.data(using: String.Encoding.utf8)!, withName: key)
                                     }
                         },
                         to: url, method: .post, headers: nil,
                         encodingCompletion: { encodingResult in
                            print("encode:\(encodingResult)")
                             switch encodingResult {
                             case .success(let upload, _, _):
                                upload.uploadProgress(closure: { (Progress) in
                                    print("Upload Progress: \(Progress.fractionCompleted)")

                                })
                                 upload.responseJSON { response in
                                    print("response:\(response)")
                                     if let jsonResponse = response.result.value as? [String: Any] {
                                        print("jsonResponse:\(jsonResponse)")
                                     }
                                 }
                             case .failure(let encodingError):
                                 print(encodingError)
                             }
                     }
                     )
//            Manager.upload(imageToUploadURL!, to: url, method: .post, headers: nil)
//            print("********Manager Upload*******")
        } else{
            print("Something went wrong in  image")
        }
        
        //MARK: - VIDEO PICKER
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL{
            print("videourl: ", videoUrl)
            //trying compression of video
            let data = NSData(contentsOf: videoUrl as URL)!
            print("File size before compression: \(Double(data.length / 1048576)) mb")
            compressWithSessionStatusFunc(videoUrl)
            let url = "https://217.218.171.90:8444/app_dev.php/telegram/upload"
            let parameters = ["user":"root", "password":"root"]
            print("@@start upload.@@")
            //MARK: _Upload Code
            // Use Alamofire to upload the image
            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(data as Data, withName: "file", fileName: "video.mp4", mimeType: "video/mp4")
//                    multipartFormData.append(("VIDEO".data(using: String.Encoding.utf8, allowLossyConversion: false))!, withName: "Type")
                    for (key, val) in parameters {
                        multipartFormData.append(val.data(using: String.Encoding.utf8)!, withName: key)
                    }
            },
                to: url,
                encodingCompletion: { encodingResult in
                    print("encode:\(encodingResult)")
                    switch encodingResult {
                    case .success(let upload, _, _):
                        print("yeganeh")
                        upload.responseJSON { response in
                            print("response:\(response)")
                            if let jsonResponse = response.result.value as? [String: Any] {
                                print("jsonResponse:\(jsonResponse)")
                            }
                        }
                    case .failure(let encodingError):
                        print(encodingError)
                    }
            }
            )
        }
        else{
            print("Something went wrong in  video")
        }
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Video Compressing technique
    fileprivate func compressWithSessionStatusFunc(_ videoUrl: NSURL) {
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".MOV")
        compressVideo(inputURL: videoUrl as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
                
                DispatchQueue.main.async {
                    self.videoPickedBlock?(compressedURL as NSURL)
                }
                
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    // Now compression is happening with medium quality, we can change when ever it is needed
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
 
    
}

//MARK: - FILE IMPORT DELEGATE
extension AttachmentHandler: UIDocumentMenuDelegate, UIDocumentPickerDelegate{
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        currentVC?.present(documentPicker, animated: true, completion: nil)
    }
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("url", url)
        self.filePickedBlock?(url)
    }
    
    //    Method to handle cancel action.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    //MARK: -UPLOAD FILE
    func requestWith(endUrl: String, imageData: Data?, parameters: [String : Any], onCompletion: ((JSON?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil){
        
        let url = "http://217.218.171.90:8443/app_dev.php/telegram/upload"
        let parameters = ["user":"root", "password":"root"]
        
//        let url = "http://localhost:8888/upload_image.php" /* your API url */
        
        let headers: HTTPHeaders = [
            /* "Authorization": "your_access_token",  in case you need authorization header */
            "Content-type": "multipart/form-data"
        ]
        
        Alamofire.upload(
            multipartFormData: {
                multipartFormData in
                
                    let pdfData = try! Data(contentsOf: url.asURL())
                    let data : Data = pdfData
                    
                    multipartFormData.append(data as Data, withName:"test.pdf", mimeType:"application/pdf")
                    for (key, value) in parameters {
                        multipartFormData.append(((value).data(using: .utf8))!, withName: key)
                    }
                    
                    print("Multi part Content -Type")
                    print(multipartFormData.contentType)
                    print("Multi part FIN ")
                    print("Multi part Content-Length")
                    print(multipartFormData.contentLength)
                    print("Multi part Content-Boundary")
                    print(multipartFormData.boundary)
                
        },
            to: url,
            method: .post,
            headers: headers,
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                    
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        print(" responses ")
                        print(response)
                        print("end responses")
                        onCompletion!(true)
//                        onCompletion(true, "Something bad happen...", 200)
                        
                    }
                case .failure(let encodingError):
                    print(encodingError)
//                    onCompletion(false, "Something bad happen...", 200)
                    onCompletion!(false)

                }
        })
        
//        Alamofire.upload(multipartFormData: { (multipartFormData) in
//            for (key, value) in parameters {
//                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
//            }
//
//            if let data = imageData{
//                multipartFormData.append(data, withName: "image", fileName: "image.png", mimeType: "image/png")
//            }
//
//        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
//            switch result{
//            case .success(let upload, _, _):
//                upload.responseJSON { response in
//                    print("Succesfully uploaded")
//                    if let err = response.error{
//                        onError?(err)
//                        return
//                    }
//                    onCompletion?(nil)
//                }
//            case .failure(let error):
//                print("Error in upload: \(error.localizedDescription)")
//                onError?(error)
//            }
//        }
    }
    

}
