//
//  AddPlayerCell.swift
//  PokerChipz
//
//  Created by Eric Zhang on 12/26/16.
//  Copyright © 2016 Eric Zhang. All rights reserved.
//

import Foundation
import UIKit

class AddPlayerCell:UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }
    
}
