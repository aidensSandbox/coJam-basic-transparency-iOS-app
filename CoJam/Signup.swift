/*-------------------------
 
 - BuzzIt -
 
 created by FV iMAGINATION © 2015
 All Rights reserved
 
 -------------------------*/

import UIKit
import Parse

class Signup: UIViewController,
    UITextFieldDelegate
{
    
    /* Views */
    @IBOutlet var containerScrollView: UIScrollView!
    @IBOutlet var usernameTxt: UITextField!
    @IBOutlet var passwordTxt: UITextField!
    @IBOutlet weak var emailTxt: UITextField!
    
    @IBOutlet weak var contView: UIView!
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contView.frame.size.width = view.frame.size.width
        containerScrollView.addKeyboardNotification()
        
        navigationController?.isNavigationBarHidden = true
        usernameTxt.delegate = self
        passwordTxt.delegate = self
        emailTxt.delegate = self
    }
    
    deinit {
        containerScrollView.removeKeyboardNotification()
    }
    
    
    @IBAction func cancel(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // TAP TO DISMISS KEYBOARD
    @IBAction func tapToDismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        usernameTxt.resignFirstResponder()
        passwordTxt.resignFirstResponder()
        emailTxt.resignFirstResponder()
    }
    
    
    // MARK: - SIGNUP BUTTON
    @IBAction func signupButt(_ sender: AnyObject) {
        dismissKeyboard()
        showHUD()
        
        let userForSignUp = PFUser()
        userForSignUp.username = usernameTxt.text!.lowercased()
        userForSignUp.password = passwordTxt.text
        if(emailTxt.text?.isEmpty == false)
        {
            userForSignUp.email = emailTxt.text
        }
    
        userForSignUp[USER_STATUS] = STATUS_AVAILABLE
        userForSignUp[IS_LIMBO] = !Utility.isHeadphoneConnected()
        userForSignUp.signUpInBackground { (succeeded, error) -> Void in
            if error == nil { // Successful Signup
                self.dismiss(animated: true, completion: nil)
                self.hideHUD()
                
            } else { // No signup, something went wrong
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
            }}
    }
    
    
    
    // MARK: -  TEXTFIELD DELEGATE
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTxt {   passwordTxt.becomeFirstResponder()  }
        if textField == passwordTxt {   emailTxt.becomeFirstResponder()  }
        if textField == emailTxt {   emailTxt.resignFirstResponder()  }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        containerScrollView.scrollRectToVisible(textField.frame, animated: true)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
