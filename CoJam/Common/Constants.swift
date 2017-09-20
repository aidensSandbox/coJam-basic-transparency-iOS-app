//
//  Constants.swift
//  CoJam
//
//  Created by apple on 8/8/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import Foundation


//MARK:- CONSTS
let kGroupColumnCount = 2
let kSpaceBetweenCell = 5
let kSpaceBetweenCellRow = 10
let kAwarenessIconBorderWidth = CGFloat(1.5)
/*Audio*/
let kDefaultAudioGain = 4 //HV = 4, HE = 2
let kMinimumGainVolume = 0
let kMaximumGainVolume = 20 //HV = 20, HE = 5
/*Default sound when user triggers microphone (System Volume), Ranges from 0.0 to 1.0*/
let kDefaultSystemSound = 0.1  //HV = 0.9, HE = 0.7, HVSafeOption = 0.1


/*Status messages*/
let socialInfoMessage = "Super-you mode music + team!"
let busyInfoMessage = "You will not be interrupted"
let limboInfoMessage = "Connect your headphone!"

let availableTitle = "Sociable"
let busyTitle = "Busy"
let limboTitle = "Limbo mode"

let kMessageWirelessHeadphoneConnected = "We see you have wireless headphones connected, CoJam currently works with wired headphones only as bluetooth has mic delay"
let kMessageHeadphoneWireless = "Wireless headphones feature is currently unavailable."
let kMessageHeadphoneRequired = "Headphone is required to access this feature. Please connect headphone and try again."
let kMessageMicrophonePermission = "Permission to access your Microphone is denied. Please enable it from Settings."

/*User Defaults contants*/
let kSurroundVoice = "kSurroundVoice"
let kPlayMusic = "kPlayMusic"
let kTutorialCompletedKey = "isTutorialCompleted"
let kApplicationBackgroundTime = "applicationBackgroundTime"


/*Notification*/
let kNotificationHeadphoneChanged = Notification.Name("headphoneConnectionStatusChanged")


//MARK:- Feedback
let kFeedbackMailRecipients = ["info@audesis.com"]
let kFeedbackMailSubject = "\(APP_NAME) - User Feedback"
let kFeedbackMailMessage = "Write to us all you want to say about the app..."

//MARK:- Help
let kHelpMailRecipients = ["info@audesis.com"]
let kHelpMailSubject = "\(APP_NAME) - Help Needed"
let kHelpMailBody = "Tell us what the problem is and we will contact you shortly to help you resolve it..."

//MARK:- Invite
let kMessageInviteText = "Hey, join me on the chat group I created on CoJam App and never let headphones hurt your communication with others again. Download the free app from their website \(APP_INVITE_URL). "

//MARK:- Analytics
/**
 Struct to group the events performed for fb-analytics.
 */
struct AnalyticsEvent {
    static let newGroup = "Created New Group"
    static let addedToNewGroup = "Added To New Group"
    static let foreGroundTime = "Foregorund Time"
    static let backGroundTime = "Background Time"
    static let soloAvailableTime = "Solo Available Time"
    static let soloBusyTime = "Solo Busy Time"
    static let groupAvailableTime = "Group Available Time"
    static let groupBusyTime = "Group Busy Time"
    static let selfInteruptionOn = "Self Interruption On"
    static let selfInteruptionOff = "Self Interruption Off"
    static let userInterruptionOn = "User Interrruption On"
    static let userInterruptionOff = "User Interrruption Off"
    static let cojamAllOn = "CoJam All On"
    static let cojamAllOff = "CoJam All Off"
}

struct AnalyticsParameter {
    static let username = "userName"
    static let groupName = "groupName"
    static let email = "email"
    static let time = "time"
    static let triggeringUsername = "tirggeredBy"
}

//MARK:- COLOR
/**Color used in app*/
struct Color {
    static let red = UIColor(red: 248/255, green: 98/255, blue: 99/255, alpha: 1)
    static let green = UIColor(red: 2/255, green: 224/255, blue: 176/255, alpha: 1)
    static let yellow = UIColor(red:246/255, green:198/255, blue:29/255, alpha:1)
    static let black = UIColor.black
}

		
