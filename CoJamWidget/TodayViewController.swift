//
//  TodayViewController.swift
//  CoJamWidget
//
//  Created by Ahmed Ibrahim on 6/4/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import AVFoundation
import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
//    @IBOutlet weak var widgetAwarenessBtn: UIButton!
//    
//    var widgetOnAwareness = false
//    var audioProcessor : AudioProcessor? = nil
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        audioProcessor = AudioProcessor()
//        audioProcessor?.pauseMusic = true;
//        audioProcessor?.surroundSound = true;
//        
//        // Do any additional setup after loading the view from its nib.
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
//        // Perform any setup necessary in order to update the view.
//        
//        // If an error is encountered, use NCUpdateResult.Failed
//        // If there's no update required, use NCUpdateResult.NoData
//        // If there's an update, use NCUpdateResult.NewData
//        
//        completionHandler(NCUpdateResult.newData)
//    }
//    
//  
//    @IBAction func widgetAwarenessAction(_ sender: UIButton) {
//        
//        //code to enable touch of button "touch"
//        if widgetOnAwareness {
//            print("** Widget - onAwareness off **")
//            
//            //audioProcessor!.stop()
//            deactiveAwareness()
//        }else{
//            print("** Widget -onAwareness on **")
//            activeAwareness()
//            
//        }
//        
//    }
//    
//    func activeAwareness() {
//        widgetOnAwareness = true;
//        self.widgetAwarenessBtn.setTitleColor(UIColor.red, for: UIControlState.normal)
//        //self.surroundSound.isEnabled = false;
//        //self.pauseMusic.isEnabled = false;
//        //audioProcessor!.start()
//    }
//    
//    
//    func deactiveAwareness(){
//        widgetOnAwareness = false;
//        self.widgetAwarenessBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
//        //self.surroundSound.isEnabled = true;
//        //self.pauseMusic.isEnabled = true;
//        //audioProcessor!.stop()
//    }
//    
    
}
