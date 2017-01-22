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
    
    let VENTROOMS_CHILD = "ventRooms"
    let VENTROOMS_AGE_SLOTS_CHILD = "ventRoomsAgeSlots"
    let MESSAGES_CHILD = "messages"
    let TIME_LEFT_CHILD = "timeLeft"
    let LAST_UPDATE_TIME_CHILD = "lastUpdateTime"
    let VENTROOM_TIMEOUT = 2*60*60*1000 // 1 hour, 1 min
    let VENTROOM_LIFESPAN = 60*60*1000 // 1 hour
    let ageCategories =  [
    "15F", "20F", "25F", "30F", "35F",
    "40F", "45F", "50F", "55F", "60F",
    "65F", "70F", "75F", "80F", "85F",
    "90F", "95F", "15M", "20M", "25M",
    "30M", "35M", "40M", "45M", "50M",
    "55M", "60M", "65M", "70M", "75M",
    "80M", "85M", "90M", "95M"]
    var ventRoomId: String?
    var userName: String?
    var userId: String?
    // Instance variables
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    @IBOutlet weak var messagesTable: UITableView!
    
    let reuseIdentifier = "MessageCell"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            if (error != nil) {
                print("Couldn't authentify")
            } else {
                self.userId = user!.uid
                print("Authentification successful")
            }
        }
        self.messagesTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        configureDatabase()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.ref.child(MESSAGES_CHILD).child(ventRoomId!).removeObserver(withHandle: _refHandle)
    }
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.child(MESSAGES_CHILD).child(ventRoomId!).observe(.childAdded, with: { (snapshot) -> Void in
            self.messages.append(snapshot)
            self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
        })
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        // Push data to Firebase Database
        if (textField.text!.characters.count > 0 && userName != nil && userId != nil) {
            let message = ["text": textField.text, "sender": userName];
            self.ref.child(MESSAGES_CHILD).child(ventRoomId!).childByAutoId().setValue(message);
        }
    }
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell: MessageCell = self.messagesTable.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MessageCell
        // Unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
        let message = messageSnapshot.value as! Dictionary<String, String>
        let text = message["text"] as String?
        let sender = message["sender"] as String?
        print(text!)
        print(sender!)
        cell.messageText.text = text
        cell.sender.text = sender
        return cell
    }
}
