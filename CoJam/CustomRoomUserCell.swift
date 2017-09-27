//
//  CustomRoomUserCell.swift
//  CoJam
//
//  Created by apple on 8/18/17.
//  Copyright © 2017 Audesis. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage

class CustomRoomUserCell: UICollectionViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var awarenessImage: UIImageView!
    @IBOutlet weak var labelUsername: UILabel?
    @IBOutlet var labelBusy: UILabel?
    
    @IBOutlet var userActivityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var indicatorView: UIView?
    
    var isDataSaving: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.isDataSaving {
                    self.indicatorView?.isHidden = false
                    self.userActivityIndicator?.startAnimating()
                }
                else {
                    self.indicatorView?.isHidden = true
                    self.userActivityIndicator?.stopAnimating()
                }
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelBusy?.isHidden = true
        labelUsername?.text = ""
        self.userImage.image = nil
        self.userImage.layer.cornerRadius =  self.userImage.frame.size.height / 2;
        self.userImage.clipsToBounds = true
        self.userImage.layer.borderWidth = 6.0     //default 4.0
        self.userImage.backgroundColor = UIColor.clear
        
        self.labelBusy?.layer.cornerRadius = self.userImage.layer.cornerRadius
        self.labelBusy?.backgroundColor = Color.red
        self.indicatorView?.layer.cornerRadius = self.userImage.layer.cornerRadius
        self.indicatorView?.isHidden = true
        
        self.awarenessImage.layer.cornerRadius = self.awarenessImage.frame.size.width / 2;
        self.awarenessImage.clipsToBounds = true
        self.awarenessImage.layer.borderWidth = 1.5
        self.awarenessImage.layer.borderColor = UIColor.black.cgColor
        self.awarenessImage.isHidden = true
        
        userActivityIndicator?.stopAnimating()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        labelBusy?.isHidden = true
        self.indicatorView?.isHidden = true
        self.userImage.af_cancelImageRequest()
        self.userImage.image = nil
        self.labelUsername?.font = UIFont.systemFont(ofSize: 15)
        self.awarenessImage.isHidden = true
    }
    
    func showBusy(name: String) {
        labelBusy?.alpha = 0.9
        labelBusy?.isHidden = false
        labelBusy?.text = name == "" ? "Busy" : "\(name) is Busy"
        Timer.scheduledTimer(timeInterval: TimeInterval(2), target: self, selector: #selector(hideBusyLabel), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func hideBusyLabel(){
        UIView.animate(withDuration: TimeInterval(0.5)) {
            self.labelBusy?.alpha = 0
            self.labelBusy?.isHidden = true
        }
    }
    
    func setProfile(image: PFFile?) {
        userImage.contentMode = .scaleAspectFill
        self.userImage.image = UIImage(named: "logo")
        if let url = URL(string: image?.url ?? "") {
            self.userImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "logo"))
        }
    }
    
    func setRooom(awareness: Bool) {
        DispatchQueue.main.async {
            if awareness {
                self.awarenessImage.isHidden = false;
            } else{
                
                self.awarenessImage.isHidden = true;
            }
        }
    }
}
