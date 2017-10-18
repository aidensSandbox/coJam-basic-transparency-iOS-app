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
    @IBOutlet weak var labelTriggerValue: UILabel!
    @IBOutlet weak var sliderMicrophoneGain: UISlider!
    @IBOutlet weak var buttonFeedback: UIButton!
    
    @IBOutlet weak var versionInfo: UILabel!
    
    weak var delegate: AccountDelegate?

    fileprivate var currentMicrophoneVolume = 0
    fileprivate let minimumVolume = 0
    fileprivate var maximumVolume = 100
    
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() == nil {
            let loginVC = storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
            navigationController?.pushViewController(loginVC, animated: true)
        } else {
            // Call query
            showUserDetails()
            //currentMicrophoneVolume = Int(User.shared.audioProcessor?.gain ?? 0)
            //updateMicroPhoneVolumeCount()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonFeedback.backgroundColor = Color.green
        
        let gAppVersion:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "0"
        let gAppBuild:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "0"
        
        
        self.versionInfo.text = "version:" + gAppVersion + " build:" + gAppBuild
        
        initilize()
        //checkAndUpdateMaximumGain()
        // Init ad banners
        //initAdMobBanner()
    }
    
    fileprivate func initilize() {
        // Round views corners
        avatarImage.layer.cornerRadius = avatarImage.bounds.size.width/2
        userView.layer.cornerRadius = 8
        
        //Audio gain.
        currentMicrophoneVolume = Int(User.shared.audioProcessor?.gain ?? Float(kDefaultAudioGain))
        sliderMicrophoneGain.value = Float(currentMicrophoneVolume)
        sliderMicrophoneGain.maximumValue = Float(kMaximumGainVolume)
        sliderMicrophoneGain.minimumValue = Float(kMinimumGainVolume)
        labelTriggerValue.text = "\(currentMicrophoneVolume)"
    }


    /**
     This method is used to limit the maximum gain in Hear Everything and Hear Voices mode.
     */
    fileprivate func checkAndUpdateMaximumGain() {
        maximumVolume = kMaximumGainVolume
        
        if currentMicrophoneVolume >= maximumVolume {
            currentMicrophoneVolume = maximumVolume
            updateMicroPhoneVolumeCount()
        }
    }
     
    //MARK:- ACTIONS
    
    @IBAction func microphoneGainValueChanged(_ sender: Any) {
        let micGainSlider = sender as! UISlider
        currentMicrophoneVolume = Int(micGainSlider.value)
        updateMicroPhoneVolumeCount()
    }
    

    @IBAction func didTappedResetMicGain(_ sender: Any) {
        sliderMicrophoneGain.value = Float(kDefaultAudioGain)
        currentMicrophoneVolume = kDefaultAudioGain
        updateMicroPhoneVolumeCount()
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
        let mailComposerController = MFMailComposeViewController()
        mailComposerController.mailComposeDelegate = self
        // Configure the fields of the interface.
        mailComposerController.setToRecipients(kHelpMailRecipients)
        mailComposerController.setSubject(kHelpMailSubject)
        mailComposerController.setMessageBody(kHelpMailBody, isHTML: false)
        // Present the view controller modally.
        self.present(mailComposerController, animated: true, completion: nil)
    }
    

     //This method is used to udpate the microphone volume.
     
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
                showHUD()
                PFUser.current()?.saveInBackground(block: { (success, error) in
                    if error == nil {
                        self.informProfileUpdateSuccessfully()
                    }
                    else {
                        self.showProfileUpdateFailed(error: error)
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    /**
     This method shows the alert when updating profile Success with the description.
     */
    fileprivate func informProfileUpdateSuccessfully() {
        Utility.showAlertWith(message: "Your profile has been updated!", type: .success)
        self.hideHUD()
        self.delegate?.didChangeSettings()
    }
    
    /**
     This method shows the alert when updating profile Failed with the description.
     */
    fileprivate func showProfileUpdateFailed(error: Error?) {
        if (error?.localizedDescription ?? "").isEmpty {
            self.hideHUD()
            return
        }
        Utility.showAlertWith(message: "\(error?.localizedDescription ?? "")")
        self.hideHUD()
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
                self.informProfileUpdateSuccessfully()
            } else {
                self.showProfileUpdateFailed(error: error)
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
