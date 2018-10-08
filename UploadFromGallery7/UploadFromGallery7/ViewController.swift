//
//  ViewController.swift
//  UploadFromGallery7
//
//  Created by yeganeh on 5/20/18.
//  Copyright © 2018 yeganeh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var AttchObject = AttachmentHandler()
    
    var progressView: UIProgressView?
    var progressLabel: UILabel?
    var timer: Timer?
    var progress: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
//        addControls()
//        addGestures()
        print("ROYA")
        
    }

    @IBAction func BtnOpen(_ sender: Any) {
        AttchObject.showAttachmentActionSheet(vc: self)
    }
    //MARK:- Controls
    func addControls() {
        // Create Progress View Control
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
        progressView?.center = self.view.center
        view.addSubview(progressView!)
        
        // Add Label
        progressLabel = UILabel()
        let frame = CGRect(x: view.center.x - 25, y: view.center.y - 100, width: 100, height: 50)
        progressLabel?.frame = frame
        view.addSubview(progressLabel!)
    }
    
    func addGestures() {
        // Add Single Tap and Doube Tap Gestures
        let tap = UITapGestureRecognizer(target: self, action: Selector(("handleTap:")))
        tap.numberOfTapsRequired = 1
        
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector(("handleDoubleTap:")))
        doubleTap.numberOfTapsRequired = 2
        
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)
    }
    
    // Start Progress View
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector(("updateProgress")), userInfo: nil, repeats: true)
        }
    }
    //MARK:- Double Tap
    // Reset Progress View
    func handleDoubleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            progressView?.progress = 0.0
            progressLabel?.text = "0 %"
            timer?.invalidate()
        }
    }
    
    //MARK:- Increment Progress
    func updateProgress() {
        progressView?.progress += 0.05
        let progressValue = self.progressView?.progress
        progressLabel?.text = "\(progressValue! * 100) %"
    }
    
}

