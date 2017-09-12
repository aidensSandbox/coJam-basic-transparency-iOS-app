    //
//  Users.swift
//  CodeJam
//
//  Created by Raminelli, Alvaro on 6/14/17.
//  Copyright © 2017 FV iMAGINATION. All rights reserved.
//

import UIKit
import Parse
import SwiftMessages

protocol UsersDelegate: NSObjectProtocol {
    func didAddedNewMember(_ user: PFUser)
}


class Users: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    
    var usersArray = [PFObject]()
    var roomObj = PFObject(className: ROOMS_CLASS_NAME)
    fileprivate var addedUser: PFUser!
    
    let cellReuseIdentifier = "cell"

    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var buttonInvite: UIButton!
    
    weak var delegate: UsersDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the table view cell class and its reuse id
        self.usersTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        usersTableView.delegate = self
        usersTableView.dataSource = self
        searchBar.delegate = self
        queryUsers()
        roomObj = User.shared.currentRoom!
        roomObj.fetchInBackground()
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /**
     Inviting friends.
     */
    @IBAction func inviteButtonTapped(_ sender: Any) {
        let activityController = UIActivityViewController(activityItems: [kMessageInviteText], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = self.view
        activityController.excludedActivityTypes = [.airDrop]
        present(activityController, animated: true, completion: nil)
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        // Hide the cancel button
        searchBar.showsCancelButton = false
        // You could also change the position, frame etc of the searchBar
    }
    
    //Mark:- TableView Datasource and Delegate
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usersArray.count
    }
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = usersTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        
        var user = PFUser()
        user = usersArray[(indexPath as NSIndexPath).row] as! PFUser
        
        // set the text from the data model
        cell.textLabel?.text = "\(user[USER_USERNAME]!)"
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var user = PFUser()
        user = usersArray[(indexPath as NSIndexPath).row] as! PFUser
        
        //Check if user is already in this group. Then no need to add him again.
        if isUserAlreadyAdded(user: user) {
            let message = "\(user.username ?? "") is already member of group \(roomObj[ROOMS_NAME] ?? "")"
            Utility.showAlertWith(message: message)
            return
        }
        
        //Check if user in anyother group.If not then add him to the group.
        if !isUserInAnotherGroup(user) {
            addUser(user)
        }
    }
    
    // MARK: - QUERY USERS
    func queryUsers() {
        showHUD()
        usersArray.removeAll()
        let query = PFUser.query()
        query?.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        query?.addAscendingOrder("username")
        query?.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects!
                self.usersTableView.reloadData()
                self.hideHUD()
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
            }}
    
    }
    
    /**
     This function is used to validate the current user is now entered in any other group.
     */
    fileprivate func isUserInAnotherGroup(_ user: PFUser) -> Bool {
        if user[USER_CURRENTROOM] != nil {
            /*
            let alert = UIAlertController(title: APP_NAME,
                                          message: "Sorry, \(user.username ?? "") is currently in another cojam circle. Please ask them to leave the group then try to add them again.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(ok);
            present(alert, animated: true, completion: nil)
            */
            
            Utility.showAlertWith(message: "Sorry, \(user.username ?? "") is currently in another cojam circle. Please ask them to leave the group then try to add them again.")
            return true
        }
        return false
    }
    
    //let CODEJAM_INVITE_CLASS_NAME = "CodeJamInvite"
    //let CODEJAM_INVITE_USER_POINTER = "userPointer"
    //let CODEJAM_INVITE_ROOM_POINTER = "roomPointer"
    
    /**
     Checking the selected user is already member of the corresponding group.
     */
    fileprivate func isUserAlreadyAdded(user: PFUser) -> Bool {
        let memberUser = roomObj[ROOM_MEMBERS] as? [PFUser] ?? []
        let groupMembers = memberUser.map({ $0.objectId! })
        if groupMembers.contains(user.objectId!) {
            return true
        }
        return false
    }
    
    func addUser(_ user: PFUser) {
        print("### Saving Invite ###")
        
        let params = [
            "targetObjectId": user.objectId ?? "",
            "roomId" : self.roomObj.objectId ?? ""
            ] as [String : Any]
        PFCloud.callFunction(inBackground: "setRoomForUser", withParameters: params, block: { (response, error) in
            if error != nil {
                print("error:", error?.localizedDescription ?? "")
            }
        })
        
        let jamObj = PFObject(className: CODEJAM_INVITE_CLASS_NAME)
        jamObj[CODEJAM_INVITE_USER_POINTER] = user
        jamObj[CODEJAM_INVITE_ROOM_POINTER] = roomObj
        jamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.addedUser = user
                self.roomObj.add(user, forKey: ROOM_MEMBERS)
                self.roomObj.saveInBackground()
                self.closeWith(user: user)
            } else {
                print("\(error!.localizedDescription)")
            }
        }
    }
    
    func closeWith(user: PFUser){
        Utility.showAlertWith(message: "\(user.username ?? "") has been added to this group.", type: Theme.success)
        self.delegate?.didAddedNewMember(self.addedUser)
        self.dismiss(animated: true, completion: nil)
    }
    
    // CREATE ROOM BUTTON -> SAVE IT TO PARSE DATABASE
    /*@IBAction func createRoomButt(_ sender: AnyObject) {
        
        if nameTxt.text != "" {
            showHUD()
            
            let roomsClass = PFObject(className: ROOMS_CLASS_NAME)
            let currentUser = PFUser.current()
            
            // Save PFUser as a Pointer
            roomsClass[ROOMS_USER_POINTER] = currentUser
            
            // Save data
            roomsClass[ROOMS_NAME] = nameTxt.text!.uppercased()
            
            // Save Image (if exists)
            if roomImage.image != nil {
                let imageData = UIImageJPEGRepresentation(roomImage.image!, 0.8)
                let imageFile = PFFile(name:"image.jpg", data:imageData!)
                roomsClass[ROOMS_IMAGE] = imageFile
            }
            
            // Saving block
            roomsClass.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.simpleAlert("Your new room has been created!")
                    self.hideHUD()
                    self.dismiss(animated: true, completion: nil)
                    
                } else {
                    self.simpleAlert("\(error!.localizedDescription)")
                    self.hideHUD()
                }}
            
            
            // You must type a title
        } else {
            simpleAlert("You must type a title to your Room!")
        }
    }*/
    
}
