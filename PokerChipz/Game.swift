//
//  Game.swift
//  PokerChipz
//
//  Created by Eric Zhang on 12/26/16.
//  Copyright © 2016 Eric Zhang. All rights reserved.
//

import Foundation
import UIKit

class Game: NSCopying {
    var players:[Player] = []
    var currentTurnIndex = -1
    var playersStillInRound:[Player] = []
    var bigBlindSize = 2
    var smallBlindSize = 1
    var bigBlindIndex = -1
    var smallBlindIndex = -1
    var currentBet = 0
    var totalPot = 0
    var currentRound = -1 //-1 - waiting to start, 0 - preflop, 1 - flop, 2 - turn, 3 - river, 4 - select winner, 5 - waiting for next game
    var winnerIndex = -1
    var gameController:GameController?
    var autoProceed = false
    
    func currentTurnPlayer() -> Player {
        if currentTurnIndex >= 0 && currentTurnIndex < players.count {
            return players[currentTurnIndex]
        }
        else { //error handling for current turn label
            return Player(name: "") //dummy player if no current turn player right now, just for current turn label
        }
    }
    
    
    /* Next game state functions --------------------------------------------------------------------------------------*/
    
    func nextAction() { //processes next game state and updates view (except for selecting winner - handleWin processes it)
        print ("next action called")
        //check if player has won and call winner if true
        if self.playersStillInRound.count == 1 {
            handleWin(player: self.playersStillInRound[0]) //updates view after handling win
        }
        else {
            //check if nextRound or nextTurn
            if self.roundShouldEnd() {
                self.nextRound() //if round is 4 - update game controller and wait for winner selection
            }
            //otherwise proceed to next player's turn, which is next player who's in playersStillInRound
            else {
                self.nextTurn()
            }
            self.gameController?.updateViews()
        }
    }
    
    func nextTurn() {
        print("next turn")
        repeat {
            self.currentTurnIndex = nextIndex(self.currentTurnIndex)
        } while !playersStillInRound.contains(self.currentTurnPlayer())
        print("Current turn: \(self.currentTurnPlayer().name)")
    }
    
    func roundShouldEnd() -> Bool{ //makes sure each player's bet is equal to current bet
        for eachPlayer in self.playersStillInRound {
            if !eachPlayer.hasBetThisRound || eachPlayer.currentBet != self.currentBet {
                print("\(eachPlayer.name) hasn't done anything yet: \(eachPlayer.hasBetThisRound) on betThisRound and \(eachPlayer.currentBet) current bet")
                return false
            }
        }
        return true
    }
    
    func resetBets() { //resets current bet and all player bets
        self.currentBet = 0
        for eachPlayer in self.players {
            eachPlayer.currentBet = 0
            eachPlayer.hasBetThisRound = false
        }
    }

    func nextRound() { //processes next round (if winner selection, update round and wait for GameController to call handleWin)
        print("next round")
        if self.currentRound < 3 {
            self.currentTurnIndex = self.smallBlindIndex
            while !playersStillInRound.contains(self.currentTurnPlayer()) {
                self.currentTurnIndex = nextIndex(self.currentTurnIndex)
            }
            self.currentRound+=1
            self.resetBets()
            
            if self.currentRound == 1 {
                print("Round: Flop")
            }
            else if self.currentRound == 2 {
                print("Round: Turn")
            }
            else if self.currentRound == 3 {
                print("Round: River")
            }
            
            print("Current turn: \(self.currentTurnPlayer().name)")
        }
        //showdown (have user select winner)
        else if self.currentRound == 3 {
            print("Select winner")
            self.currentRound += 1 //round 4 so didSelectRow will process and update winner
        }
    }
    
    func handleWin(player:Player) { //called after player mucks it, or when winner is selected in GameController
        print("\(player.name) wins \(self.totalPot) chips")
        player.addChips(chips: self.totalPot)
        if autoProceed {
            self.nextGame()
            self.gameController?.updateViews()
        }
        else {
            self.currentRound = 5
            self.gameController?.updateViews()
        }
    }
    
    func nextGame() { //resets pot, bets, round number, players still in round, and increments blinds and starting player
        print("next game")
        //put everyone back in
        self.playersStillInRound = self.players

        //reset current bet and total pot
        self.resetBets()
        self.totalPot = 0
        self.currentRound = 0
        
        //move blinds to next people and set starting turn
        self.moveBlindsForward()
        self.currentTurnIndex = nextIndex(self.bigBlindIndex)
        self.processBlinds()
        
        print("Next game with: \nPlayers: \(self.formatNames(players:self.players)) \nSmall blind: \(self.players[self.smallBlindIndex].name) \nBig blind: \(self.players[self.bigBlindIndex].name)")
        print("Round: Pre-flop")
        print("Current turn: \(self.currentTurnPlayer().name)")
        
        self.gameController?.updateViews()
    }
    
    func startGame() {
        print("STARTING GAME")
        //put everyone in
        self.playersStillInRound = self.players
        
        //set up random big/small blind index and starting turn
        let rng = Int(arc4random_uniform(UInt32(players.count)))
        self.bigBlindIndex = rng
        self.smallBlindIndex = prevIndex(self.bigBlindIndex)
        self.currentTurnIndex = nextIndex(self.bigBlindIndex)
        self.processBlinds()
        
        self.currentRound = 0
        
        print("Created game with: \nPlayers: \(self.formatNames(players: self.players)) \nSmall blind: \(self.players[self.smallBlindIndex].name) \nBig blind: \(self.players[self.bigBlindIndex].name) \nGLHF!")
        print("Round: Pre-flop")
        print("Current turn: \(self.currentTurnPlayer().name)")
        
        self.gameController?.updateViews()
    }
    
    
    /* Player action functions ------------------------------------------------------------------------------------*/
    
    func currentPlayerPutIn(chips:Int) {
        print("\(self.currentTurnPlayer().name) put in \(chips) chips")
        self.totalPot += chips
        self.currentTurnPlayer().removeChips(chips: chips)
        self.currentTurnPlayer().hasBetThisRound = true
    }
    
    func check() { //put in 0
        print("\(self.currentTurnPlayer().name) checks")
        self.currentPlayerPutIn(chips: 0)
        self.nextAction()
    }
    
    func call() { //put in difference between how much player has bet already and current bet
        print("\(self.currentTurnPlayer().name) calls \(self.currentBet)")
        self.currentPlayerPutIn(chips: self.currentBet - self.currentTurnPlayer().currentBet)
        self.currentTurnPlayer().currentBet = self.currentBet
        self.nextAction()
    }
    
    func bet(chips:Int) { //put in bet and set that as new bet
        print("\(self.currentTurnPlayer().name) bets \(chips) chips")
        self.currentPlayerPutIn(chips: chips)
        self.currentTurnPlayer().currentBet = chips
        self.currentBet = chips
        self.nextAction()
    }
    
    func raise(chips:Int) { //put in difference between how much player has bet already and current bet
        print("\(self.currentTurnPlayer().name) raises to \(chips) chips")
        self.currentPlayerPutIn(chips: chips - self.currentTurnPlayer().currentBet)
        self.currentTurnPlayer().currentBet = chips
        self.currentBet = chips
        self.nextAction()
    }
    
    func fold() { //put in 0 and take out of playersStillInRound
        print("\(self.currentTurnPlayer().name) folds")
        self.currentPlayerPutIn(chips: 0)
        self.playersStillInRound.remove(at: self.playersStillInRound.index(of: self.currentTurnPlayer())!)
        self.nextAction()
    }
    
    init(){}
    init(players:[Player], gameController:GameController) {
        //attach view controller
        self.gameController = gameController

        //set up players
        self.players = players
        self.playersStillInRound = self.players

        //do startGame if auto proceed
        if autoProceed {
            startGame()
        }
        else {
            self.currentRound = -1
        }
    }
    
    /* Copying protocol -----------------------------------------------------------------------------------*/
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Game.init(players: self.players, currentTurnIndex: self.currentTurnIndex, playersStillInRound: self.playersStillInRound, bigBlindSize: self.bigBlindSize, smallBlindSize: self.smallBlindSize, bigBlindIndex: self.bigBlindIndex, smallBlindIndex: self.smallBlindIndex, currentBet: self.currentBet, totalPot: self.totalPot, currentRound: self.currentRound, winnerIndex: self.winnerIndex, gameController: self.gameController, autoProceed: self.autoProceed)
        return copy
    }
    init(players:[Player], currentTurnIndex:Int, playersStillInRound:[Player], bigBlindSize:Int, smallBlindSize:Int, bigBlindIndex:Int, smallBlindIndex:Int, currentBet:Int, totalPot:Int, currentRound:Int, winnerIndex:Int, gameController:GameController?, autoProceed:Bool) {
        
        //deep copy of array of players and playersStillInRound
        var playersCopy:[Player] = []
        for eachPlayer in players {

            playersCopy.append(eachPlayer.copy() as! Player)
        }
        var roundCopy:[Player] = []
        for eachPlayer in playersCopy {
//            print("player \(eachPlayer.name) with hasBet:\(eachPlayer.hasBetThisRound) and currentBet:\(eachPlayer.currentBet) was copied")
            if playersStillInRound.contains(eachPlayer) {
                roundCopy.append(eachPlayer)
            }
        }
        self.players = playersCopy
        self.playersStillInRound = roundCopy
//        self.players = players
//        self.playersStillInRound = playersStillInRound
        
        self.currentTurnIndex = currentTurnIndex
        self.bigBlindSize = bigBlindSize
        self.smallBlindSize = smallBlindSize
        self.bigBlindIndex = bigBlindIndex
        self.smallBlindIndex = smallBlindIndex
        self.currentBet = currentBet
        self.totalPot = totalPot
        self.currentRound = currentRound
        self.winnerIndex = winnerIndex
        self.gameController = gameController
        self.autoProceed = autoProceed
    }
    
    /* Helper methods --------------------------------------------------------------------------------------*/
    
    private func processBlinds() {
        //process blinds
        self.players[self.bigBlindIndex].removeChips(chips: self.bigBlindSize)
        self.players[self.bigBlindIndex].currentBet = self.bigBlindSize
        self.players[self.smallBlindIndex].removeChips(chips: self.smallBlindSize)
        self.players[self.smallBlindIndex].currentBet = self.smallBlindSize
        self.totalPot = self.smallBlindSize + self.bigBlindSize
        self.currentBet = self.bigBlindSize
    }
    
    private func nextIndex(_ index:Int) -> Int{
        var nextIndex = index + 1
        if nextIndex >= self.players.count {
            nextIndex = 0
        }
        return nextIndex
    }
    
    private func prevIndex(_ index:Int) -> Int{
        var prevIndex = index - 1
        if prevIndex == -1 {
            prevIndex = self.players.count - 1
        }
        return prevIndex
    }
    
    func moveBlindsForward() {
        self.bigBlindIndex = nextIndex(self.bigBlindIndex) //set big blind to next index
        self.smallBlindIndex = prevIndex(self.bigBlindIndex) //set small blind right behind big blind
    }
    
    func moveBlindsBackward() {
        self.bigBlindIndex = prevIndex(self.bigBlindIndex) //set big blind to prev index
        self.smallBlindIndex = prevIndex(self.bigBlindIndex) //set small blind right behind big blind
    }
    
    func formatNames (players:[Player]) -> String {
        var string = ""
        for eachPlayer in players {
            string += eachPlayer.name + ", "
        }
        return string
    }
}
