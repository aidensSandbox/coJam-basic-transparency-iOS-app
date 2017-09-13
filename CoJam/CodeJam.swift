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

// MARK: - CUSTOM ROOMS CELL
class RoomCell: UICollectionViewCell {
    /* Views */
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addNew: UIImageView!
    
}

class User{
    // Can't init is singleton
    private init() { }
    // MARK: Shared Instance
    static let shared = User()
    var status = STATUS_AVAILABLE
    var awarenessMode = false
    var imageFile = UIImage(named: "logo")
    var currentRoom:PFObject?
    var audioProcessor : AudioProcessor? = nil
    var isUserStatusLimbo = false
}


// MARK:- ROOMS CONTROLLER
class CodeJam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UISearchBarDelegate
{
    
    /* Views */
    @IBOutlet weak var roomsCollView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var newRoomButton: UIBarButtonItem!
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
    var roomsArray = [PFObject]()
    
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
        self.awarenessIcon.layer.borderColor = UIColor.black.cgColor
        
        if PFUser.current() == nil {
            showLoginController()
            
        } else {
            let isTutorialCompleted = UserDefaults.standard.bool(forKey: kTutorialCompletedKey)
            if !isTutorialCompleted {
                Timer.scheduledTimer(timeInterval: TimeInterval(0.5), target: self, selector: #selector(checkAndShowTutorial), userInfo: nil, repeats: false)
                return
            }
            
            showUserDetails()
            setStatus()
            queryRooms()
            setCurrentRoom()
            
            // Associate the device with a user for Push Notifications
            let installation = PFInstallation.current()
            installation?["username"] = PFUser.current()!.username
            installation?["userID"] = PFUser.current()!.objectId ?? ""
            installation?.saveInBackground(block: { (succ, error) in
                if error == nil {
                }
            })
            
            User.shared.audioProcessor?.surroundSound = UserDefaults.standard.value(forKey: kSurroundVoice) as? Bool ?? true
            User.shared.audioProcessor?.pauseMusic = UserDefaults.standard.value(forKey: kPlayMusic) as? Bool ?? true
            
            if(User.shared.currentRoom != nil){
                self.joinInRoom()
            }
            
            subscribeToInvitation()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        initilize()
        customizeHeader()
        addSwipeGestureToHeader()
        subscribeTo()
        subscribeToNewGroups()
        
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
    
    deinit {
        subscriptionInvitation = nil
        subscription = nil
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
        let limbo = !(Utility.isMicrophonePermissionEnabled() && Utility.isHeadphoneConnected())
        saveUserLimbo(status: limbo)
    }
    
    
    /**
     Notification listner to handle user limbo status,
     headphone pluged then IS_LIMBO = FALSE and 
     headphone removed then IS_LIMBO = TRUE
     */
    func audioNotificationChanged(_ notification: Notification) {
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
        guard let currentUser = PFUser.current() else {
            return
        }
        User.shared.isUserStatusLimbo = status
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
        searchBar.backgroundImage = UIImage()
        labelStatus.text = ""
        labelStatusMessage.text  = ""
        
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        self.profileImg.layer.masksToBounds = true
        
        viewActivityContainer?.layer.cornerRadius = profileImg.layer.cornerRadius
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        roomsCollView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(tapGestureRecognizer)
        
        viewActivityContainer?.isHidden = true
        activityIndicatorUserAwareness?.stopAnimating()
        
        print("@@@@@@@@@@@@@@@@")
        print("Setup Audio")
        print("@@@@@@@@@@@@@@@@")
        User.shared.audioProcessor = AudioProcessor()
        User.shared.audioProcessor?.pauseMusic = true;
        User.shared.audioProcessor?.surroundSound = true;
        User.shared.audioProcessor?.gain = Float(kDefaultAudioGain)
        //UIApplication.shared.beginReceivingRemoteControlEvents()
        
        /**
         Check Headphone is plugged in or not. and setting is user is limbo.
         */
        let limbo = !(Utility.isMicrophonePermissionEnabled() && Utility.isHeadphoneConnected())
        saveUserLimbo(status: limbo)
        
        if PFUser.current() != nil {
            _ = try? PFUser.current()?.fetch()
            User.shared.status = PFUser.current()![USER_STATUS] as? String ?? STATUS_AVAILABLE
            print("Currentuser:", PFUser.current()!)
            setCurrentRoom()
            
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
    
    fileprivate func setCurrentRoom() {
        if let currentRoom = PFUser.current()![USER_CURRENTROOM] as? PFObject {
            let query = PFQuery(className: ROOMS_CLASS_NAME)
            if let object = try? query.getObjectWithId(currentRoom.objectId!) {
                User.shared.currentRoom = object
            }
        }
    }
    
    
    fileprivate func showLoginController() {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
        present(loginVC, animated: true, completion: nil)
    }
    
    fileprivate func invitationAcceptFor(room: PFObject) {
        if let currentUser = PFUser.current() {
            room.add(currentUser, forKey: ROOM_MEMBERS)
            room.saveInBackground()
        }
    }
    
    /*
    func showInvite(room:PFObject){
        let alert = UIAlertController(title: APP_NAME,
                                      message: "You have been invited to join in CodeJam \(room[ROOMS_NAME] ?? "")",
            preferredStyle: .alert)
        let ok = UIAlertAction(title: "Accept", style: .default, handler: { (action) -> Void in
            //setting the new 
            self.invitationAcceptFor(room: room)
            User.shared.currentRoom = room
            self.updateCurrentRoom()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        alert.addAction(ok); alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    */
    
    var subscriptionInvitation: Subscription<PFObject>?
    func subscribeToInvitation(){
        let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_INVITE_CLASS_NAME)
        query.whereKey(CODEJAM_INVITE_USER_POINTER, equalTo: PFUser.current()!)
        subscriptionInvitation = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            let room = object[CODEJAM_INVITE_ROOM_POINTER] as! PFObject;
            let query = PFQuery(className: ROOMS_CLASS_NAME)
            query.whereKey("objectId", equalTo: room.objectId ?? "")
            query.findObjectsInBackground { (objects, error)-> Void in
                if error == nil {
                    var rObj = PFObject(className: ROOMS_CLASS_NAME)
                    rObj = objects![0]
                    //self.showInvite(room:rObj)
                    self.invitationAcceptFor(room: rObj)
                    do{
                        try rObj.fetchIfNeeded()
                    }
                    catch {
                        print("fetching_room_error", error)
                    }
                    
                    User.shared.currentRoom = rObj
                    self.updateCurrentRoom()
                }}
        }
    }
    
    var subscriptionNewInvitaions: Subscription<PFObject>?
    func subscribeToNewGroups() {
        if let currentUser = PFUser.current() {
            let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_INVITE_CLASS_NAME)
            query.whereKey(CODEJAM_INVITE_USER_POINTER, equalTo: currentUser)
            subscriptionNewInvitaions = liveQueryClient.subscribe(query).handle(Event.entered){ _, object in
                print("Event.entered")
            }
        }
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
            if error == nil {
                //self.pushEvent(event: "refresh")
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
                self.profileImg.layer.borderColor = UIColor.black.cgColor
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
                self.profileImg.layer.borderColor = UIColor.green.cgColor
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
                self.profileImg.layer.borderColor = UIColor.red.cgColor
            }
        }
        
        //only set the USER_STATUS_TIME is null and clears when user logout.
//        if PFUser.current()![USER_STATUS_TIME] is NSNull || PFUser.current()![USER_STATUS_TIME] == nil {
//           PFUser.current()![USER_STATUS_TIME] = Date()
//        }
        setUserStatusTime()
    }
    
    /**
     This method is used to save the USER_STATUS.
     */
    fileprivate func saveUserStatus(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_STATUS] = User.shared.status
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
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
                print("STATUS_AVAILABLE_previousTime: ", previousTime)
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
                print("STATUS_BUSY_previousTime: ", previousTime)
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
                let event = User.shared.currentRoom == nil ? AnalyticsEvent.soloAvailableTime : AnalyticsEvent.groupAvailableTime
                Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        else{
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                let event = User.shared.currentRoom == nil ? AnalyticsEvent.soloBusyTime : AnalyticsEvent.groupBusyTime
                Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        
        /*Reset the date.*/
        PFUser.current()?.setObject(NSNull(), forKey: USER_STATUS_TIME)
        PFUser.current()?.saveInBackground()
    }
    
    
    fileprivate func customizeHeader() {
        viewCircular.layer.cornerRadius = viewCircular.frame.size.width/2.0
    }
    
    // MARK: - QUERY ROOMS
    func queryRooms() {
        showHUD()
        roomsArray.removeAll()
        let searchString = (searchBar.text ?? "").uppercased()
        let query = PFQuery(className: ROOMS_CLASS_NAME)
        query.whereKey(ROOMS_NAME, contains: searchString)
        query.order(byDescending: "createdAt")
        query.includeKey(ROOM_MEMBERS)
        query.whereKey("roomMembersArray.objectId", equalTo: PFUser.current()!.objectId ?? "")
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.roomsArray = objects ?? []
                self.roomsCollView.reloadData()
                self.hideHUD()
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
            }
        }
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
    }
    
    // MARK: - COLLECTION VIEW DELEGATES
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomsArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newRoomCell", for: indexPath)
            let imageView = cell.viewWithTag(100) as? UIImageView
            imageView?.layer.cornerRadius = (imageView?.frame.size.width)!/2
            imageView?.layer.borderWidth = 2
            imageView?.layer.borderColor = UIColor.black.cgColor
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomCell", for: indexPath) as! RoomCollectionViewCell
        if roomsArray.count > 0 {
            let roomClass = roomsArray[indexPath.row - 1]
            cell.labelName?.text = "\(roomClass[ROOMS_NAME] ?? "")"
            cell.labelSubscript?.text = ""
        }
        
        return cell
    }
    
    // MARK: - TAP ON A CELL -> ENTER A JAM ROOM
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let jam = self.storyboard?.instantiateViewController(withIdentifier: "NewRoom") as! NewRoom
            jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            present(jam, animated: true, completion: nil)
        }
        else if roomsArray.count > 0 {
            
            var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
            roomsClass = roomsArray[indexPath.row - 1]
            User.shared.currentRoom = roomsClass
            updateCurrentRoom()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columnWidth = (collectionView.frame.size.width / CGFloat(kGroupColumnCount)) - CGFloat(kSpaceBetweenCell)
        return CGSize(width: columnWidth, height: columnWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(kSpaceBetweenCellRow)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(kSpaceBetweenCell)
    }
    
    
    //Settings
    @IBAction func onAccountBtn(_ sender: UIButton) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "Account") as! Account
        view.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        present(view, animated: true, completion: nil)
    
    }
    
    // MARK: - SEARCH BAR DELEGATES
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        queryRooms()
        searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        searchBar.text = ""
        queryRooms()
    }
    
    func updateCurrentRoom(){
        guard let updatedUser = PFUser.current() else {
            showLoginController()
            return
        }
        
        showHUD();

        updatedUser[USER_CURRENTROOM] = User.shared.currentRoom
        if !User.shared.isUserStatusLimbo {
            updatedUser[USER_STATUS_TIME] = Date()
        }
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                //Send room enter analytics SOLO STATE.
                self.sendUserStatusAnalytics(isCurrentStatus: true)
                self.joinInRoom()
            } else {
                self.hideHUD()
                print(error?.localizedDescription ?? "")
            }
        }
    }
   
    func removeCurrentRoom(){
        guard let updatedUser = PFUser.current() else {
            showLoginController()
            return
        }
        updatedUser[USER_CURRENTROOM] = NSNull()
        updatedUser.setObject(NSNull(),forKey: USER_CURRENTROOM)
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
            } else {
                print(error?.localizedDescription ?? "")
            }
        }
    }

    func joinInRoom(){
        let jam = self.storyboard?.instantiateViewController(withIdentifier: "Jam") as! Jam
        jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        User.shared.currentRoom?.fetchInBackground(block: { (object, error) in
            
            self.hideHUD()
            jam.codejamObj = User.shared.currentRoom!
            self.present(jam, animated: true, completion: nil)
        })
        
    }
    
    var subscription: Subscription<PFObject>?
    func subscribeTo(){
        if let currentUser =  PFUser.current(){
            let query: PFQuery<PFObject> = PFQuery(className:USERCODEJAM_CLASS_NAME)
            query.whereKey(USERCODEJAM_USER_POINTER, equalTo: currentUser)
            query.whereKey(USERCODEJAM_USER_STATUS, equalTo: "invited")
            subscription = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
                User.shared.currentRoom = object[CHAT_ROOM_POINTER] as? PFObject
                self.updateCurrentRoom()
            }
        }
        
    }
    
    // MARK: - REFRESH ROOMS BUTTON
    /*@IBAction func refreshButt(_ sender: AnyObject) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        
        // Call query
        if PFUser.current() != nil { queryRooms() }
    }*/
    
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
    
    @objc fileprivate func didSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        if User.shared.isUserStatusLimbo || currentHeaderIndex == 1 {
            return
        }
        currentHeaderIndex = 1
        User.shared.status = STATUS_BUSY
        setStatus()
        saveUserStatus()
        sendUserStatusAnalytics()
        UIView.transition(with: viewProfile, duration: TimeInterval(0.5), options: .transitionFlipFromRight, animations: {
        }, completion: nil)
    }
    
    @objc fileprivate func didSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        if User.shared.isUserStatusLimbo || currentHeaderIndex == 0 {
            return
        }
        currentHeaderIndex = 0
        User.shared.status = STATUS_AVAILABLE
        setStatus()
        saveUserStatus()
        sendUserStatusAnalytics()
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
