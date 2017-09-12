/*-------------------------
 
 - BuzzIt -
 
 created by FV iMAGINATION © 2015
 All Rights reserved
 
 -------------------------*/

import UIKit
import Parse
import AudioToolbox
import MessageUI


// MARK: - CUSTOM CELL
class MyRoomsCell: UITableViewCell {
    /* Views */
    @IBOutlet weak var rImage: UIImageView!
    @IBOutlet weak var rTitle: UILabel!
}



protocol AccountDelegate: NSObjectProtocol {
    
    func didChangeSettings()
}



// MARK: - ACCOUNT CONTROLLER
class Account: UIViewController,
    UITextFieldDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    UIAlertViewDelegate
{
    /* Views */
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet var labelTriggerValue: UILabel!
    @IBOutlet var switchSurroundVoice: UISwitch!
    @IBOutlet var switchPlayMusic: UISwitch!
    
    
    weak var delegate: AccountDelegate?

    fileprivate var currentMicrophoneVolume = 0
    fileprivate let minimumVolume = 0
    fileprivate var maximumVolume = 100
    @IBOutlet var buttonGainIncrease: UIButton!
    @IBOutlet var buttonGainDecrease: UIButton!
    @IBOutlet weak var buttonFeedback: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() == nil {
            let loginVC = storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
            navigationController?.pushViewController(loginVC, animated: true)
        } else {
            // Call query
            showUserDetails()
            currentMicrophoneVolume = Int(User.shared.audioProcessor?.gain ?? 0)
            updateMicroPhoneVolumeCount()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initilize()
        checkAndUpdateMaximumGain()
        // Init ad banners
        //initAdMobBanner()
    }
    
    fileprivate func initilize() {
        // Round views corners
        avatarImage.layer.cornerRadius = avatarImage.bounds.size.width/2
        userView.layer.cornerRadius = 8
        
        //Initial operations related to awareness mode.
        if User.shared.awarenessMode {
            switchSurroundVoice.isEnabled = false
            switchPlayMusic.isEnabled = false
        }
        else {
            switchSurroundVoice.isEnabled = true
            switchPlayMusic.isEnabled = true
        }
        
        switchSurroundVoice.isOn = (User.shared.audioProcessor?.surroundSound ?? false)
        switchPlayMusic.isOn = (User.shared.audioProcessor?.pauseMusic ?? false)
    }
    
    /**
     This method is used to limit the maximum gain in Hear Everything and Hear Voices mode.
     */
    fileprivate func checkAndUpdateMaximumGain() {
        if (User.shared.audioProcessor?.surroundSound)! {
            maximumVolume = kMaxGainInHearVoices
        }
        else {
            maximumVolume = kMaxGainInHearEverything
        }
        
        if currentMicrophoneVolume >= maximumVolume {
            currentMicrophoneVolume = maximumVolume
            updateMicroPhoneVolumeCount()
        }
    }
    
    
    //MARK:- ACTIONS
    @IBAction func didTappedIncreaseVloume(_ sender: Any) {
        if currentMicrophoneVolume >= maximumVolume {
            currentMicrophoneVolume = maximumVolume
            return
        }
        currentMicrophoneVolume += 1
        updateMicroPhoneVolumeCount()
    }
    
    @IBAction func didTappedDecreseVolume(_ sender: Any) {
        if currentMicrophoneVolume == minimumVolume {
            currentMicrophoneVolume = minimumVolume
            return
        }
        currentMicrophoneVolume -= 1
        updateMicroPhoneVolumeCount()
    }
    
    @IBAction func didTappedChangeSurroundVoice(_ sender: Any) {
        print("Surround:", switchSurroundVoice.isOn ? "On" : "Off")
        User.shared.audioProcessor?.surroundSound = switchSurroundVoice.isOn
        UserDefaults.standard.set(switchSurroundVoice.isOn, forKey: kSurroundVoice)
        UserDefaults.standard.synchronize()
        //reset the current mic gain.
        checkAndUpdateMaximumGain()
    }
    
    @IBAction func didTappedChangePlayMusic(_ sender: Any) {
        print("Music:", switchPlayMusic.isOn ? "Play" : "Pause")
        User.shared.audioProcessor?.pauseMusic = switchPlayMusic.isOn
        UserDefaults.standard.set(switchPlayMusic.isOn, forKey: kPlayMusic)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func didTappedFeedbackButton(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            sendEmail()
        }
        else {
            Utility.showAlertWith(message: "This device is not configured to send emails. Please check the settings.")
        }
    }
    
    @IBAction func didTappedEditButton(_ sender: Any) {
        usernameTxt.becomeFirstResponder()
    }
    
    @IBAction func didTappedHelpButton(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            sendHelpEmail()
        }
        else {
            Utility.showAlertWith(message: "This device is not configured to send emails. Please check the settings.")
        }
    }
    
    @IBAction func closeBtn(_ sender: Any) {
        let previousUsername: String = PFUser.current()?[USER_USERNAME] as? String ?? ""
        if previousUsername != usernameTxt.text ?? "" {
            updateUserName()
        }
        dismiss(animated: true, completion: nil)
    }
    
    /**
     Method to send email feedback.
     */
    fileprivate func sendEmail() {
        let mailComposerController = MFMailComposeViewController()
        mailComposerController.mailComposeDelegate = self
        // Configure the fields of the interface.
        mailComposerController.setToRecipients(kFeedbackMailRecipients)
        mailComposerController.setSubject(kFeedbackMailSubject)
        mailComposerController.setMessageBody(kFeedbackMailMessage, isHTML: false)
        // Present the view controller modally.
        self.present(mailComposerController, animated: true, completion: nil)
    }
    
    
    /**
     Method to send email asking help.
     */
    fileprivate func sendHelpEmail() {
//        guard let currentUser = PFUser.current() else {
//            return
//        }
        
        //let subject = "\(currentUser.username ?? "") requested help for \(APP_NAME)"
        let mailComposerController = MFMailComposeViewController()
        mailComposerController.mailComposeDelegate = self
        // Configure the fields of the interface.
        mailComposerController.setToRecipients(kHelpMailRecipients)
        mailComposerController.setSubject(kHelpMailSubject)
        mailComposerController.setMessageBody(kHelpMailBody, isHTML: false)
        // Present the view controller modally.
        self.present(mailComposerController, animated: true, completion: nil)
    }
    
    /**
     This method is used to udpate the microphone volume.
     */
    fileprivate func updateMicroPhoneVolumeCount() {
        labelTriggerValue.text = "\(currentMicrophoneVolume)"
        User.shared.audioProcessor?.gain = Float(currentMicrophoneVolume)
    }
    
    // MARK: - SHOW CURRENT USER DETAILS
    func showUserDetails() {
        let currentUser = PFUser.current()!
        
        // Get avatar
        let imageFile = currentUser[USER_AVATAR] as? PFFile
        imageFile?.getDataInBackground { (imageData, error) -> Void in
            if error == nil {
                if let imageData = imageData {
                    self.avatarImage.image = UIImage(data:imageData)
                }}}
        
        // Get username
        usernameTxt.text = "\(currentUser[USER_USERNAME]!)"
        view.layoutIfNeeded()
    }
    
    
    // MARK: - EDIT AVATAR BUTTON
    @IBAction func editAvatarButt(_ sender: AnyObject) {
        let alert = UIAlertView(title: APP_NAME,
                                message: "Select source",
                                delegate: self,
                                cancelButtonTitle: "Cancel",
                                otherButtonTitles: "Camera", "Photo Library")
        alert.show()
    }
    // AlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.buttonTitle(at: buttonIndex) == "Camera" {
            if UIImagePickerController.isSourceTypeAvailable(.camera)
            {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
            
            
        } else if alertView.buttonTitle(at: buttonIndex) == "Photo Library" {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
    }
    
    // ImagePicker delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            avatarImage.image = image
            
            // Save Avatar Image
            if avatarImage.image != nil {
                let imageData = UIImageJPEGRepresentation(avatarImage.image!, 0.5)
                let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
                PFUser.current()![USER_AVATAR] = imageFile
                PFUser.current()?.saveInBackground(block: { (success, error) in
                    if error == nil {
                        //self.showUserDetails()
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: -  UPDATE PROFILE BUTTON
    
    /**
     Update the User name if it is not empty.
     */
    fileprivate func updateUserName() {
        let previousUserName = PFUser.current()![USER_USERNAME] as? String
        if usernameTxt.text! == "" {
            usernameTxt.text = previousUserName
            Utility.showAlertWith(message: "Username cannot be empty.")
            return
        }
        // No change in username
        if previousUserName == usernameTxt.text! {
            return
        }
        
        showHUD()
        let updatedUser = PFUser.current()!
        updatedUser[USER_USERNAME] = usernameTxt.text!
        
        // Saving block
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                Utility.showAlertWith(message: "Your profile has been updated!", type: .success)
                self.hideHUD()
                
                self.delegate?.didChangeSettings()
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
                self.usernameTxt.resignFirstResponder()
            }}
    }
    
    // MARK: - TEXT FIELD DELEGATE
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateUserName()
        usernameTxt.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


//MARK:- MAIL COMPOSER DELEGATE
extension Account: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
