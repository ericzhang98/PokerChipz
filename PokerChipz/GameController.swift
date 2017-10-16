//
//  GameController.swift
//  PokerChipz
//
//  Created by Eric Zhang on 12/27/16.
//  Copyright © 2016 Eric Zhang. All rights reserved.
//

import Foundation
import UIKit

class GameController:UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var game:Game = Game() //current game state (dummy game pre-init)
    var gameStates:[Game] = [] //stack of game states, pop and set as current game to go back
    var button:UIButton? //for return key
    
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var potLabel: UILabel!
    @IBOutlet var betLabel: UILabel!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var roundLabel: UILabel!
    @IBOutlet var turnLabel: UILabel!

    
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var middleButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    @IBAction func leftButtonClick(_ sender: Any) {
        self.performSelector(onMainThread: Selector(self.leftButton.currentTitle!.lowercased()), with: nil, waitUntilDone: false)
    }
    @IBAction func middleButtonClick(_ sender: Any) {
        self.performSelector(onMainThread: Selector(self.middleButton.currentTitle!.lowercased()), with: nil, waitUntilDone: false)
    }
    @IBAction func rightButtonClick(_ sender: Any) {
        self.performSelector(onMainThread: Selector(self.rightButton.currentTitle!.lowercased()), with: nil, waitUntilDone: false)
    }
    @IBAction func nextButtonClick(_ sender: Any) {
        self.nextButton.isHidden = true
        if self.game.currentRound == -1 {
            self.game.startGame()
        }
        else if self.game.currentRound == 5 {
            self.game.nextGame()
        }
    }
    @IBAction func backButtonClick(_ sender: Any) {
        if self.gameStates.count > 1 {
            print("GOING BACK ONE GAME STATE")
            self.gameStates.removeLast() //get rid of current game state
//            self.game = self.gameStates.removeLast() //remove second to last game (previous state) set current game to it
//            self.updateViews() //call update views which re-inserts the previous game state into gameStates
            self.game = self.gameStates.last!.copy() as! Game //saves a copy of previous state as current game
            self.updateViews(shouldSaveGameState: false) //update views without saving game state
        }
    }
    
    func fold() {
        self.game.fold()
    }
    
    func check() {
        self.game.check()
    }
    
    func call() {
        self.game.call()
    }
    
    func bet() {
        if let betInput = Int(self.amountTextField.text!), betInput > 0 {
            self.game.bet(chips: betInput)
            self.amountTextField.text = ""
            self.amountTextField.resignFirstResponder()
        }
        else {
            self.badInputAlert()
        }
    }
    
    func raise() {
        if let raiseInput = Int(self.amountTextField.text!), raiseInput > self.game.currentBet {
            self.game.raise(chips: raiseInput)
            self.amountTextField.text = ""
            self.amountTextField.resignFirstResponder()
        }
        else {
            self.badInputAlert()
        }
    }
    
    func badInputAlert() {
        let alert = UIAlertController(title: "Uh oh!", message: "Please enter a valid amount", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.updateViews()
        self.addDoneButtonOnKeyboard()
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
        
        if self.game.bigBlindIndex == IndexPath.row {
            cell.blind.text = "B"
        }
        else if self.game.smallBlindIndex == IndexPath.row {
            cell.blind.text = "S"
        }
        else {
            cell.blind.text = ""
        }
        
        //color code for current turn and still in round
        if !self.game.playersStillInRound.contains(self.game.players[IndexPath.row]) {
            //make cell gray
            cell.backgroundColor = UIColor.gray
        }
        else if self.game.players[IndexPath.row] == self.game.currentTurnPlayer() {
            //make cell green
            cell.backgroundColor = UIColor.green
        }
        else {
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.game.currentRound == 4 {
            self.game.handleWin(player: self.game.players[indexPath.row])
        }
    }
    
    func updateViews(shouldSaveGameState:Bool = true) { //update views in viewcontroller and save curr game in game states
        //update tableview and labels
        self.tableView.reloadData()
        self.potLabel.text = "Pot: \(self.game.totalPot)"
        self.betLabel.text = "Bet: \(self.game.currentBet)"
        switch self.game.currentRound {
        case -1:
            self.roundLabel.text = "Waiting to start..."
            self.nextButton.setTitle("Start game", for: .normal)
        case 0:
            self.roundLabel.text = "Round: Pre-flop"
        case 1:
            self.roundLabel.text = "Round: Flop"
        case 2:
            self.roundLabel.text = "Round: Turn"
        case 3:
            self.roundLabel.text = "Round: River"
        case 4:
            self.roundLabel.text = "Select Winner!"
        case 5:
            self.roundLabel.text = "Ready for next game..."
            self.nextButton.setTitle("Next game", for: .normal)
        default:
            self.roundLabel.text = "Round: "
        }
        self.turnLabel.text = "Current turn: \(self.game.currentTurnPlayer().name)"
        
        //update butons based off of current player's bet vs game's current bet
        if self.game.currentTurnPlayer().currentBet == self.game.currentBet {
            if self.game.currentBet == 0 {
                self.leftButton.setTitle("Fold", for: .normal)
                self.middleButton.setTitle("Check", for: .normal)
                self.rightButton.setTitle("Bet", for: .normal)
            }
            else {
                self.leftButton.setTitle("Fold", for: .normal)
                self.middleButton.setTitle("Check", for: .normal)
                self.rightButton.setTitle("Raise", for: .normal)
            }
        }
        else {
            self.leftButton.setTitle("Fold", for: .normal)
            self.middleButton.setTitle("Call", for: .normal)
            self.rightButton.setTitle("Raise", for: .normal)
        }
        
        //process hiding for buttons/labels
        let actionEnabled = (self.game.currentRound >= 0) && (self.game.currentRound <= 3)
        self.leftButton.isHidden = !actionEnabled
        self.middleButton.isHidden = !actionEnabled
        self.rightButton.isHidden = !actionEnabled
        self.turnLabel.isHidden = !actionEnabled
        
        let nextEnabled = (self.game.currentRound == -1) || (self.game.currentRound == 5)
        self.nextButton.isHidden = !nextEnabled

        if shouldSaveGameState {
            print("SAVING GAME STATE")
            self.saveGameState()
        }
    }
    
    func saveGameState() {
        self.gameStates.append(self.game.copy() as! Game)
        if self.gameStates.count > 20 {
            self.gameStates.removeFirst()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAdjust" {
            (segue.destination as! AdjustController).game = self.game
            (segue.destination as! AdjustController).inBetweenGame =
                (self.game.currentRound == -1) || (self.game.currentRound == 5)
        }
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done:UIBarButtonItem =
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(GameController.doneButtonAction))
        
        var items:[UIBarButtonItem] = []
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.amountTextField.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction() {
        self.amountTextField.resignFirstResponder()
    }
}
