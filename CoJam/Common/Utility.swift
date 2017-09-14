//
//  Utility.swift
//  CoJam
//
//  Created by apple on 8/8/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import AlamofireImage
import Parse
import SwiftMessages


class Utility: NSObject {
    /**
     Send the Analytics event with name and prameter.
     - Parameters:
        - name: event name, eg: group created, etc.
        - param: pass the values inside(supporting) the event, eg: group_name, etc.
        - value: the value to added.
     */
    class func sendEvent(name: String, value: Double = 1, param: [String: Any]) {
        print("analytics:\(name), params: \(param), value(Min):\(value)")
        FBSDKAppEvents.logEvent(name, valueToSum: value, parameters: param)
    }
    
    /**
     Send the Analytics event with name only.
     - Parameter name: event name, eg: group created, etc.
     */
    class func sendEvent(name: String){
        print("analytics:\(name)")
        FBSDKAppEvents.logEvent(name, valueToSum: 1)
    }
    class func stringFromTime(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02dH:%02dM:%02dS", hours, minutes, seconds)
    }
    
    /**
     This method is used to check if headphone is connected or not.
     - Returns : if headphone connected then return true otherwise false.
     */
    class func isHeadphoneConnected() -> Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        var isConnected = false
        for discription in currentRoute.outputs {
            if discription.portType == AVAudioSessionPortHeadphones {
                isConnected = true
                break
            }
        }
        return isConnected
    }
    
    /**
     This method is used to check whether user is connected to Wireless headphone or not.
     - Returns : "true" if Wireless headphone is connected otherwise "false". 
     */
    class func isWirelessHeadphoneConnected() -> Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        var isConnected = false
        for discription in currentRoute.inputs {
            if discription.portType == AVAudioSessionPortBluetoothHFP {
                isConnected = true
                break
            }
        }
        return isConnected
    }
    
    /**
     This method is used to set the profile image async.
     - Parameters:
        - view: The image view, ImageView
        - imageFile: The parse image file, PFFile
     */
    class func setImage(view: UIImageView, imageFile: PFFile?){
        if let url = URL(string: imageFile?.url ?? "") {
            view.af_setImage(withURL: url, placeholderImage: UIImage(named: "logo"), filter: nil, progress: nil, progressQueue: .global(), imageTransition: .noTransition, runImageTransitionIfCached: false, completion: nil)
        }
        else{
            view.image = UIImage(named: "logo")
        }
    }
    
    /**
     This method is used to show warning with a message give.
     - Parameter message: The to be shown in warning message, String.
     */
    class func showAlertWith(message: String, type: Theme = .error) {
        let messageView = MessageView.viewFromNib(layout: .CardView)
        messageView.configureTheme(type)
        messageView.configureDropShadow()
        messageView.configureContent(title: APP_NAME, body: message)
        messageView.button?.isHidden = true
        var warningConfig = SwiftMessages.defaultConfig
        warningConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.show(config: warningConfig, view: messageView)
    }
    
    
    /**
     This method used to check if user give access to microphone.
     - Returns : Retruns true if access granded otherwise false.
     */
    class func isMicrophonePermissionEnabled() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            return true
            
        case AVAudioSessionRecordPermission.denied, AVAudioSessionRecordPermission.undetermined:
            return false
            
        default:
            break
        }
        return false
    }
    
    
    /**
     This method is to show the tutorial about the application.
     - Parameter controller: The viewcontroller which is presenting tutorial.
     */
    class func showTutorialScreen(on controller: UIViewController) {
        let path = Bundle.main.path(forResource: "panels", ofType: "json")
        let panels = SRFSurfboardViewController.panelsFromConfiguration(atPath: path)
        let panelController = SRFSurfboardViewController()
        panelController.setPanels(panels)
        panelController.backgroundColor = UIColor.white
        panelController.tintColor = UIColor.black
        let selectedPageColor = UIColor(colorLiteralRed: 2/255, green: 224/255, blue: 176/255, alpha: 1)
        panelController.setPageControl(UIColor.lightGray, andSelectedColor: selectedPageColor)
        
        panelController.delegate = controller as! SRFSurfboardDelegate
        controller.present(panelController, animated: true, completion: nil)
    }
    
    /**
     Method to send analytics of user triggered mic.
     */
    class func sendSelfInterruptionAnalytics() {
        let event = User.shared.awarenessMode ? AnalyticsEvent.selfInteruptionOn : AnalyticsEvent.selfInteruptionOff
        let params = [
            AnalyticsParameter.username: PFUser.current()!.username ?? "",
            AnalyticsParameter.email: PFUser.current()!.email ?? ""
        ]
        Utility.sendEvent(name: event, param: params)
    }
    
    /**
     Method to set the system volume. Ranges from, 0.0 to 1.0
     */
    class func updateSystemVolume() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            let volumeView = MPVolumeView()
            volumeView.showsRouteButton = false
            volumeView.showsVolumeSlider = true
            if let view = volumeView.subviews.first as? UISlider{
                view.value = Float(kDefaultSystemSound)
            }
        })
        
    }
}

