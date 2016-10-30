//
//  HomeViewController.swift
//  Venting
//
//  Created by Florent Remis on 30/09/2016.
//  Copyright (c) 2016 Spersio. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class StartVentingViewController: UIViewController {
    
    @IBOutlet weak var ventRoomTitleTextField: UITextField!
    @IBOutlet weak var startVentingButton: UIButton!
    let ageCategories = [
        "15F", "20F", "25F", "30F", "35F",
        "40F", "45F", "50F", "55F", "60F",
        "65F", "70F", "75F", "80F", "85F",
        "90F", "95F", "15M", "20M", "25M",
        "30M", "35M", "40M", "45M", "50M",
        "55M", "60M", "65M", "70M", "75M",
        "80M", "85M", "90M", "95M"]
    let VENTROOM_TIMEOUT = 60*1000 // 1 hour
    let VENTROOMS_AGE_SLOTS_CHILD = "ventRoomsAgeSlots"
    let VENTROOMS_CHILD = "ventRooms"
    let TIME_LEFT_CHILD = "timeLeft"
    let LAST_UPDATE_TIME_CHILD = "lastUpdateTime"
    let VENTROOM_TITLE_CHILD = "title"
    let CREATION_TIME_CHILD = "creationTime"
    let VENTER_ID_CHILD = "venterId"
    let VENTROOM_ID_CHILD = "roomId"
    let LOCKED_CHILD = "locked"
    var userId: String?
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            if (error != nil) {
                print("Couldn't authentify")
            } else {
                self.userId = user!.uid
                print("Authentification successful")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ventRoomViewController = segue.destination as! VentRoomViewController
        if segue.identifier == "startVentingSegue" {
            let ventRoomTitle = ventRoomTitleTextField.text
            let ventRoomId = openNewVentRoom(userId!, ventRoomTitle!, floor(NSDate().timeIntervalSince1970));
            ventRoomViewController.ventRoomId = ventRoomId
            ventRoomViewController.userName = "Venter"
        }
    }
    
    func openNewVentRoom(_ localUserId: String, _ ventRoomTitle: String, _ currentTime: Double) -> String {
        ref = FIRDatabase.database().reference()
        let roomId = "\(currentTime)" + localUserId
        let ventRoom: [String: Any] = [
                        "title": ventRoomTitle,
                        "roomId": roomId,
                        "creationTime": FIRServerValue.timestamp(),
                        "lastUpdateTime": FIRServerValue.timestamp(),
                        "timeLeft": VENTROOM_TIMEOUT,
                        "locked": false,
                        "venterId": localUserId]
        let ventRoomsAgeSlot: [String: Any] = [
                        "title": ventRoomTitle,
                        "roomId": roomId,
                        "creationTime": FIRServerValue.timestamp(),
                        "userId": localUserId]
        var childVentRoomsAgeSlotUpdates = [String: Any]()
        for i in 0..<ageCategories.count {
            childVentRoomsAgeSlotUpdates["/\(VENTROOMS_AGE_SLOTS_CHILD)/\(ageCategories[i])/\(roomId)"] = ventRoomsAgeSlot
        }
        ref.updateChildValues(childVentRoomsAgeSlotUpdates)
        let childVentRoomUpdate: [String: Any] = ["/\(VENTROOMS_CHILD)/\(roomId)": ventRoom]
        ref.updateChildValues(childVentRoomUpdate)
        return roomId
    }
    
    @IBAction func startVenting(_ sender: AnyObject) {
        if userId != nil {
            if ventRoomTitleTextField.text!.characters.count > 10 {
                if ventRoomTitleTextField.text!.characters.count < 100 {
                    performSegue(withIdentifier: "startVentingSegue", sender: self)
                }
            }
        }
    }
}
