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
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Background
        let background = createBackground()
        background.zPosition = 0
        addChild(background)
        
        // Game Over
        let gameOverLabel = SKLabelNode(fontNamed: "Futura-Medium")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = SKColor.whiteColor()
        gameOverLabel.position = CGPoint(x: size.width / 2, y: 350)
        gameOverLabel.horizontalAlignmentMode = .Center
        gameOverLabel.text = "GAME OVER!"
        gameOverLabel.zPosition = 1
        addChild(gameOverLabel)
        
        // Score
        let scoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: size.width / 2, y: 250)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        scoreLabel.text = "YOUR SCORE: \(GameState.sharedInstance.score)"
        scoreLabel.zPosition = 1
        addChild(scoreLabel)
        
        // High Score
        let highScoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = SKColor.whiteColor()
        highScoreLabel.position = CGPoint(x: size.width / 2, y: 200)
        highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        highScoreLabel.text = "HIGH SCORE: \(GameState.sharedInstance.highScore)"
        highScoreLabel.zPosition = 1
        addChild(highScoreLabel)
        
        // Name (later will use for scoreboard)
        let nameLabel = SKLabelNode(fontNamed: "Futura-Medium")
        nameLabel.fontSize = 20
        nameLabel.fontColor = SKColor.whiteColor()
        nameLabel.position = CGPoint(x: size.width / 2, y: 150)
        nameLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        nameLabel.text = "YOUR NAME: brb1494"
        nameLabel.zPosition = 1
        addChild(nameLabel)
        
        // Try again
        let tryAgainLabel = SKLabelNode(fontNamed: "Futura-Medium")
        tryAgainLabel.fontSize = 20
        tryAgainLabel.fontColor = SKColor.whiteColor()
        tryAgainLabel.position = CGPoint(x: size.width / 2, y: 50)
        tryAgainLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        tryAgainLabel.text = "TAP TO TRY AGAIN"
        tryAgainLabel.zPosition = 1
        addChild(tryAgainLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Restart Game
        let reveal = SKTransition.fadeWithDuration(0.5)
        let gameScene = GameScene(size: self.size)
        self.view!.presentScene(gameScene, transition: reveal)
    }
    
    func createBackground() -> SKNode {
        
        let background = SKNode()
        let scaleFactor = self.size.width / 320.0
        let ySpacing = 64.0 * scaleFactor // image dimension in pixels
        
        // load bottom 10 background nodes
        for i in 10...19 {
            let node = SKSpriteNode(imageNamed: String(format: "space_background%02d", i + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            
            // offset used to calculate y when ship climbs beyond background already loaded
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * (CGFloat(19 - i)))
            background.addChild(node)
        }
        return background
    }
}
