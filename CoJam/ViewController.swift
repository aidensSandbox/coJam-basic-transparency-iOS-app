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
            onAwareness = false;
            self.awarenessBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
            //audioProcessor!.stop()
            deactiveAwareness()
        }else{
            onAwareness = true;
            print("** onAwareness on **")
            self.awarenessBtn.setTitleColor(UIColor.red, for: UIControlState.normal)
            activeAwareness()
            
        }
    }
    
    func activeAwareness() {
        self.surroundSound.isEnabled = false;
        self.pauseMusic.isEnabled = false;
        audioProcessor!.start()
    }
    
    
    func deactiveAwareness(){
        self.surroundSound.isEnabled = true;
        self.pauseMusic.isEnabled = true;
        audioProcessor!.stop()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

