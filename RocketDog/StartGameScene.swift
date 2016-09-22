//
//  StartGameScene.swift
//  RocketDog
//
//  Created by Benjamin on 9/21/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import UIKit
import SpriteKit

/*
 Start Game Scene:
 - Title label
 - Start Game Button
 - Space Background
    - Rocket Ship in Center Tilted
    - Asteroid flying down
    - Rockets zooming by
 
 */

class StartGameScene: SKScene {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Draw Background
        let background = createBackground()
        background.zPosition = 0
        addChild(background)
        
        // Add Flying Asteroids
        let gameScene = GameScene(size: size)
        drawAsteroids(gameScene)
        
        // Title Label
        let titleLabel = SKLabelNode(fontNamed: "Futura-Medium")
        titleLabel.fontSize = 40
        titleLabel.fontColor = SKColor.whiteColor()
        titleLabel.position = CGPoint(x: size.width / 2, y: 350)
        titleLabel.horizontalAlignmentMode = .Center
        titleLabel.text = "BLAST OFF!"
        titleLabel.zPosition = 1
        addChild(titleLabel)
        
        // Tap To Start Label
        let tapToStartLabel = SKLabelNode(fontNamed: "Futura-Medium")
        tapToStartLabel.fontSize = 20
        tapToStartLabel.fontColor = SKColor.whiteColor()
        tapToStartLabel.position = CGPoint(x: size.width / 2, y: 100)
        tapToStartLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        tapToStartLabel.text = "TAP TO START"
        tapToStartLabel.zPosition = 1
        addChild(tapToStartLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start Game
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
    
    func drawAsteroids(gameScene: GameScene) {
        
        let r = Int(arc4random())
        let xPosition = CGFloat(r) % size.width
        let asteroid = gameScene.createAsteroidAtPosition(CGPoint(x: xPosition, y: size.height + 50), ofType: .Moving)
        addChild(asteroid)
        moveAseroid(asteroid)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 2), dispatch_get_main_queue(), {
            // If the current scene is still present, keep drawing
            if self.view != nil {
                self.drawAsteroids(gameScene)
            }
        })
    }
    
    func moveAseroid(asteroid: AsteroidNode) {
        // Get random dx between -5 and 5, random dy between -15 and -5
        let r = Int(arc4random())
        let dx = (r % 10) - 5
        let dy = dx - 10
        
        asteroid.zRotation = atan2(CGFloat(dy), CGFloat(dx)) + CGFloat(M_PI_2)
        asteroid.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
        
        let fireEmitterPath = NSBundle.mainBundle().pathForResource("AsteroidFire", ofType: "sks")
        let fireEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(fireEmitterPath!) as! SKEmitterNode
        asteroid.addChild(fireEmitter)
        fireEmitter.position = CGPoint(x: fireEmitter.position.x, y: fireEmitter.position.y - 10)
        fireEmitter.zPosition = asteroid.zPosition + 1
    }
}
