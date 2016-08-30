//
//  EndGameScene.swift
//  RocketDog
//
//  Created by Benjamin Beltzer on 8/26/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import UIKit
import SpriteKit

class EndGameScene: SKScene {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // TODO: Completely change end scene. This is shit
    override init(size: CGSize) {
        super.init(size: size)
        
        // Score
        let scoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: 300)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        scoreLabel.text = String(format: "%d", GameState.sharedInstance.score)
        addChild(scoreLabel)
        
        // High Score
        let highScoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        highScoreLabel.fontSize = 30
        highScoreLabel.fontColor = SKColor.cyanColor()
        highScoreLabel.position = CGPoint(x: self.size.width / 2, y: 150)
        highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        highScoreLabel.text = String(format: "High Score: %d", GameState.sharedInstance.highScore)
        addChild(highScoreLabel)
        
        // Try again
        let tryAgainLabel = SKLabelNode(fontNamed: "Futura-Medium")
        tryAgainLabel.fontSize = 30
        tryAgainLabel.fontColor = SKColor.whiteColor()
        tryAgainLabel.position = CGPoint(x: self.size.width / 2, y: 50)
        tryAgainLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        tryAgainLabel.text = "Tap To Try Again"
        addChild(tryAgainLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Restart Game
        let reveal = SKTransition.fadeWithDuration(0.5)
        let gameScene = GameScene(size: self.size)
        self.view!.presentScene(gameScene, transition: reveal)
    }
    
}
