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
        
        // Add Flying Ships
        drawShips()
        
        // Title Label
        let topTitleLabel = SKLabelNode(fontNamed: "Futura-Medium")
        topTitleLabel.fontSize = 80
        topTitleLabel.fontColor = SKColor.whiteColor()
        topTitleLabel.position = CGPoint(x: size.width / 2, y: size.height/2 + 37)
        topTitleLabel.horizontalAlignmentMode = .Center
        topTitleLabel.text = "BLAST"
        topTitleLabel.zPosition = 1
        topTitleLabel.physicsBody?.dynamic = true
        addChild(topTitleLabel)
        
        let bottomTitleLabel = SKLabelNode(fontNamed: "Futura-Medium")
        bottomTitleLabel.fontSize = 80
        bottomTitleLabel.fontColor = SKColor.whiteColor()
        bottomTitleLabel.position = CGPoint(x: size.width / 2, y: size.height/2 - 37)
        bottomTitleLabel.horizontalAlignmentMode = .Center
        bottomTitleLabel.text = "OFF!"
        bottomTitleLabel.zPosition = 1
        bottomTitleLabel.physicsBody?.dynamic = true
        addChild(bottomTitleLabel)
        
        bounceTitle(topTitleLabel, bottomLabel: bottomTitleLabel, moveSequence: nil)
        
        // Tap To Start Label
        let tapToStartLabel = SKLabelNode(fontNamed: "Futura-Medium")
        tapToStartLabel.fontSize = 30
        tapToStartLabel.fontColor = SKColor.whiteColor()
        tapToStartLabel.position = CGPoint(x: size.width / 2, y: 75)
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
    
    func bounceTitle(topLabel: SKLabelNode, bottomLabel: SKLabelNode, moveSequence: SKAction?) {
        
        var move: SKAction!
        if moveSequence == nil {
            let moveDown = SKAction.moveBy(CGVectorMake(0, -20), duration: 0.35)
            let moveUp = SKAction.moveBy(CGVectorMake(0, 20), duration: 0.35)
            move = SKAction.sequence([moveDown, moveUp])
        } else {
            move = moveSequence!
        }
        
        topLabel.runAction(move)
        bottomLabel.runAction(move)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.7)), dispatch_get_main_queue(), {
            // If the current scene is still present, keep drawing
            if self.view != nil {
                self.bounceTitle(topLabel, bottomLabel: bottomLabel, moveSequence: move)
            }
        })
        
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
    
    func drawShips() {
        let r = Int(arc4random())
        let yPosition = CGFloat(r) % (self.size.height - 200)
        let xPosition = CGFloat(-50)

        let type = ShipType(rawValue: r % 3)!
        let ship = ShipNode(type: type)
        ship.position = CGPoint(x: xPosition, y: yPosition)
        ship.physicsBody?.dynamic = true
        ship.zPosition = 5
        addChild(ship)
        moveShip(ship)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            // If the current scene is still present, keep drawing
            if self.view != nil {
                self.drawShips()
            }
        })
    }
    
    func moveShip(ship: ShipNode) {
        let dx = 50
        let dy = 50
        
        ship.zRotation = atan2(CGFloat(dy), CGFloat(dx)) - CGFloat(M_PI_2)
        ship.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
        ship.physicsBody?.affectedByGravity = false
        ship.addThrust()
    }
}
