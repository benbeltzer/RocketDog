//
//  GameScene.swift
//  RocketDog
//
//  Created by Benjamin Beltzer on 8/24/16.
//  Copyright (c) 2016 Benjamin Beltzer. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    // Layers
    var background: SKNode!
    var midground: SKNode!
    var foreground: SKNode!
    var hud: SKNode!
    
    var player: SKNode!
    
    // For iPhone 6
    var scaleFactor: CGFloat!
    
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.blackColor()

        physicsWorld.contactDelegate = self
        
        // No gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        scaleFactor = self.size.width / 320.0
        
        // Setup Background
        background = createbackground()
        addChild(background)
        
        // Setup Foreground
        foreground = SKNode()
        foreground.zPosition = 1
        addChild(foreground)
        
        // HUD
        hud = SKNode()
        addChild(hud)
        
        // Load level
        let levelPlist = NSBundle.mainBundle().pathForResource("Level01", ofType: "plist")
        let levelData = NSDictionary(contentsOfFile: levelPlist!)!
        drawAsteroids(levelData)
        
        // Player
        player = createPlayer()
        foreground.addChild(player)
        
        // Tap to Start
        // TODO: Change this image to something else
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 200.0)
        tapToStartNode.zPosition = player.zPosition + 1
        hud.addChild(tapToStartNode)
    }
    
    func createbackground() -> SKNode {
        
        let background = SKNode()
        background.zPosition = 0
        let ySpacing = 64.0 * scaleFactor // image dimension in pixels
        
        for i in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: "space_background%02d", i + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(19-i))
            background.addChild(node)
        }
        
        return background
    }
    
    func createPlayer() -> GameObjectNode {
        
        let playerNode = GameObjectNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0) // TODO: Change magic number
        
        let sprite = SKSpriteNode(imageNamed: "blueRocket")
        playerNode.addChild(sprite)
        
        playerNode.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        playerNode.physicsBody?.dynamic = false
        playerNode.physicsBody?.allowsRotation = false // TODO: May want to change this later

        // Node interaction properties
        // TODO: May want to change damping later
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.linearDamping = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.friction = 0.0
        
        // Physics Body Setup
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Player
        playerNode.physicsBody?.collisionBitMask = 0 // Dont let physics engine handle player collisions
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid
        
        return playerNode
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        // If already started ignore touches
        // TODO: Change this when power ups incorporated
        if player.physicsBody!.dynamic {
            return
        }
        
        tapToStartNode.removeFromParent()
        
        player.physicsBody?.dynamic = true
        // TODO: Remove this impulse
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
    
    // For creating stationary asteroids
    // TODO: Create seperate method for creating asteroid at position with force (vector)
    func createAsteroidAtPosition(position: CGPoint, ofType type: AsteroidType) -> AsteroidNode {
        
        let node = AsteroidNode()
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.name = "ASTEROID_NODE"
        
        node.type = type
        var sprite: SKSpriteNode!
        if type == .Moving {
            sprite = SKSpriteNode(imageNamed: "asteroidWithTrail")
        } else {
            sprite = SKSpriteNode(imageNamed: "asteroid")
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        node.physicsBody?.dynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Asteroid
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func drawAsteroids(levelData: NSDictionary) {
        let asteroids = levelData["Asteroids"] as! NSDictionary
        let asteroidPatterns = asteroids["Patterns"] as! NSDictionary
        let asteroidPositions = asteroids["Positions"] as! [NSDictionary]
        
        for asteroidPosition in asteroidPositions {
            let patternX = asteroidPosition["x"]?.floatValue
            let patternY = asteroidPosition["y"]?.floatValue
            let pattern = asteroidPosition["pattern"] as! NSString
            
            let asteroidPattern = asteroidPatterns[pattern] as! [NSDictionary]
            for asteroidPoint in asteroidPattern {
                let x = asteroidPoint["x"]?.floatValue
                let y = asteroidPoint["y"]?.floatValue
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                
                // TODO: For now, all asteroids will be type normal
                let asteroidNode = createAsteroidAtPosition(CGPoint(x: positionX, y: positionY), ofType: .Normal)
                foreground.addChild(asteroidNode)
            }
        }
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBeginContact(contact: SKPhysicsContact) {
        var updateHUD = false
        
        let nonPlayerNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = nonPlayerNode as! GameObjectNode
        
        updateHUD = other.collisionWithPlayer(player)
        
        // Update the HUD if necessary
        if updateHUD {
            // TODO: Update HUD
        }
    }
    
}








