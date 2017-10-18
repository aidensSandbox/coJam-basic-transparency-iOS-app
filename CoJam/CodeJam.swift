/*-------------------------
 
 - Audesis -
 
 created by Alvaro Raminelli © 2017
 All Rights reserved
 
 -------------------------*/

import UIKit
import Parse
import AudioToolbox
import ParseLiveQuery
import AVFoundation
import CoreMotion

class User{
    // Can't init is singleton
    private init() { }
    // MARK: Shared Instance
    static let shared = User()
    var status = STATUS_AVAILABLE
    var currentRoom:PFObject?
    var awarenessMode = false
    var imageFile = UIImage(named: "logo")
    var audioProcessor : AudioProcessor? = nil
    var isUserStatusLimbo = false
}


// MARK:- ROOMS CONTROLLER
class CodeJam: UIViewController,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UISearchBarDelegate
{
    
    /* Views */
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var awarenessIcon: UIImageView!
    
    @IBOutlet weak var viewStatusInfoMessage: UIView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelStatusMessage: UILabel!
    @IBOutlet weak var viewSwipeHeader: UIView!
    @IBOutlet weak var viewCircular: UIView!
    @IBOutlet var viewProfile: UIView!
    @IBOutlet weak var viewActivityContainer: UIView?
    @IBOutlet weak var activityIndicatorUserAwareness: UIActivityIndicatorView?
    
   
    /* Variables */
    var knocked = false
    var onAwareness = false
    var audioProcessor : AudioProcessor? = nil
    let manager = CMMotionManager()
    let motionUpdateInterval : Double = 0.2
    var knockReset : Double = 2.0
    fileprivate var currentHeaderIndex = 0
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.awarenessIcon.isHidden = User.shared.awarenessMode ? false : true
        self.awarenessIcon.layer.cornerRadius = self.awarenessIcon.frame.size.width / 2
        self.awarenessIcon.clipsToBounds = true
        self.awarenessIcon.layer.borderWidth = kAwarenessIconBorderWidth
        self.awarenessIcon.layer.borderColor = Color.black.cgColor
        
        if PFUser.current() == nil {
            showLoginController()
            
        } else {
            let isTutorialCompleted = UserDefaults.standard.bool(forKey: kTutorialCompletedKey)
            if !isTutorialCompleted {
                Timer.scheduledTimer(timeInterval: TimeInterval(0.5), target: self, selector: #selector(checkAndShowTutorial), userInfo: nil, repeats: false)
                return
            }
            let limbo = !(Utility.isMicrophonePermissionEnabled() && Utility.isHeadphoneConnected())
            User.shared.isUserStatusLimbo = limbo
            
            showUserDetails()
            setStatus()
            
            // Associate the device with a user for Push Notifications
            let installation = PFInstallation.current()
            installation?["username"] = PFUser.current()!.username
            installation?["userID"] = PFUser.current()!.objectId ?? ""
            installation?.saveInBackground(block: { (succ, error) in
                if error == nil {
                }
            })
            //subscribeToInvitation()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        initilize()
        //customizeHeader()
        addSwipeGestureToHeader()
    }
    
    /**
     This method is called when user initial login. Used to show the tutorial screen
     */
    @objc fileprivate func checkAndShowTutorial() {
        //Check to is tutorial already
        Utility.showTutorialScreen(on: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    

    /**
     Overriding var to change the status-bar color.
     */
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    //MARK:- Notification
    
    /**
     This function is used to remove the NSNotification.Name.AVAudioSessionRouteChange.
     */
    fileprivate func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    fileprivate func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(audioNotificationChanged(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    @objc fileprivate func applicationDidBecomeActive(_ notification: Notification) {
        /**
         Check Headphone is plugged in or not. and setting is user is limbo.
         */
        checkAndSetUserLimbo()
    }
    
    
    /**
     Notification listner to handle user limbo status,
     headphone pluged then IS_LIMBO = FALSE and 
     headphone removed then IS_LIMBO = TRUE
     */
    func audioNotificationChanged(_ notification: Notification) {
        if PFUser.current() == nil {
            return
        }
        
        let audioRouteChanged = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        switch audioRouteChanged {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable.rawValue:
            print("pluged in")
            if Utility.isWirelessHeadphoneConnected() {
                showAlert(message: kMessageWirelessHeadphoneConnected)
            }
            else if Utility.isHeadphoneConnected() {
                print("pluged in Headphone")
                let awareness = PFUser.current()![AWARENESS] as? Bool ?? false
                User.shared.awarenessMode = User.shared.awarenessMode || awareness
                if User.shared.awarenessMode {
                    User.shared.audioProcessor?.start()
                }
                User.shared.isUserStatusLimbo = false
                setUserLimbo(status: false)
                setUserStatusTime()
            }
            break
            
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue:
            print("unpluged")
            setUserLimbo(status: true)
            if User.shared.awarenessMode {
                User.shared.audioProcessor?.stop()
            }
            sendAnalyticsWhenUserLimbo()
            
            break
        default:
            break
        }
    }
    
    /**
     This function is used to save the current user limbo status.
     - Parameter status : is headphone plugged then "false" else "true"
     */
    fileprivate func setUserLimbo(status: Bool) {
        DispatchQueue.main.async {
            //let awareness = PFUser.current()![AWARENESS] as? Bool ?? false
            self.awarenessIcon.isHidden = status || !User.shared.awarenessMode
        }
        
        saveUserLimbo(status: status)
        NotificationCenter.default.post(name: kNotificationHeadphoneChanged, object: nil)
    }
    
    /**
     This function is used to save the user Limbo status to remote db.
     - Parameter status: 
     */
    fileprivate func saveUserLimbo(status: Bool) {
        User.shared.isUserStatusLimbo = status
        guard let currentUser = PFUser.current() else {
            return
        }
        setStatus()
        currentUser[IS_LIMBO] = status
        currentUser.saveInBackground(block: { (success, error) in
            if error != nil {
                print(error)
            }
        })
    }
    
    
    @IBAction func didTappedHelpButton(_ sender: Any) {
        Utility.showTutorialScreen(on: self)
    }
    
    
    //MARK:- Initialize
    
    fileprivate func initilize() {
        labelStatus.text = ""
        labelStatusMessage.text  = ""
        
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 6.0 //4.0
        self.profileImg.layer.masksToBounds = true
        
        viewActivityContainer?.layer.cornerRadius = profileImg.layer.cornerRadius
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(tapGestureRecognizer)
        
        viewActivityContainer?.isHidden = true
        activityIndicatorUserAwareness?.stopAnimating()
        
        print("@@@@@@@@@@@@@@@@")
        print("Setup Audio")
        print("@@@@@@@@@@@@@@@@")
        User.shared.audioProcessor = AudioProcessor()
        User.shared.audioProcessor?.pauseMusic = false;
        User.shared.audioProcessor?.surroundSound = true;
        User.shared.audioProcessor?.gain = Float(kDefaultAudioGain)
     
        /**
         Check Headphone is plugged in or not. and setting is user is limbo.
         */
        checkAndSetUserLimbo()
        
        if PFUser.current() != nil {
            //_ = try? PFUser.current()?.fetch()
            PFUser.current()?.fetchInBackground(block: { (_, error) in
                User.shared.status = PFUser.current()![USER_STATUS] as? String ?? STATUS_AVAILABLE
                print("Currentuser:", PFUser.current()!)
            })
            UIApplication.shared.isIdleTimerDisabled = true
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                print(AVAudioSession.sharedInstance().outputVolume)
            }
            catch {
                print("Setting category to AVAudioSessionCategoryPlayback failed.")
            }
        }
    }
    
    /**
     Method check the user headphone is connected and permission is enabled and decide limbo or not.
     */
    fileprivate func checkAndSetUserLimbo() {
        let limbo = !(Utility.isMicrophonePermissionEnabled() && Utility.isHeadphoneConnected())
        saveUserLimbo(status: limbo)
    }
    
    
    
    fileprivate func showLoginController() {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
        present(loginVC, animated: true, completion: nil)
    }
    
    /**
     This function is used to show the settings page to enable microphone permission.
     */
    fileprivate func showSettings() {
        let action = {(action: UIAlertAction) -> Void in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url as URL)
            }
        }
        self.showConfirmAlert(message: kMessageMicrophonePermission, okTitle: "Settings", completionHandler: action)
    }
    
    /**This function is used to request */
    fileprivate func requestForMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granded) in
                if granded {
                    self.saveUserLimbo(status: !Utility.isHeadphoneConnected() )
                }
            })
            
        case AVAudioSessionRecordPermission.denied:
            self.showSettings()
            break
        default:
            break
        }
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer){
        if !Utility.isMicrophonePermissionEnabled() {
            requestForMicrophonePermission()
            return
        }
        else if Utility.isWirelessHeadphoneConnected() {
            Utility.showAlertWith(message: kMessageHeadphoneWireless)
            return
        }
        else if !Utility.isHeadphoneConnected() {
            Utility.showAlertWith(message: kMessageHeadphoneRequired)
            return
        }
        
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false;
            self.awarenessIcon.isHidden = true;
            User.shared.audioProcessor?.stop()
        } else{
            User.shared.awarenessMode = true;
            self.awarenessIcon.isHidden = false;
            
            User.shared.audioProcessor?.start()
            //Utility.updateSystemVolume()
        }
        viewActivityContainer?.isHidden = false
        activityIndicatorUserAwareness?.startAnimating()
        
        self.setStatus()
        self.saveUserAwareness()
        
        profileImg.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        viewActivityContainer?.transform = profileImg.transform
        UIView.animate(withDuration: TimeInterval(0.5), animations: {
            self.profileImg.transform = CGAffineTransform.identity
            self.viewActivityContainer?.transform = self.profileImg.transform
        })
        
        Utility.sendSelfInterruptionAnalytics()
    }
    
    /**
     This method is used to update the current user awareness state.
     */
    fileprivate func saveUserAwareness() {
        
        let updatedUser = PFUser.current()!
        updatedUser[AWARENESS] = User.shared.awarenessMode
        updatedUser.saveInBackground { (success, error) -> Void in
            DispatchQueue.main.async {
                self.viewActivityContainer?.isHidden = true
                self.activityIndicatorUserAwareness?.stopAnimating()
            }
        }
    }
    
    
    // MARK: - SHOW CURRENT USER DETAILS
    func showUserDetails() {
        guard let currentUser = PFUser.current() else {
            print("-Unauthenicated user")
            return
        }
        
        // Get avatar
        self.profileImg.image = UIImage(named: "logo")
        let imageFile = currentUser[USER_AVATAR] as? PFFile
        Utility.setImage(view: profileImg, imageFile: imageFile)
        
    }
    
    func setStatus(){
        viewStatusInfoMessage.alpha = 0.5
        if User.shared.isUserStatusLimbo {
            DispatchQueue.main.async {
                self.profileImg.layer.borderColor = Color.yellow.cgColor
                self.labelStatus.text = limboTitle.capitalized
                self.labelStatusMessage.text = limboInfoMessage
                self.awarenessIcon.isHidden = true
            }
        }
        else if User.shared.status == STATUS_AVAILABLE{
            currentHeaderIndex = 0
            DispatchQueue.main.async {
                self.labelStatus.text = availableTitle.capitalized
                self.labelStatusMessage.text = socialInfoMessage
                
                self.labelStatusMessage.updateConstraintsIfNeeded()
                UIView.animate(withDuration: TimeInterval(1.0), animations: {
                    self.viewStatusInfoMessage.alpha = 1
                })
                
                self.profileImg.clipsToBounds = true
                self.profileImg.layer.borderColor = Color.green.cgColor
            }
            
        } else{
            currentHeaderIndex = 1
            DispatchQueue.main.async {
                self.labelStatus.text = busyTitle.capitalized
                self.labelStatusMessage.text = busyInfoMessage
                
                self.labelStatusMessage.updateConstraintsIfNeeded()
                UIView.animate(withDuration: TimeInterval(1.0), animations: {
                    self.viewStatusInfoMessage.alpha = 1
                })
                
                self.profileImg.clipsToBounds = true
                self.profileImg.layer.borderColor = Color.red.cgColor
            }
        }
        
        //only set the USER_STATUS_TIME is null and clears when user logout.
        setUserStatusTime()
    }
    
    /**
     This method is used to save the USER_STATUS.
     */
    fileprivate func saveUserStatus(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_STATUS] = User.shared.status
        viewActivityContainer?.isHidden = false
        activityIndicatorUserAwareness?.startAnimating()
        updatedUser.saveInBackground { (success, error) -> Void in
            DispatchQueue.main.async {
                self.viewActivityContainer?.isHidden = true
                self.activityIndicatorUserAwareness?.stopAnimating()
            }
        }
    }
    
    
    
    /**
     This method is used to set the USER_STATUS_TIME when user is only available.
     */
    fileprivate func setUserStatusTime() {
        if !User.shared.isUserStatusLimbo && (PFUser.current()![USER_STATUS_TIME] is NSNull || PFUser.current()![USER_STATUS_TIME] == nil) {
            PFUser.current()![USER_STATUS_TIME] = Date()
            PFUser.current()?.saveInBackground()
        }
    }
    
    
    //MARK:- ANALYTICS
    /**
     This function is used to send the user available and busy state time
     - Parameter isCurrentStatus: This parameter is used to determine, should pass the current status or not.
     */
    fileprivate func sendUserStatusAnalytics(isCurrentStatus: Bool = false) {
        if User.shared.isUserStatusLimbo {
            return
        }
        if User.shared.status == STATUS_AVAILABLE {
            // send busy time if not logout else available time.
            // his/her previous state is busy.
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                let event = isCurrentStatus ? AnalyticsEvent.soloAvailableTime : AnalyticsEvent.soloBusyTime
                Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
            
        }
        else{
            // send available time
            // his/her previous state is available.
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                let event = isCurrentStatus ? AnalyticsEvent.soloBusyTime : AnalyticsEvent.soloAvailableTime
                Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        // reset the new time
        if !isCurrentStatus {
            PFUser.current()![USER_STATUS_TIME] = Date()
            PFUser.current()?.saveInBackground()
        }
    }
    
    /**
     This method is used to send the current analytics when the user enter to Limbo mode.
     */
    fileprivate func sendAnalyticsWhenUserLimbo() {
        if User.shared.status == STATUS_AVAILABLE {
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                //let event = User.shared.currentRoom == nil ? AnalyticsEvent.soloAvailableTime : AnalyticsEvent.groupAvailableTime
                //Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        else{
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                //let event = User.shared.currentRoom == nil ? AnalyticsEvent.soloBusyTime : AnalyticsEvent.groupBusyTime
                //Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        
        /*Reset the date.*/
        PFUser.current()?.setObject(NSNull(), forKey: USER_STATUS_TIME)
        PFUser.current()?.saveInBackground()
    }
    
    fileprivate func customizeHeader() {
        viewCircular.layer.cornerRadius = viewCircular.frame.size.width/2.0
    }
    
    @IBAction func closeButt(_ sender: AnyObject) {
    
        let alert = UIAlertController(title: APP_NAME,
                                      message: "Are you sure you want to logout?",
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Logout", style: .default, handler: { (action) -> Void in
            self.showHUD()
            self.sendUserStatusAnalytics(isCurrentStatus: true)
            self.removeNotification()
            self.resetUser()
            // reset the new time
            guard let updateUser = PFUser.current() else {
                self.showLoginController()
                return
            }
            
            updateUser[USER_STATUS_TIME] = NSNull()
            updateUser.setObject(NSNull(), forKey: USER_STATUS_TIME)
            updateUser.saveInBackground { (success, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "")
                }
                
                User.shared.imageFile = UIImage(named: "logo")
                PFUser.logOutInBackground(block: { (error) in
                    if error == nil {
                        // Show the Login screen
                        self.hideHUD()
                        self.showLoginController()
                    }
                })
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        
        alert.addAction(ok); alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
    }
    
    /**This function is used to reset the details.*/
    fileprivate func resetUser(){
        User.shared.awarenessMode = false
        User.shared.audioProcessor?.stop()
        
        //Reset user last triggered.
        UserDefaults.standard.set("", forKey: "lastTriggeredBy")
        UserDefaults.standard.synchronize()
    }
    
    //Settings
    @IBAction func onAccountBtn(_ sender: UIButton) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "Account") as! Account
        view.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        present(view, animated: true, completion: nil)
    
    }
    
    //Invite Friend
    @IBAction func inviteButtonTapped(_ sender: Any) {
        let activityController = UIActivityViewController(activityItems: [kMessageInviteText], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = self.view
        activityController.excludedActivityTypes = [.airDrop]
        present(activityController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK:- Swipe Gesture
extension CodeJam {
    fileprivate func addSwipeGestureToHeader() {
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft(_:)))
        swipeLeftGesture.direction = .left
        viewSwipeHeader.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight(_:)))
        swipeRightGesture.direction = .right
        viewSwipeHeader.addGestureRecognizer(swipeRightGesture)
    }
    // Swipe Left
    @objc fileprivate func didSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        if User.shared.isUserStatusLimbo || currentHeaderIndex == 1 {
            return
        }
        currentHeaderIndex = 1
        //User.shared.status = STATUS_BUSY
        //setStatus()
        //saveUserStatus()
        //sendUserStatusAnalytics()
        
        //Temporarily fix status to always available, and keep action active
        currentHeaderIndex = 0
        User.shared.status = STATUS_AVAILABLE
        setStatus()
        saveUserStatus()
        
        
        UIView.transition(with: viewProfile, duration: TimeInterval(0.5), options: .transitionFlipFromRight, animations: {
        }, completion: nil)
    }
    // Swipe Right
    @objc fileprivate func didSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        if User.shared.isUserStatusLimbo || currentHeaderIndex == 0 {
            return
        }
        currentHeaderIndex = 0
        User.shared.status = STATUS_AVAILABLE
        setStatus()
        saveUserStatus()
        //sendUserStatusAnalytics()
        UIView.transition(with: viewProfile, duration: TimeInterval(0.5), options: .transitionFlipFromLeft, animations: {
        }, completion: nil)
    }
}

extension CodeJam: SRFSurfboardDelegate {
    func surfboard(_ surfboard: SRFSurfboardViewController!, didShowPanelAt index: Int) {
        
    }
    
    func surfboard(_ surfboard: SRFSurfboardViewController!, didTapButtonAt indexPath: IndexPath!) {
        let isTutorialCompleted = UserDefaults.standard.bool(forKey: kTutorialCompletedKey)
        if !isTutorialCompleted {
            UserDefaults.standard.set(true, forKey: kTutorialCompletedKey)
            UserDefaults.standard.synchronize()
        }
        surfboard.dismiss(animated: true, completion: nil)
    }
}
