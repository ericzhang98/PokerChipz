//
//  AdjustController.swift
//  PokerChipz
//
//  Created by Eric Zhang on 1/10/17.
//  Copyright © 2017 Eric Zhang. All rights reserved.
//

import Foundation
import UIKit

class AdjustController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var game:Game = Game()
    var selectedIndex:Int = -1
    var inBetweenGame:Bool = false
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    @IBOutlet var amountTextField: UITextField!
    @IBAction func minusButtonClick(_ sender: Any) {
        if self.selectedIndex != -1 {
            if let amount:Int = Int(self.amountTextField.text!) {
                self.game.players[self.selectedIndex].removeChips(chips: amount)
                self.tableView.reloadData()
            }
            else {
                self.badInputAlert()
            }
        }
        else {
            self.selectSomeoneAlert()
        }
    }
    @IBAction func plusButtonClick(_ sender: Any) {
        if self.selectedIndex != -1 {
            if let amount:Int = Int(self.amountTextField.text!) {
                self.game.players[self.selectedIndex].addChips(chips: amount)
                self.tableView.reloadData()
            }
            else {
                self.badInputAlert()
            }
        }
        else {
            self.selectSomeoneAlert()
        }
    }
    
    @IBOutlet var nameTextField: UITextField!
    @IBAction func addPlayerClick(_ sender: Any) {
        if self.inBetweenGame {
            let nameInput:String = self.nameTextField.text!
            let newPlayer:Player = Player(name: nameInput)
            
            if !nameInput.isEmpty && !self.game.players.contains(newPlayer) {
                self.game.players.append(newPlayer)
                self.tableView.reloadData()
                self.nameTextField.text = ""
            }
            else {
                self.badNameAlert()
            }
        }
        else {
            self.notInBetweenGameAlert()
        }
    }
    
    
    @IBOutlet var bigBlindTextField: UITextField!
    @IBOutlet var smallBlindTextField: UITextField!
    
    func selectSomeoneAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "Please select a player", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func badInputAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "Please enter a valid amount", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func notInBetweenGameAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "You can only adjust players in between games", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func badNameAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "Please enter a valid non-duplicate name", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func lessThanTwoAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "You can't have less than 2 people in a poker game", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func returnToGame(_ sender: Any) {
        //change big and small blinds to what they were set to
        if let bigBlindChange:Int = Int(self.bigBlindTextField.text!) {
            if bigBlindChange >= 0 {
                self.game.bigBlindSize = bigBlindChange
            }
        }
        if let smallBlindChange:Int = Int(self.smallBlindTextField.text!) {
            if smallBlindChange >= 0 {
                self.game.smallBlindSize = smallBlindChange
            }
        }
        
        //update game and add a copy onto the game state stack
        self.game.gameController?.updateViews()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.bigBlindTextField.text = "\(self.game.bigBlindSize)"
        self.smallBlindTextField.text = "\(self.game.smallBlindSize)"
        self.addDoneButtonOnKeyboard()
        self.tableView.isEditing = true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //resize tableview
        if (self.game.players.count >= 6) {
            self.tableViewHeight.constant = CGFloat(264)
        }
        else {
            self.tableViewHeight.constant = CGFloat(self.game.players.count * 44)
        }
        return self.game.players.count
    }
    
    func tableView(_ tableView:UITableView, cellForRowAt IndexPath:IndexPath)  -> UITableViewCell{
        let cell:GamePlayerCell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! GamePlayerCell
        
        //format cell with names, chips, and blinds
        let player = self.game.players[IndexPath.row]
        cell.name.text = player.name
        cell.chips.text = "\(player.chips)"
        cell.blind.text = ""
        
        //make selected player gray
        if IndexPath.row == self.selectedIndex {
            cell.backgroundColor = UIColor.lightGray
        }
        else {
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if self.inBetweenGame {
                if self.game.players.count > 2 {
                    self.game.players.remove(at: indexPath.row) //TODO: blind adjustment is a little bit jank b/c I don't keep track of dealer
                    if indexPath.row <= self.game.bigBlindIndex {
                        self.game.moveBlindsBackward()
                    }
                    self.selectedIndex = -1
                    self.tableView.reloadData()
                }
                else {
                    self.lessThanTwoAlert()
                }
            }
            else {
                self.notInBetweenGameAlert()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if self.inBetweenGame {
            let movingPlayer:Player = self.game.players.remove(at: sourceIndexPath.row)
            self.game.players.insert(movingPlayer, at: destinationIndexPath.row)
            self.tableView.reloadData()
        }
        else {
            self.notInBetweenGameAlert()
        }
    }
    
    
    /* Text field delegate/setup -------------------------------------------------------------------------*/
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done:UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(AdjustController.doneButtonAction))
        
        var items:[UIBarButtonItem] = []
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.amountTextField.inputAccessoryView = doneToolbar
        self.bigBlindTextField.inputAccessoryView = doneToolbar
        self.smallBlindTextField.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction() {
        self.amountTextField.resignFirstResponder()
        self.bigBlindTextField.resignFirstResponder()
        self.smallBlindTextField.resignFirstResponder()
    }
    
}
