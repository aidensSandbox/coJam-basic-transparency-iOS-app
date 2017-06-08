//
//  AppDelegate.swift
//  Swift testing
//
//  Created by Mateusz Nuckowski on 27/06/16.
//  Copyright © 2016 Mat Nuckowski. All rights reserved.
//
import UIKit
import CoreMotion
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let motionMgr = CMMotionManager()
    var notificationShown = false
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    var myTimer: Timer?
    var notificationTimer: Timer?
    
    func isMultitaskingSupported() -> Bool
    {
        return UIDevice.current.isMultitaskingSupported
    }
    
    func timerMethod(sender: Timer)
    {
        startMotionDetection()
        let backgroundTimeRemaining =
            UIApplication.shared.backgroundTimeRemaining
        if backgroundTimeRemaining == .greatestFiniteMagnitude
        {
            print("Background Time Remaining = Undetermined")
        } else {
            print("Background Time Remaining = " +
                "\(backgroundTimeRemaining) Seconds")
        }
        
    }
    
    func resetNotifications()
    {
        notificationShown = false
    }
    
    func motionRefresh()
    {
        if let pitch = motionMgr.deviceMotion?.attitude.pitch
        {
            print(pitch)
            if pitch < 0.5 && !notificationShown
            {
                /*let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey:
                    "Posture alert", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey:
                    "Please correct your posture", arguments: nil)
                
                // Deliver the notification in five seconds.
                content.sound = UNNotificationSound.default()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                                repeats: false)
                
                // Schedule the notification.
                let request = UNNotificationRequest(identifier: "Posture", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.add(request, withCompletionHandler: nil)*/
                notificationShown = true
                notificationTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self,
                                                         selector: #selector(self.resetNotifications), userInfo: nil, repeats: false)
                motionMgr.stopDeviceMotionUpdates()
            }
        }
        
    }
    
    func startMotionDetection()
    {
        motionMgr.deviceMotionUpdateInterval = 0.1
        
        let motionDisplayLink = CADisplayLink(target: self, selector: #selector(motionRefresh))
        motionDisplayLink.add(to: .current, forMode: .defaultRunLoopMode)
        
        if motionMgr.isDeviceMotionAvailable
        {
            motionMgr.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
            print("Start motion detection")
        }
        //
        //        if ([self.motionManager isDeviceMotionAvailable]) {
        //            // to avoid using more CPU than necessary we use `CMAttitudeReferenceFrameXArbitraryZVertical`
        //            [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
        //        }
    }
    
    func endBackgroundTask(){
        
        print ("END BACKGROUND")
        let mainQueue = DispatchQueue.main
        
        mainQueue.async {
            if let timer = self.myTimer {
                timer.invalidate()
                self.myTimer = nil
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
        }
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        
        if !isMultitaskingSupported()
        {
            return
        }
        
        myTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self,
                                       selector: #selector(self.timerMethod(sender:)), userInfo: nil, repeats: true)
        
        
        backgroundTaskIdentifier = application.beginBackgroundTask(expirationHandler: {
            self.endBackgroundTask()
        })
        
        
        
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.endBackgroundTask()
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}
