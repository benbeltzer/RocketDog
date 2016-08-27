//
//  GameState.swift
//  RocketDog
//
//  Created by Benjamin Beltzer on 8/26/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import Foundation

class GameState {

    var score: Int
    var highScore: Int
    
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        
        return Singleton.instance
    }
    
    init() {
        score = 0
        highScore = 0
        
        // Load game state
        let defaults = NSUserDefaults.standardUserDefaults()
        highScore = defaults.integerForKey("highScore")
    }
    
    func saveState() {
        highScore = max(score, highScore)
        
        // Store in user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(highScore, forKey: "highScore")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}