//
//  CodeJam.swift
//  CodeJam
//
//  Created by Raminelli, Alvaro on 6/11/17.
//  Copyright © 2017 FV iMAGINATION. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery
import PopupDialog


class Jam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout, AccountDelegate, UsersDelegate
{
    // Profile
    @IBOutlet weak var exitJam: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var awarenessIcon: UIImageView!
    @IBOutlet weak var activeButton: UIImageView!
    @IBOutlet weak var deactiveButton: UIImageView!
    
    @IBOutlet weak var viewStatusInfoMessage: UIView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelStatusMessage: UILabel!
    @IBOutlet weak var viewSwipeHeader: UIView!
    @IBOutlet weak var viewCircular: UIView!
    @IBOutlet var viewProfile: UIView!
    @IBOutlet var buttonCoJamAll: UIButton!
    @IBOutlet var labelTitle: UILabel!
    
    @IBOutlet var userAwarenessUpdateActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var viewContainerIndicator: UIView!
    @IBOutlet weak var activityIndicatorCoJamAll: UIActivityIndicatorView!
    
    
    var codejamObj = PFObject(className: ROOMS_CLASS_NAME)
    var codejamSessionObj = PFObject(className: USERCODEJAM_CLASS_NAME)
    var usersArray = [PFObject]()
    var refreshTimer: Timer?
    var roomAwarenessMode = false
    fileprivate var currentHeaderIndex = 0
    var arrayOnlineUsers: [PFUser] = []
    
    fileprivate var locationManager: CLLocationManager?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addNotification()
        collectionView.contentInset = UIEdgeInsetsMake(10, 0, 65, 0)
        customizeHeader()
        addSwipeGestureToHeader()
        
        buttonCoJamAll.layer.cornerRadius = buttonCoJamAll.frame.size.height/2
        buttonCoJamAll.backgroundColor = UIColor.white

        buttonCoJamAll.layer.borderWidth = 1.0
        buttonCoJamAll.layer.borderColor = UIColor.black.cgColor
        
        self.setupUI();
        
        
     
        
        setupLocationManager()
    }
    
    func showLocationInfo()
    {
        // Prepare the popup assets
        let title = "LOCATIONS KEEP THE APP ALIVE"
        let message = "Users can only request to talk to you while your phone is locked or sleeping, if CoJam can use your location in the background. We don't store your location or do anything with your data, we simply keep the app alive with it. We are working on a better solution, and will remove the need for location soon."
        let image = UIImage(named: "map")
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: image)
        
       
        
        let buttonTwo = DefaultButton(title: "TURN ON LOCATION SERVICES") {
            
            self.locationManager?.requestAlwaysAuthorization()
            self.locationManager?.startUpdatingLocation()
        }
        
        buttonTwo.buttonColor = UIColor.green
        buttonTwo.titleColor = UIColor.black

        
        let buttonThree = DefaultButton(title: "DON'T TURN ON LOCATION SERVICES") {
        }
        buttonThree.buttonColor = UIColor(colorLiteralRed: 175/255, green: 53/255, blue: 53/255, alpha: 1)
        buttonThree.titleColor = UIColor.white

        
        // Add buttons to dialog
        // Alternatively, you can use popup.addButton(buttonOne)
        // to add a single button
        popup.addButtons([buttonTwo, buttonThree])
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func setupUI()
    {
        userAwarenessUpdateActivityIndicator.stopAnimating()
        viewContainerIndicator.isHidden = true
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2;
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        self.profileImg.layer.borderColor = UIColor.clear.cgColor
        
        viewContainerIndicator.layer.cornerRadius = self.profileImg.layer.cornerRadius
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(awarenessTapped(tapGestureRecognizer:)))
        self.profileImg.isUserInteractionEnabled = true
        self.profileImg.addGestureRecognizer(tapGestureRecognizer)
        
        
        let currentUser = PFUser.current()!
        _ = try? currentUser.fetchIfNeeded()
        // Get avatar
        let imageFile = currentUser[USER_AVATAR] as? PFFile
        Utility.setImage(view: profileImg, imageFile: imageFile)
        
        self.awarenessIcon.isHidden = true;
        self.awarenessIcon.layer.cornerRadius = self.awarenessIcon.frame.size.width / 2;
        self.awarenessIcon.clipsToBounds = true
        self.awarenessIcon.layer.borderWidth = kAwarenessIconBorderWidth
        self.awarenessIcon.layer.borderColor = UIColor.black.cgColor
        
        labelTitle.text = codejamObj[ROOMS_NAME] as? String ?? ""
        
        
        intializeUserStatus()
        getRoomDetails()
        loadUsers()
        subscribeToAwareness()
        subscribeTo()
        subscribeToInvitation()
        
        initializeRefreshTimer()
        self.pushEvent(event: "refresh")
        
        print("/////////////////////\n", PFUser.current()!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        setUserStatus()
//        getRoomDetails()
//        loadUsers()
//        subscribeToAwareness()
//        subscribeTo()
//        subscribeToInvitation()
        
        //subscribeToUserAwareness()
    }
    
    
    @IBAction func didTappedHelpButton(_ sender: Any) {
        Utility.showTutorialScreen(on: self)
    }
    
    /**
     Overriding var to change the status-bar color.
     */
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        subscription = nil
        subscriptionAwareness = nil
        subscriptionInvitation = nil
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestLocationUpdateAuthorization()
        print("##########################################")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "users" {
            if let toViewController = segue.destination as? Users {
                toViewController.roomObj = codejamObj
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    
    //MARK:- NOTIFICATION
    
    fileprivate func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnteredBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnteredForeground(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        /**Notification to listen headphone plugged in or not*/
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserStatus(_:)), name: kNotificationHeadphoneChanged, object: nil)
    }
    
    fileprivate func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: kNotificationHeadphoneChanged, object: nil)
    }
    
    // this get fires when user pluged or unplugged headphone.
    @objc fileprivate func updateUserStatus(_ notification: Notification) {
        validateUserTriggerStatus()
        //setRoomAwarenessDispaly()
        updateUser()
    }
    
    
    func applicationEnteredBackground(_ notification: Notification) {
        resetRefreshTimer()
    }
    
    func applicationEnteredForeground(_ notification: Notification) {
        initializeRefreshTimer()
        let limbo = !(Utility.isMicrophonePermissionEnabled() && Utility.isHeadphoneConnected())
        self.saveUserLimbo(status: limbo)
    }
    
    //MARK:- LOCATION MANAGER
    /**
     This function is used to initialize the location manager.
     */
    fileprivate func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
       // locationManager?.distanceFilter = 500
    }
    
    /**
     This function is used to handle and check if user location permissions is enabled.
     */
    fileprivate func requestLocationUpdateAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                
                self.showLocationInfo()
                
                break
                
            case .restricted, .denied:
                let completionHandler: (_ action: UIAlertAction) -> Void = { (action: UIAlertAction) -> Void in
                    if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.openURL(url as URL)
                    }
                }
                
                self.showConfirmAlert(message: "Please open this app's settings and set location access to 'Always'.", okTitle: "Settings", completionHandler: completionHandler)
                break
            default:
                locationManager?.startUpdatingLocation()
                break
            }
        }
        else {
            let completionHandler: (_ action: UIAlertAction) -> Void = { (action: UIAlertAction) -> Void in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url as URL)
                }
            }
            self.showConfirmAlert(message: "Please open this app's settings and enable location access.", okTitle: "Settings", completionHandler: completionHandler)
        }
        
    }
    
    /**
     Reset the location manager
     */
    fileprivate func resetLocationManager() {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    
    //MARK:- CONFIG HEADER
    
    fileprivate func customizeHeader() {
        labelStatus.text = ""
        labelStatusMessage.text  = ""
        viewCircular.layer.cornerRadius = viewCircular.frame.size.width/2.0
    }
    
    
    func getRoomDetails(){
        let query = PFQuery(className: ROOMS_CLASS_NAME)
        query.whereKey("objectId", equalTo: codejamObj.objectId!)
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                var rObj = PFObject(className: ROOMS_CLASS_NAME)
                rObj = objects![0]
                let result = Bool(rObj[AWARENESS] as? NSNumber ?? 0)
                //print("### getRoomDetails ###")
                print(result)
                /* Is room awareness on and headphone connected */
                self.roomAwarenessMode = result
                self.validateUserTriggerStatus();
                self.updateCoJamAll(status: result)
                self.updateCurrentUser(force: true)
            }}
    }
    
    /**
     This function is used to set the background color of cojam all button.
     */
    func updateCoJamAll(status: Bool) {
        DispatchQueue.main.async {
            self.activityIndicatorCoJamAll.stopAnimating()
            if status {
                self.buttonCoJamAll.backgroundColor = UIColor.green
            }
            else{
                self.buttonCoJamAll.backgroundColor = UIColor.white
            }
        }
        
    }
    
    fileprivate func updateUserWithoutAnimation() {
        if User.shared.isUserStatusLimbo {
            self.profileImg.layer.borderColor = UIColor.black.cgColor
            self.labelStatus.text = limboTitle.capitalized
            self.labelStatusMessage.text = limboInfoMessage
        }
        else if User.shared.status == STATUS_AVAILABLE {
            self.profileImg.layer.borderColor = UIColor.green.cgColor
            self.labelStatus.text = "Sociable"
            self.labelStatusMessage.text = socialInfoMessage
            self.labelStatusMessage.updateConstraintsIfNeeded()
        } else{
            self.profileImg.layer.borderColor = UIColor.red.cgColor
            self.labelStatus.text = "Busy"
            self.labelStatusMessage.text = busyInfoMessage
            self.labelStatusMessage.updateConstraintsIfNeeded()
        }
        
        setRoomAwarenessDispaly()
    }
    
    /**Hightlight the user awareness icon based on limbo mode and awareness*/
    fileprivate func setRoomAwarenessDispaly() {
        DispatchQueue.main.async {
            if User.shared.awarenessMode && !User.shared.isUserStatusLimbo {
                self.awarenessIcon.isHidden = false;
            } else{
                self.awarenessIcon.isHidden = true;
            }
        }
        
    }
    
    ///With animation
    func updateUser(animate: Bool = true){
        viewStatusInfoMessage.alpha = animate ? 0.5 : 1
        if User.shared.isUserStatusLimbo {
            self.profileImg.layer.borderColor = UIColor.black.cgColor
            self.labelStatus.text = limboTitle.capitalized
            self.labelStatusMessage.text = limboInfoMessage
        }
        else if User.shared.status == STATUS_AVAILABLE {
            currentHeaderIndex = 0
            DispatchQueue.main.async {
                self.profileImg.layer.borderColor = UIColor.green.cgColor
                self.labelStatus.text = availableTitle.capitalized
                self.labelStatusMessage.text = socialInfoMessage
                self.labelStatusMessage.updateConstraintsIfNeeded()
                
                if animate {
                    UIView.animate(withDuration: TimeInterval(1.0), animations: {
                        self.viewStatusInfoMessage.alpha = 1
                    })
                }
            }
            
            
        } else{
            currentHeaderIndex = 1
            DispatchQueue.main.async {
                self.profileImg.layer.borderColor = UIColor.red.cgColor
                self.labelStatus.text = busyTitle.capitalized
                self.labelStatusMessage.text = busyInfoMessage
                self.labelStatusMessage.updateConstraintsIfNeeded()
                
                if animate {
                    UIView.animate(withDuration: TimeInterval(1.0), animations: {
                        self.viewStatusInfoMessage.alpha = 1
                    })
                }
            }
        }
        setRoomAwarenessDispaly()
        
    }
    
    func pushEvent(event:String){
        let eventClass = PFObject(className: CODEJAM_EVENT_CLASS_NAME)
        let currentUser = PFUser.current()
        // Save PFUser as a Pointer
        eventClass[CODEJAM_EVENT_USER_POINTER] = currentUser
        // Save Name Event
        eventClass[CODEJAM_EVENT_NAME] = event
        eventClass[CHAT_ROOM_POINTER] = codejamObj
        // Saving block
        eventClass.saveInBackground { (success, error) -> Void in
            if error == nil {
        }}
    }
    
    
    func intializeUserStatus()
    {
        self.updateUser()
        
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
    
    /**This function is used to request to enable microphone permission */
    fileprivate func requestForMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granded) in
                if granded {
                    User.shared.isUserStatusLimbo = !Utility.isHeadphoneConnected()
                    self.saveUserLimbo(status: !Utility.isHeadphoneConnected())
                }
            })
            
        case AVAudioSessionRecordPermission.denied:
            self.showSettings()
            break
        default:
            break
        }
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
        updateUser(animate: false)
        currentUser[IS_LIMBO] = status
        currentUser.saveInBackground(block: { (success, error) in
            if error != nil {
                print(error)
            }
        })
    }
    
    /**
     Set the current user awareness and save the change and reload all. Send a refresh event.
     */
    func setUserStatus(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_STATUS] = User.shared.status
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.updateUser()
                self.pushEvent(event: "refresh")
            }
        }
    }
    
    func awarenessTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
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
        userAwarenessUpdateActivityIndicator.startAnimating()
        viewContainerIndicator.isHidden = false
        
        /**
         This is used to reset the forced awareness.
         FORCED_AWARENESS_OFF set to true when group is in CoJam mode and need to disable the awareness.
         */
        PFUser.current()?.fetchInBackground(block: { (object, error) in
            
            let forcedAwareness = PFUser.current()![FORCED_AWARENESS_OFF] as? Bool ?? false
            let roomAwareness = self.codejamObj[AWARENESS] as? Bool ?? false
            if !forcedAwareness && roomAwareness {
                PFUser.current()?[FORCED_AWARENESS_OFF] = true
                PFUser.current()?.saveInBackground()
            }
            //Reset the triggeredBy user
            PFUser.current()?["triggeredBy"] = NSNull()
            self.updateCurrentUserAwareness()
            
            var enabledMembers: [PFUser] = self.codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] as? [PFUser] ?? []
            if enabledMembers.contains(where: { (members) -> Bool in
                return members.objectId! == PFUser.current()!.objectId!
            }) {
                if let itemIndex = enabledMembers.index(where: { (user: PFUser) -> Bool in
                    return user.objectId! == PFUser.current()!.objectId!
                }) {
                    enabledMembers.remove(at: itemIndex)
                    self.codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] = enabledMembers
                    self.codejamObj.saveInBackground()
                }
            }
            self.profileImg.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.viewContainerIndicator.transform = self.profileImg.transform
            UIView.animate(withDuration: TimeInterval(0.5), animations: {
                self.profileImg.transform = CGAffineTransform.identity
                self.viewContainerIndicator.transform = self.profileImg.transform
            })
        })
        
    }
    
    fileprivate func updateCurrentUserAwareness() {
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false
            User.shared.audioProcessor?.stop()
        } else{
            User.shared.awarenessMode = true;
            User.shared.audioProcessor?.start()
        }
        
        self.roomAwarenessMode = User.shared.awarenessMode
        
        let updatedUser = PFUser.current()!
        updatedUser[AWARENESS] = User.shared.awarenessMode
        updatedUser.saveInBackground { (success, error) -> Void in
            self.userAwarenessUpdateActivityIndicator.stopAnimating()
            self.viewContainerIndicator.isHidden = true
            if error == nil {
                self.updateUser()
                self.pushEvent(event: "refresh")
            }
        }
        
        Utility.sendSelfInterruptionAnalytics()
    }
    
    
    @IBAction func didTappedRoomAwareness(_ sender: Any) {
        //setRoomAwareness()
        
        let result = Bool(self.codejamObj[AWARENESS] as? NSNumber ?? 0)
        //self.updateCoJamAll(status: !result)
        updateUsersForced(awareness: !result)
    }
    
    /**
     This function updates the current room awareness. CoJam All
     */
    /*func setRoomAwareness(){
        let result = Bool(self.codejamObj[AWARENESS] as? NSNumber ?? 0)
        codejamObj[AWARENESS] = !result
        codejamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                print("setRoomAwareness Saved with success")
                self.pushEvent(event: "refresh")
            } else {
                print("\(error!.localizedDescription)")
            }
        }
    }*/
    
    /**
     This function is used to set users forced awareness in a room.
     */
    fileprivate func updateUsersForced(awareness: Bool) {
        let params: [String: Any] = [
            "roomId": codejamObj.objectId ?? "",
            "awareness": awareness
        ]
        activityIndicatorCoJamAll.isHidden = false
        activityIndicatorCoJamAll.startAnimating()
        buttonCoJamAll.isUserInteractionEnabled = false
        PFCloud.callFunction(inBackground: "cojamAll", withParameters: params) { (response, error) in
            self.buttonCoJamAll.isUserInteractionEnabled = true
            DispatchQueue.main.async {
                self.activityIndicatorCoJamAll.stopAnimating()
            }
            if error == nil {
                //print(response)
                //Cojam All Analytics.
                let event = awareness ? AnalyticsEvent.cojamAllOn : AnalyticsEvent.cojamAllOff
                let params = [
                    AnalyticsParameter.username: PFUser.current()!.username ?? "",
                    AnalyticsParameter.email: PFUser.current()!.email ?? ""
                ]
                Utility.sendEvent(name: event, param: params)
            }
            else {
                print(error)
            }
        }
    }
    
    
    /**
     This function is called when awarness changed.
     */
    func validateUserTriggerStatus()
    {

        let result = Bool(self.codejamObj[AWARENESS] as? NSNumber ?? 0)
        var memberAwareness = false
        /**Members whose awareness enabled in the current room.*/
        let enabledMembers: [PFUser] = self.codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] as? [PFUser] ?? []
        if enabledMembers.contains(where: { (members) -> Bool in
            return members.objectId! == PFUser.current()!.objectId!
        }) {
            memberAwareness = true
        }
        else {
            memberAwareness = false
        }
        _ = try? PFUser.current()?.fetchIfNeeded()
        let userAwareness = Bool(PFUser.current()![AWARENESS] as? NSNumber ?? 0)
        
        self.roomAwarenessMode = (result || userAwareness || memberAwareness) && Utility.isHeadphoneConnected()
        _ = try? PFUser.current()?.fetch()
        let forcedAwarenessOff = PFUser.current()![FORCED_AWARENESS_OFF] as? Bool ?? false
        if (result && forcedAwarenessOff) && !(userAwareness || memberAwareness) {
            self.roomAwarenessMode = false
        }
        
        self.updateCoJamAll(status: result)
        self.updateCurrentUser(force: false)
        self.setRoomAwarenessDispaly()
    }
    
    func updateCurrentUser(force:Bool)
    {
        if User.shared.status == STATUS_AVAILABLE || force{
            if self.roomAwarenessMode == User.shared.awarenessMode {
                return
            }
            User.shared.awarenessMode = self.roomAwarenessMode
            
            if User.shared.awarenessMode
            {
                User.shared.audioProcessor?.start()
            }
            else
            {
                User.shared.audioProcessor?.stop()
            }
        }
    }
    
    func setUserAwareness(force:Bool){
        
        if User.shared.status == STATUS_AVAILABLE || force{
            if self.roomAwarenessMode == User.shared.awarenessMode {
                return
            }
            User.shared.awarenessMode = self.roomAwarenessMode
            
            if User.shared.awarenessMode
            {
                User.shared.audioProcessor?.start()
            }
            else
            {
                User.shared.audioProcessor?.stop()
            }
            
            let updatedUser = PFUser.current()!
            updatedUser[AWARENESS] = User.shared.awarenessMode
            updatedUser.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.updateUser(animate: false)
                    self.pushEvent(event: "refresh")
                }
            }
        }
    
    }
    
    func showInvite(room:PFObject){
    
        let alert = UIAlertController(title: APP_NAME,
                                      message: "You have been invited to join in CoJam \(room[ROOMS_NAME])",
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Accept", style: .default, handler: { (action) -> Void in
                        User.shared.currentRoom = room
            let updatedUser = PFUser.current()!
            updatedUser[USER_CURRENTROOM] = User.shared.currentRoom
            updatedUser.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        alert.addAction(ok); alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

    /**
     Update the user details after changing from settings.
     */
    func didChangeSettings()
    {
        guard let currentUser = PFUser.current() else {
            return
        }
        
        // Get avatar
        let imageFile = currentUser[USER_AVATAR] as? PFFile
        /*imageFile?.getDataInBackground { (imageData, error) -> Void in
            if error == nil {
                if let imageData = imageData {
                    
                    self.profileImg.image = UIImage(data:imageData)
                }}}*/
        Utility.setImage(view: profileImg, imageFile: imageFile)
        
        
        self.pushEvent(event: "refresh")

    }
    
    //Delegate method of users
    func didAddedNewMember(_ user: PFUser) {
        self.pushEvent(event: "refresh")
        
        let inviteEvent = PFObject(className: USERCODEJAM_CLASS_NAME)
        inviteEvent[USERCODEJAM_USER_POINTER] = user
        inviteEvent[USERCODEJAM_USER_STATUS] = "invited"
        inviteEvent[CHAT_ROOM_POINTER] = codejamObj
        inviteEvent.saveInBackground { (success, error) in
            if error == nil {
                
            }
        }
    }
    
    @IBAction func didTappedSettingsButton(_ sender: Any) {
        let settingsController = self.storyboard?.instantiateViewController(withIdentifier: "Account") as! Account
        settingsController.delegate = self
        settingsController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        present(settingsController, animated: true, completion: nil)
    }
    
    
    @IBAction func closeButt(_ sender: AnyObject) {
        showHUD()
        resetRefreshTimer()
        resetLocationManager()
        removeNotification()
        User.shared.currentRoom = nil
        let updatedUser = PFUser.current()!
        updatedUser[USER_CURRENTROOM] = NSNull()
        updatedUser.setObject(NSNull(),forKey: USER_CURRENTROOM)
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.pushEvent(event: "refresh")
                self.hideHUD()
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        //Analytics: Group Available or Busy time.
        sendUserStatusAnalytics(isCurrentState: true)
    }

    //let CODEJAM_INVITE_CLASS_NAME = "CodeJamInvite"
    //let CODEJAM_INVITE_USER_POINTER = "userPointer"
    //let CODEJAM_INVITE_ROOM_POINTER = "roomPointer"
    
    var subscriptionInvitation: Subscription<PFObject>?
    func subscribeToInvitation(){
        print("@@@ subscribeTo JAM Invitation@@@")
        let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_INVITE_CLASS_NAME)
        query.whereKey(CODEJAM_INVITE_USER_POINTER, equalTo: PFUser.current()!)
        subscriptionInvitation = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            let room = object[CODEJAM_INVITE_ROOM_POINTER] as! PFObject;
            let query = PFQuery(className: ROOMS_CLASS_NAME)
            query.whereKey("objectId", equalTo:room.objectId ?? "")
            query.findObjectsInBackground { (objects, error)-> Void in
                if error == nil {
                    guard let arrayObjects = objects else {
                        return
                    }
                    var rObj = PFObject(className: ROOMS_CLASS_NAME)
                    rObj = arrayObjects[0]
                    self.showInvite(room:rObj)
                }}
        }
    }
    
    
    var subscription: Subscription<PFObject>?
    func subscribeTo(){
        print("@@@ subscribeTo JAM @@@")
        let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_EVENT_CLASS_NAME)
        query.whereKey(CHAT_ROOM_POINTER, equalTo: codejamObj)
        query.whereKey(CODEJAM_EVENT_USER_POINTER, notEqualTo: PFUser.current()!)
        subscription = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            print("@@@ Created Event JAM @@@")
            var rObj = PFObject(className: CODEJAM_EVENT_CLASS_NAME)
            rObj = object
            //if (rObj[CODEJAM_EVENT_USER_POINTER] as! PFUser).objectId != PFUser.current()!.objectId{
                self.loadUsers();
            //}
        }
    }
    var subscriptionAwareness: Subscription<PFObject>?
    func subscribeToAwareness(){
        print("@@@ subscribeTo JAM Awareness @@@")
        let query: PFQuery<PFObject> = PFQuery(className:ROOMS_CLASS_NAME)
        query.whereKey("objectId", equalTo: codejamObj.objectId ?? "")
        subscriptionAwareness = liveQueryClient.subscribe(query).handle(Event.updated) { _, object in
            self.codejamObj = object
            self.validateUserTriggerStatus()
        }
    }
    
    
    func addFriend(){
        let usersNavigationController = self.storyboard!.instantiateViewController(withIdentifier: "UsersNav") as! UINavigationController
        let usersController = usersNavigationController.viewControllers.first as! Users
        usersController.delegate = self
        present(usersNavigationController, animated: true, completion: nil)
    }
    
    
    // MARK: - LOAD CHATS OF THIS ROOM
    /**
     This function is used to get all the users in current room.
     */
    func loadUsers() {
        
        //usersArray.removeAll()
        // check if user is logged in
        if PFUser.current() == nil {
            return
        }
        print("loadUsers")
        
        let query : PFQuery = PFUser.query()!
        query.whereKey(USER_CURRENTROOM, equalTo: codejamObj)
        query.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        //query.whereKey("objectId", containedIn: fetchingmembers)
        
        query.order(byAscending: "createdAt")
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects ?? []
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
            }}
    }
    
    //MARK: ONLINE USERS
    /**
     This function is used to load all online users.
     This function is called in every REFRESH_TIME sec.
     */
    @objc fileprivate func getOnlineUsers() {
        if PFUser.current() == nil {
            resetRefreshTimer()
            return
        }
        
        let param: [String: Any] = ["roomId": codejamObj.objectId ?? ""]
        PFCloud.callFunction(inBackground: "getOnlineUsers", withParameters: param) { (response, error) in
            if error == nil && PFUser.current() != nil {
                //print("online users: ", response ?? [])
                self.arrayOnlineUsers = response as? [PFUser] ?? []
                
                //Check if user is present and replace the user with corresponding online user.
                if self.arrayOnlineUsers.count > 0 && self.usersArray.count > 0 {
                    for online in self.arrayOnlineUsers {
                        let onlineUsers = self.usersArray.filter(){ $0.objectId! == online.objectId! }
                        if onlineUsers.count > 0 {
                            let itemIndex = self.usersArray.index(of: onlineUsers.first!)!
                            self.usersArray[itemIndex] = online
                        }
                    }
                }
                self.collectionView.reloadData()
            }
            else {
                print(error)
            }
        }
    }
    
    /**
     This function is used to initialize the refresh timer for checking logged in users.
     */
    func initializeRefreshTimer() {
        if refreshTimer == nil {
            getOnlineUsers()
        }
        //REFRESH_TIME
        refreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(getOnlineUsers), userInfo: nil, repeats: true)
    }
    
    /**
     This function is used to reset the refresh timer. and invalidate the timer.
     Refresh timer helps to get the users online, Which refresh priodically.
     */
    func resetRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    
    /**
     This function is used to set and enable the current user awareness if current room awareness is not triggering.
     And if current user is not in limbo mode.
     */
    func checkAndTriggerCurrentUser(isTriggering: Bool)
    {
        if self.roomAwarenessMode != isTriggering && !User.shared.isUserStatusLimbo {
            self.roomAwarenessMode = isTriggering
            setUserAwareness(force: true)
        }
    }
    
    /**
     This function is used to check whether disable/enable current user awareness after triggering off others.
     Checking if current user is enabled by others or triggered any one else.
     */
    fileprivate func validateAndReleaseTriggerCurrentUserAwareness() {
        _ = try? codejamObj.fetch()
        let enabledMembers: [PFUser] = codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] as? [PFUser] ?? []
        if !enabledMembers.contains(where: { (members) -> Bool in
            return members.objectId! == PFUser.current()!.objectId!
        }) {
            print("Can off, Not Triggered by any")
            let query = PFUser.query()
            query?.includeKey("triggeredBy")
            query?.whereKey(USER_CURRENTROOM, equalTo: codejamObj)
            query?.whereKey("triggeredBy", equalTo: PFUser.current()!)
            query?.findObjectsInBackground(block: { (arrayUsers, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "")
                    return
                }
                
                print("Tiggered Objects: ", arrayUsers ?? [])
                if (arrayUsers?.count ?? 0) == 0 {
                    PFUser.current()?[AWARENESS] = false
                    _ = try? PFUser.current()?.save()
                    
                    self.roomAwarenessMode = false
                    self.updateCurrentUser(force: true)
                    self.setRoomAwarenessDispaly()
                }
            })
        }
        else {
            print("Cannot off Triggered by other: ", enabledMembers)
        }
    }
    
    /**
     This function is used to get the trigerring status based on the corresponsing user
     - Parameter user: PFUser object
     - Returns : Bool
     */
    func getTriggerStatus(user: PFUser) -> Bool
    {
        var result = Bool(self.codejamObj[AWARENESS] as! NSNumber)
        var memberAwareness = false
        let enabledMembers: [PFUser] = self.codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] as? [PFUser] ?? []
        if enabledMembers.contains(where: { (members) -> Bool in
            return members.objectId! == user.objectId!
        }) {
            memberAwareness = true
        }
        else {
            memberAwareness = false
        }
        let userAwareness = Bool(user[AWARENESS] as? NSNumber ?? 0)
        
        result = result && isUserEnabledInCurrentRoom(user: user)
        let status = user[USER_STATUS] as? String ?? STATUS_AVAILABLE
        let isLimbo = user[IS_LIMBO] as? Bool ?? false
        let forcedAwareness = user[FORCED_AWARENESS_OFF] as? Bool ?? false
        
        print("user: \(user.username!), result\(result), userAwareness:\(userAwareness), memberAwareness: \(memberAwareness) isLimbo: \(isLimbo) forcedAwareness: \(forcedAwareness)")
        
        return ((result && (status == STATUS_AVAILABLE) && !forcedAwareness) || userAwareness || memberAwareness) && !isLimbo
    }
    
    /**
     Checking the current user is online.
     The user should be in online list and current room.
     */
    fileprivate func isUserEnabledInCurrentRoom(user: PFUser) -> Bool{
        if user[USER_CURRENTROOM] == nil || user[USER_CURRENTROOM] is NSNull {
            return false
        }
        
        let isOnline = isUserOnline(user: user)
        let isCurrentRoom = ((user[USER_CURRENTROOM] as? PFObject)?.objectId! == codejamObj.objectId!)
        let isLimbo = user[IS_LIMBO] as? Bool ?? false
        
        print("user:\(user.username ?? "") -> isOnline:\(isOnline) isCurrentRoom:\(isCurrentRoom) isLimbo:\(isLimbo)")
        
        return isOnline && isCurrentRoom && !isLimbo
        
        //return ((user[USER_CURRENTROOM] as? PFObject)?.objectId! == codejamObj.objectId!)
    }
    
    fileprivate func isUserOnline(user: PFUser) -> Bool {
        let users = arrayOnlineUsers.filter { (onlineUser) -> Bool in
            return onlineUser.objectId! == user.objectId!
        }
        if users.count > 0 {
            return true
        }
        return false
    }
    
    /**
     This function is used to set the user triggredBy status.
     - Parameters:
        - user: The user wich is triggering, PFUser
        - status: Is adding or removing the triggering user from the awareness enabled array., Bool
     */
    fileprivate func updateTriggered(user: PFUser, status: Bool) {
        let params: [String: Any] = [
            "targetObjectId": user.objectId ?? "",
            "setting": status
        ]
        print("updateTriggered-Params:\(user.username ?? "") ", params)
        PFCloud.callFunction(inBackground: "setTriggeredUser", withParameters: params) { (response, error) in
            if error == nil {
                print(response)
            }
            else{
                print(error)
            }
        }
        
    }
    
    
    // MARK: - COLLECTION VIEW DELEGATES
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserTableViewCell", for: indexPath) as! CustomRoomUserCell
        if indexPath.row == 0 {
            cell.userImage.layer.borderColor = UIColor.black.cgColor
            cell.userImage.contentMode = .center
            cell.userImage.image = UIImage(named: "plusIcon")
            cell.labelUsername?.text = "Add Member"
            cell.labelUsername?.font = UIFont.boldSystemFont(ofSize: 15)
            return cell
        }
        else if usersArray.count > 0 && indexPath.row != 0 {
            let user = usersArray[(indexPath as NSIndexPath).row - 1] as! PFUser
            user.fetchInBackground()
            let imageFile = user[USER_AVATAR] as? PFFile
            cell.setProfile(image: imageFile)
            cell.labelUsername?.text = user.username
            
            if !isUserEnabledInCurrentRoom(user: user) {
                cell.userImage.layer.borderColor = UIColor.black.cgColor
            }
            else if (user[USER_STATUS] as? String ?? STATUS_AVAILABLE) == STATUS_AVAILABLE {
                cell.userImage.layer.borderColor = UIColor.green.cgColor
            } else {
                cell.userImage.layer.borderColor = UIColor.red.cgColor
            }
            
            let userAwareness =  getTriggerStatus(user: user)
            cell.setRooom(awareness: userAwareness)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            addFriend()
        }
        else if usersArray.count > 0 {
            let cell = self.collectionView?.cellForItem(at: indexPath) as! CustomRoomUserCell
            let selectedUser = usersArray[indexPath.row - 1] as! PFUser
            if cell.isDataSaving {
                // updating the details. processing not completed
                return
            }
            
            //Check user is active. 1) offline, 2) limbo
            if !isUserEnabledInCurrentRoom(user: selectedUser){
                if !isUserOnline(user: selectedUser) {
                    Utility.showAlertWith(message: "\(selectedUser.username ?? "") is offline")
                }
                else if selectedUser[IS_LIMBO] as? Bool ?? false {
                    Utility.showAlertWith(message: "\(selectedUser.username ?? "") has not connected their headphones.")
                }
                return
            }
            
            // check if user is busy
            if (selectedUser[USER_STATUS] as? String ?? "") == STATUS_BUSY {
                cell.showBusy(name: selectedUser.username ?? "")
                return
            }
            // check if user can hear you
            let userAwareness = Bool(selectedUser[AWARENESS] as? NSNumber ?? 0)
            let isLimbo = Bool(selectedUser[IS_LIMBO] as? NSNumber ?? 0)
            if userAwareness && !isLimbo {
                self.checkAndTriggerCurrentUser(isTriggering: true)
                let message = "\(selectedUser.username!) can hear you. Go ahead and talk."
                Utility.showAlertWith(message: message)
                //self.showAlert(message: message)
                return
            }
            //User cannot release others while the group is CoJam all model.
            
            let result = Bool(self.codejamObj[AWARENESS] as? NSNumber ?? 0)
            if result {
                let message = "You cannot release a trigger while the group is in CoJam All mode."
                Utility.showAlertWith(message: message)
                //self.showAlert(message: "You cannot release a trigger while the group is in CoJam All mode.")
                return
            }
            
            var enabledMembers: [PFUser] = codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] as? [PFUser] ?? []
            print("selectedUser:", selectedUser)
            
            if enabledMembers.contains(where: { (members) -> Bool in
                return members.objectId! == selectedUser.objectId!
            }) {
                /**Check if corresponding user is in awareness enabled array. Then remove the user awareness.*/
                if let itemIndex = enabledMembers.index(where: { (user: PFUser) -> Bool in
                    return user.objectId! == selectedUser.objectId!
                }) {
                    //print("-------- removed user:", selectedUser.username ?? "")
                    updateTriggered(user: selectedUser, status: false)
                    cell.isDataSaving = true
                    enabledMembers.remove(at: itemIndex)
                    codejamObj[ROOM_MEMBERS_AWARENESS_ENABLED] = enabledMembers
                    
                    codejamObj.saveInBackground(block: { (success, error) in
                        cell.isDataSaving = false
                        if error == nil {
                            cell.setRooom(awareness: self.getTriggerStatus(user: selectedUser))
                            self.validateAndReleaseTriggerCurrentUserAwareness()
                            
                            //Tiggering analytics: remove other user
                            let params: [String: Any] = [
                                AnalyticsParameter.username: selectedUser.username ?? "",
                                AnalyticsParameter.email: selectedUser.email ?? "",
                                AnalyticsParameter.triggeringUsername: PFUser.current()!.username ?? ""
                            ]
                            Utility.sendEvent(name: AnalyticsEvent.userInterruptionOff, param: params)
                        }
                    })
                    
//                    self.checkAndTriggerCurrentUser(isTriggering: false)
                }
            }
            else{
                //print("++++++++ added user:", selectedUser.username ?? "")
                cell.isDataSaving = true
                self.checkAndTriggerCurrentUser(isTriggering: true)
                updateTriggered(user: selectedUser, status: true)
                codejamObj.add(selectedUser, forKey: ROOM_MEMBERS_AWARENESS_ENABLED)
                codejamObj.saveInBackground(block: { (success, error) in
                    cell.isDataSaving = false
                    if error == nil {
                        cell.setRooom(awareness: self.getTriggerStatus(user: selectedUser))
                        
                        //Tiggering analytics: add other user
                        let params: [String: Any] = [
                            AnalyticsParameter.username: selectedUser.username ?? "",
                            AnalyticsParameter.email: selectedUser.email ?? "",
                            AnalyticsParameter.triggeringUsername: PFUser.current()!.username ?? ""
                        ]
                        Utility.sendEvent(name: AnalyticsEvent.userInterruptionOn, param: params)
                    }
                })
                
            }
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
}

//MARK:- Swipe Gesture
extension Jam {
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
        setUserStatus()
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
        setUserStatus()
        sendUserStatusAnalytics()
        UIView.transition(with: viewProfile, duration: TimeInterval(0.5), options: .transitionFlipFromLeft, animations: {
        }, completion: nil)
        if self.roomAwarenessMode {
            updateCurrentUser(force: false)
        }
    }
    
    //MARK:- ANALYTICS
    /**
     This function is used to send the user available and busy state time
     - Parameter isCurrentState: control variable to should send current state or previous state.
     */
    fileprivate func sendUserStatusAnalytics(isCurrentState: Bool = false) {
        if User.shared.isUserStatusLimbo {
            return
        }
        if User.shared.status == STATUS_AVAILABLE {
            // send busy time
            // his/her previous state is busy.
            if let previousTime = PFUser.current()![USER_STATUS_TIME] as? Date {
                let timeInterval = Date().timeIntervalSince(previousTime)
                let data = [
                    AnalyticsParameter.time: Utility.stringFromTime(interval: timeInterval),
                    AnalyticsParameter.username: PFUser.current()!.username ?? ""
                ]
                let event = isCurrentState ? AnalyticsEvent.groupAvailableTime : AnalyticsEvent.groupBusyTime
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
                let event = isCurrentState ? AnalyticsEvent.groupBusyTime : AnalyticsEvent.groupAvailableTime
                Utility.sendEvent(name: event, value: timeInterval/60, param: data)
            }
        }
        // reset the new time.
        PFUser.current()![USER_STATUS_TIME] = Date()
        PFUser.current()?.saveInBackground()
        
    }
}

//MARK:- LOCATION MANAGER DELEGATE
extension Jam: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed updateing location: ", error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location updated")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
    }
}

extension Jam: SRFSurfboardDelegate {
    func surfboard(_ surfboard: SRFSurfboardViewController!, didShowPanelAt index: Int) {
        
    }
    
    func surfboard(_ surfboard: SRFSurfboardViewController!, didTapButtonAt indexPath: IndexPath!) {
        surfboard.dismiss(animated: true, completion: nil)
    }
}
