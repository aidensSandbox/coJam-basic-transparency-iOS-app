/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/
import Foundation
import UIKit
import ParseLiveQuery

// EDIT THE RED STRING BELOW ACCORDINGLY TO THE NEW NAME YOU'LL GIVE TO THIS APP
let APP_NAME = "CoJam"
let APP_SITE = "https://audesis.com/"


// YOU CAN CHANGE THE VALUE OF THE MAX. DURATION OF A RECORDING (PLEASE NOTE THAT HIGHER VALUES MAY AFFET THE LOADING TIME OF POSTS)
let RECORD_MAX_DURATION: TimeInterval = 10.0



// YOU CAN CHANGE THE TIME WHEN THE APP WILL REFRESH THE CHATS (PLEASE NOTE THAT A LOW VALUE MAY AFFECT THE STABILITY OF THE APP, WE THINK 30 seconds A GOOD MINIMUM REFRESH TIME)
let REFRESH_TIME: TimeInterval = 20.0



// REPLACE THE RED STRING BELOW WITH YOUR OWN BANNER UNIT ID YOU'VE GOT ON http://apps.admob.com
let ADMOB_UNIT_ID = "ca-app-pub-9733347540588953/7805958028"



// REPLACE THE RED STRING BELOW WITH THE LINK TO YOUR OWN APP (You can find it on iTunes Connect, click More -> View on the App Store)
let APPSTORE_LINK = "https://itunes.apple.com/app/id957290825"


// REPLACE THE RED STRING BELOW WITH YOUR APP ID (still on iTC, click on More -> About this app)
let APP_ID = "957290825"



// HUD View
let hudView = UIView(frame: CGRect(x:0, y: 0, width: 80, height:80))
let indicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:0, width:80, height: 80))
extension UIViewController {
    func showHUD() {
        hudView.center = CGPoint(x: view.frame.size.width/2, y:view.frame.size.height/2)
        hudView.backgroundColor = UIColor.darkGray
        hudView.alpha = 0.9
        hudView.layer.cornerRadius = hudView.bounds.size.width/2

        indicatorView.center = CGPoint(x: hudView.frame.size.width/2, y: hudView.frame.size.height/2)
        indicatorView.activityIndicatorViewStyle = .white
        indicatorView.color = UIColor.white
        hudView.addSubview(indicatorView)
        indicatorView.startAnimating()
        view.addSubview(hudView)
    }
    func hideHUD() { hudView.removeFromSuperview() }

  func simpleAlert(_ mess:String) {
        UIAlertView(title: APP_NAME, message: mess, delegate: nil, cancelButtonTitle: "OK").show()
    }
}


//AUDIO
var knocked = false
var onAwareness = false
var gain = 6
//var audioProcessor : AudioProcessor? = nil
//let manager = CMMotionManager()
//let motionUpdateInterval : Double = 0.2
//var knockReset : Double = 2.0


// PARSE KEYS ------------------------------------------------------------------------
let PARSE_APP_KEY = "KJsBLVPpbDTU1MlGQfg7z00Ig0ogL6sGztBCa2HJ"
let PARSE_CLIENT_KEY = "f8GmmDpIcbYHc9z0qxGUZQvHe2qCXBslRnP0Nsf3"



/*************** DO NOT EDIT THE CODE BELOW! *************/

var audioURLStr = ""
var tenMessLimit = UserDefaults.standard.bool(forKey: "tenMessLimit")

let STATUS_AVAILABLE = "available"
let STATUS_BUSY = "busy"
let AWARENESS_STATUS = false

let USER_USERNAME = "username"
let USER_AVATAR = "avatar"
let USER_CURRENTROOM = "currentRoom"
let USER_STATUS = "status"
let USER_STATUS_TIME = "userStatusTime"
let IS_LIMBO = "isLimbo"
let FORCED_AWARENESS_OFF = "forcedAwarenessOff"


let CHAT_CLASS_NAME = "ChatRooms"
let CHAT_USER_POINTER = "userPointer"
let CHAT_ROOM_NAME = "name"
let CHAT_ROOM_POINTER = "roomPointer"
let CHAT_MESSAGE = "message"
let CHAT_IS_REPORTED = "isReported"


let ROOMS_CLASS_NAME = "Rooms"
let ROOMS_NAME = "name"
let ROOMS_IMAGE = "image"
let ROOMS_USER_POINTER = "userPointer"
let ROOM_MEMBERS = "roomMembersArray"
let ROOM_MEMBERS_AWARENESS_ENABLED = "membersAwarenessEnbaled"


let CODEJAM_CLASS_NAME = "CodeJam"
let CODEJAM_NAME = "name"
let CODEJAM_USER_POINTER = "userPointer"

let CODEJAM_EVENT_CLASS_NAME = "CodeJamEvent"
let CODEJAM_EVENT_NAME = "name"
let CODEJAM_EVENT_USER_POINTER = "userPointer"

let CODEJAM_INVITE_CLASS_NAME = "CodeJamInvite"
let CODEJAM_INVITE_USER_POINTER = "userPointer"
let CODEJAM_INVITE_ROOM_POINTER = "roomPointer"

let USERCODEJAM_CLASS_NAME = "UserCodeJam"
let USERCODEJAM_USER_POINTER = "userPointer"
let USERCODEJAM_CODEJAM_POINTER = "codeJamPointer"
let USERCODEJAM_USER_STATUS = "status"
let AWARENESS = "awareness"

let liveQueryClient: Client = ParseLiveQuery.Client(server: "wss://audesis.back4app.io", applicationId:PARSE_APP_KEY, clientKey:PARSE_CLIENT_KEY)







