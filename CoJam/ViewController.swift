//
//  ViewController.swift
//  CoJam
//
//  Created by Alvaro Raminelli on 5/26/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import AVFoundation
import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var gainValue: UILabel!
    @IBOutlet weak var upBtn: UIButton!
    @IBOutlet weak var downBtn: UIButton!
    @IBOutlet weak var awarenessBtn: UIButton!
    @IBOutlet weak var pauseMusic: UISwitch!
    @IBOutlet weak var surroundSound: UISwitch!
    var knocked = false
    var onAwareness = false
    var gain = 6
    var audioProcessor : AudioProcessor? = nil
    
    var window: UIWindow?
    
    let manager = CMMotionManager()
    let motionUpdateInterval : Double = 0.2
    var knockReset : Double = 2.0
    
    //let notificationCenter = NotificationCenter.defaultCenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gainValue.text = String(gain)
        audioProcessor = AudioProcessor()
        audioProcessor?.pauseMusic = self.pauseMusic.isOn;
        audioProcessor?.surroundSound = self.surroundSound.isOn;
        UIApplication.shared.isIdleTimerDisabled = true
        
        //UIApplication.shared.beginReceivingRemoteControlEvents()
        //if UIApplication.shared.canBecomeFirstResponder {
        //  UIApplication.shared.becomeFirstResponder()
        //}
        
        // Remote Control from Headphones
        /*let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
            try audioSession.setActive(true)
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        let scc = MPRemoteCommandCenter.shared()
        scc.togglePlayPauseCommand.isEnabled = true
        scc.togglePlayPauseCommand.addTarget(self, action: #selector(doPlayPause))*/
        
        /*let singleTap = UITapGestureRecognizer(target: self, action:#selector(singleTapAction))
        singleTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTap)*/
        
        /*let doubleTap = UITapGestureRecognizer(target: self, action:#selector(doubleTapAction))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)*/
        
        //singleTap.require(toFail: doubleTap)
        UIApplication.shared.isIdleTimerDisabled = true
        //UIScreen.main.brightness = CGFloat(0.0)
        
        /*notificationCenter.addObserver(self,
                                       selector: #selector(systemVolumeDidChange),
                                       name: "AVSystemController_SystemVolumeDidChangeNotification",
                                       object: nil*/
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            print(AVAudioSession.sharedInstance().outputVolume)
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        //audioSession.addObserver(self, forKeyPath:"outputVolume", options: [.Initial, .New], context: UnsafeMutablePointer<Void>())
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new, .old], context: nil)

        //NotificationCenter.default.addObserver(self, selector: "NotificationVolumeChange:", name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification") , object: nil)

        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = motionUpdateInterval // seconds
            print("isDeviceMotionAvailable")
            manager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: { [weak self] (data, error) in
                
                // ...
                //print("deviceMotion")
                //print(String(format: "X: %.4f",(data?.userAcceleration.x)!))
                //print(String(format: "Y: %.4f",(data?.userAcceleration.y)!))
                //print(String(format: "Z: %.4f",(data?.userAcceleration.z)!))

                
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.async {
                        // >>>>>>>
                        // !!!!MOTION SENSOR TRIGGER CODE GOES HERE!!!
                        //<<<<<<<<<
                        
                        //Read Accelerometer values (m/s^2)
                        //print(String(format: "A-X: %.4f",(data?.userAcceleration.x)!))
                        //print(String(format: "A-Y: %.4f",(data?.userAcceleration.y)!))
                        //print(String(format: "A-Z: %.4f",(data?.userAcceleration.z)!))

                        //Read Rotation Rate (Gyroscope) (rad/s)
                        print(String(format: "G-X: %.4f",(data?.rotationRate.x)!))
                        print(String(format: "G-Y: %.4f",(data?.rotationRate.y)!))
                        print(String(format: "G-Z: %.4f",(data?.rotationRate.z)!))
                        
                        //Read attitude (Yaw, pitch, roll)
                        //print(String(format: "Yaw: %.4f",(data?.attitude.yaw)!))
                        //print(String(format: "Pitch: %.4f",(data?.attitude.pitch)!))
                        //print(String(format: "Roll: %.4f",(data?.attitude.roll)!))
                        
                        //Read gravity (phone's tilt and position)
                        //print(String(format: "T-X: %.4f",(data?.gravity.x)!))
                        //print(String(format: "T-Y: %.4f",(data?.gravity.y)!))
                        //print(String(format: "T-Z: %.4f",(data?.gravity.z)!))
                        
                        //Read Magnetic field
                        //print(String(format: "M-X: %.4f",(data?.magneticField.x)!))
                        //print(String(format: "M-Y: %.4f",(data?.magneticField.y)!))
                        //print(String(format: "M-Z: %.4f",(data?.magneticField.z)!))
                        
                        //if (fabs((data?.userAcceleration.y)!) > Double(0.4)) && (fabs((data?.userAcceleration.z)!) < Double(0.2)){
                        if (fabs((data?.rotationRate.z)!) > Double(3.5)){
                            //FUTURE ADDITION: Add code to determine that the first spin has a positive value and is 4.5 rad/s or more,
                            //then the second spin needs to be with a negative value, and is equal to (4.5 rad/s + or - 40%) to compensate for
                            //user's inconsistent spin force
                            
                            // Check for double spin
                            if self?.knocked == false {
                                // First knock
                                print("First Movement")
                                //Read Accelerometer values
                                //print(String(format: "A-X: %.4f",(data?.userAcceleration.x)!))
                                //print(String(format: "A-Y: %.4f",(data?.userAcceleration.y)!))
                                //print(String(format: "A-Z: %.4f",(data?.userAcceleration.z)!))

                                self?.knocked = true
                                
                            }else{
                                // Second knock
                                print("Second Movement")
                                self?.knocked = false
                                // Action:
                                self?.toggleAwareness()
                                //self?.knockReset = 0.1
                                self?.knockReset = 2.0
                                print("Reset 2.0")
                                
                            }
                            
                        }
                        
                        if (self?.knocked)! && (self?.knockReset)! >= Double(0.0) {
                            
                            self?.knockReset = (self?.knockReset)! - (self?.motionUpdateInterval)!
                            
                        }else if self?.knocked == true {
                            self?.knocked = false
                            self?.knockReset = 2.0
                            print("Reset 2.0")
                        }
                        
                    }
                }
                
            })

        }

    }
    
    func handleMove(motion: CMDeviceMotion?, error: Error?) {
        print("handleMove")
        
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            print("got in here")
            
            print(AVAudioSession.sharedInstance().outputVolume)
            /*if audioSession.outputVolume > vol{
                upOrDown = "UP"
                print(upOrDown)
                
            }
            if audioSession.outputVolume < vol{
                upOrDown = "DOWN"
                print(upOrDown)
            }
            vol = 0.5
            
            (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(0.5, animated: false)
            MPVolumeSettingsAlertHide()*/
        }
    }
    
    func NotificationVolumeChange(notification : NSNotification?) {
        
        /*if shutterButton.enabled == true {
            shutterButtonAction(shutterButton)
        }
        volumeSlider.value = initialVolume*/
        print("NotificationVolumeChange");
    }
    
    /*override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notificationCenter.removeObserver(self)
    }*/
    
    // MARK: AVSystemPlayer - Notifications
    
    func systemVolumeDidChange(notification: NSNotification) {
        print("** AVSystemController_AudioVolumeNotificationParameter **")
        //print(notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? Float)
    }

    func doubleTapAction() {
        // do something cool here
        print("doubleTapAction")
        if onAwareness {
            print("** onAwareness off **")
            
            //audioProcessor!.stop()
            deactiveAwareness()
        }else{
            print("** onAwareness on **")
            activeAwareness()
            
        }
    }
    
    func toggleAwareness() {
        // do something cool here
        print("doubleTapAction")
        if onAwareness {
            print("** onAwareness off **")
            
            //audioProcessor!.stop()
            deactiveAwareness()
        }else{
            print("** onAwareness on **")
            activeAwareness()
            
        }
    }
    
    /*func listenVolumeButton() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            print("got in here")
        }
    }
    */
    deinit {
        //let scc = MPRemoteCommandCenter.shared()
        //scc.togglePlayPauseCommand.removeTarget(self)
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
    }

    
    func doPlayPause(_ event:MPRemoteCommandEvent) {
        if onAwareness {
            print("** onAwareness off **")
            
            //audioProcessor!.stop()
            deactiveAwareness()
        }else{
            print("** onAwareness on **")
            activeAwareness()
            
        }
    }
    
    @IBAction func upGain(_ sender: UIButton) {
        gain += 1
        audioProcessor?.gain = Float(gain)
        self.gainValue.text = String(gain)
        
    }
    @IBAction func downGain(_ sender: UIButton) {
        gain -= 1
        audioProcessor?.gain = Float(gain)
        self.gainValue.text = String(gain)
    }
    
    @IBAction func surroundSoundChanged(_ sender: UISwitch) {
        print("Surround Sound Switched")
        print(sender.isOn)
        audioProcessor?.surroundSound = sender.isOn
        
        /*if onAwareness {
            audioProcessor!.stop()
            audioProcessor!.start()
        }*/
    }
    
    @IBAction func pauseMusicChanged(_ sender: UISwitch) {
        print("Pause Music Switched")
        print(sender.isOn)
        audioProcessor?.pauseMusic = sender.isOn
    }
    @IBAction func awarenessAction(_ sender: UIButton) {
        //code to enable touch of button "touch"
        if onAwareness {
            print("** onAwareness off **")
            
            //audioProcessor!.stop()
            deactiveAwareness()
        }else{
            print("** onAwareness on **")
            activeAwareness()
            
        }
    }
    
    func activeAwareness() {
        onAwareness = true;
        self.awarenessBtn.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.surroundSound.isEnabled = false;
        self.pauseMusic.isEnabled = false;
        print("USER TOUCHED BUTTON")
        audioProcessor!.start()
    }
    
    
    func deactiveAwareness(){
        onAwareness = false;
        self.awarenessBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        self.surroundSound.isEnabled = true;
        self.pauseMusic.isEnabled = true;
        audioProcessor!.stop()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

