//
//  HomeViewController.swift
//  Venting
//
//  Created by Florent Remis on 30/09/2016.
//  Copyright (c) 2016 Spersio. All rights reserved.
//

import UIKit

import Firebase

class VentRoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
UITextFieldDelegate, UINavigationControllerDelegate {
    
    var ventRoomId: String?
    var userName: String?
    // Instance variables
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    @IBOutlet weak var clientTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        
        configureDatabase()    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.ref.child("messages").removeObserver(withHandle: _refHandle)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.child("messages").observe(.childAdded, with: { (snapshot) -> Void in
            self.messages.append(snapshot)
            self.clientTable.insertRowsAtIndexPaths([NSIndexPath(forRow: self.messages.count-1, inSection: 0)], withRowAnimation: .Automatic)
        })
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        textFieldShouldReturn(textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= self.msglength.intValue // Bool
    }
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell: UITableViewCell! = self.clientTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.MessageFields.name] as String!
        if let imageUrl = message[Constants.MessageFields.imageUrl] {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX){ (data, error) in
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    cell.imageView?.image = UIImage.init(data: data!)
                }
            } else if let url = URL(string:imageUrl), let data = Data(contentsOfURL: url) {
                cell.imageView?.image = UIImage.init(data: data)
            }
            cell!.textLabel?.text = "sent by: \(name)"
        } else {
            let text = message[Constants.MessageFields.text] as String!
            cell!.textLabel?.text = name + ": " + text
            cell!.imageView?.image = UIImage(named: "ic_account_circle")
            if let photoUrl = message[Constants.MessageFields.photoUrl], let url = URL(string:photoUrl), let data = Data(contentsOfURL: url) {
                cell!.imageView?.image = UIImage(data: data)
            }
        }
        return cell!
    }
    
    // UITextViewDelegate protocol methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let data = [Constants.MessageFields.text: textField.text! as String]
        sendMessage(data)
        return true
    }
    
    func sendMessage(_ data: [String: String]) {
        var mdata = data
        mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
        if let photoUrl = AppState.sharedInstance.photoUrl {
            mdata[Constants.MessageFields.photoUrl] = photoUrl.absoluteString
        }
        // Push data to Firebase Database
        self.ref.child("messages").childByAutoId().setValue(mdata)
    }
    }
