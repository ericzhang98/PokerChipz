//
//  Player.swift
//  PokerChipz
//
//  Created by Eric Zhang on 12/26/16.
//  Copyright © 2016 Eric Zhang. All rights reserved.
//

import Foundation

class Player: Equatable, NSCopying {
    var name:String;
    var chips = 100
    var currentBet:Int = 0
    var hasBetThisRound:Bool = false
    
    static func == (lhs:Player, rhs:Player) -> Bool{
        return lhs.name == rhs.name
    }
    
    func addChips(chips:Int) {
        self.chips += chips
    }
    func removeChips(chips:Int) {
        self.chips -= chips
    }
    
    init(name:String) {
        self.name = name
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return Player(name: self.name, chips: self.chips, currentBet: self.currentBet, hasBetThisRound: self.hasBetThisRound)
    }
    init(name:String, chips:Int, currentBet:Int, hasBetThisRound:Bool) {
        self.name = name
        self.chips = chips
        self.currentBet = currentBet
        self.hasBetThisRound = hasBetThisRound
    }
}
