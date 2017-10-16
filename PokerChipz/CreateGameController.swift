//
//  CreateGameController.swift
//  PokerChipz
//
//  Created by Eric Zhang on 12/26/16.
//  Copyright © 2016 Eric Zhang. All rights reserved.
//

import Foundation
import UIKit

class CreateGameController:UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var addedPlayerNames:[String] = []
    
    @IBAction func done(_ sender: Any) {
        //create an array of player names from input
        addedPlayerNames = []
        for i in 0...9 {
            let nameInput = (self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! AddPlayerCell).textField.text
            if !(nameInput?.isEmpty)! { //only process non-empty names
                addedPlayerNames.append(nameInput!)
            }
        }
        
        //check names entered, if more than 1, advance to next screen
        if self.addedPlayerNames.count > 1 && !containsDuplicates(array: self.addedPlayerNames){
            performSegue(withIdentifier: "showGame", sender: self)
        }
        else {
            let alert = UIAlertController(title: "Uh oh!", message: "You need 2 or more players for a poker game! Make sure there aren't any duplicates too!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func containsDuplicates(array:[String]) -> Bool{
        return Set(array).count != array.count
    }

    @IBOutlet var tableView: UITableView!
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:AddPlayerCell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! AddPlayerCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:AddPlayerCell = tableView.cellForRow(at: indexPath) as! AddPlayerCell
        cell.textField.becomeFirstResponder()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGame" {
            var players:[Player] = []
            for name in addedPlayerNames {
                players.append(Player(name: name))
            }
            
            //init new game with players and pass to GameController (game controller can process initial info more easily too)
            let game = Game(players: players, gameController: segue.destination as! GameController)
            (segue.destination as! GameController).game = game
        }
    }
}
