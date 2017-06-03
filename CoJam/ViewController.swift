//
//  ViewController.swift
//  CoJam
//
//  Created by Alvaro Raminelli on 5/26/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var gainValue: UILabel!
    @IBOutlet weak var upBtn: UIButton!
    @IBOutlet weak var downBtn: UIButton!
    @IBOutlet weak var awarenessBtn: UIButton!
    @IBOutlet weak var pauseMusic: UISwitch!
    @IBOutlet weak var surroundSound: UISwitch!
    
    var onAwareness = false
    var gain = 6
    var audioProcessor : AudioProcessor? = nil
    
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
        
        let doubleTap = UITapGestureRecognizer(target: self, action:#selector(doubleTapAction))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        
        //singleTap.require(toFail: doubleTap)
        UIApplication.shared.isIdleTimerDisabled = true
        //UIScreen.main.brightness = CGFloat(0.0)
        
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
    
    deinit {
        //let scc = MPRemoteCommandCenter.shared()
        //scc.togglePlayPauseCommand.removeTarget(self)
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

