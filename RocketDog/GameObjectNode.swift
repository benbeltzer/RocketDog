//
//  GameObjectNode.swift
//  RocketDog
//
//  Created by Benjamin Beltzer on 8/25/16.
//  Copyright © 2016 Benjamin Beltzer. All rights reserved.
//

import UIKit
import SpriteKit

struct CollisionCategoryBitMask {
    static let Player: UInt32 = 0x00
    static let Asteroid: UInt32 = 0x01
    static let PowerUp: UInt32 = 0x02
    static let Laser: UInt32 = 0x03
}

enum AsteroidType: Int {
    case Normal = 0
    case Moving
}

enum ShipType: Int {
    case Normal = 0
    case Laser
}

class GameObjectNode: SKNode {

    let explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: true)
    
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 100.0 {
            self.removeFromParent()
        }
    }
    
    func addExplosionToObject() {
        
        guard let gameScene = self.scene as? GameScene else {
            return
        }
        
        gameScene.runAction(explosionSound)
        
        // Pulsate Background
        let background = gameScene.background
        background.runAction(SKAction.scaleTo(1.05, duration: 0.05), completion: {
            background.runAction(SKAction.scaleTo(1, duration: 0.05))
        })
        
        // Shake the scene
        let move1 = SKAction.moveBy(CGVectorMake(-7, -7), duration: 0.1)
        let move2 = SKAction.moveBy(CGVectorMake(0, 10), duration: 0.1)
        let move3 = SKAction.moveBy(CGVectorMake(7, -10), duration: 0.1)
        let move4 = SKAction.moveBy(CGVectorMake(0, 7), duration: 0.1)
        let move5 = SKAction.moveBy(CGVectorMake(0, 10), duration: 0.15)
        let move6 = SKAction.moveBy(CGVectorMake(7, -10), duration: 0.2)
        let move7 = SKAction.moveBy(CGVectorMake(0, 7), duration: 0.25)
        
        let shake = SKAction.sequence([move1, move2, move3, move4, move1, move5, move6, move7])
        
        for child in gameScene.children {
            shakeNode(child, shake: shake)
        }
        
        let fireEmitterPath = NSBundle.mainBundle().pathForResource("fire", ofType: "sks")
        let fireEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(fireEmitterPath!) as! SKEmitterNode
        fireEmitter.position = position
        fireEmitter.zPosition = 2
        self.parent!.addChild(fireEmitter)
        
        fireEmitter.runAction(SKAction.sequence([
            SKAction.waitForDuration(0.3),
            SKAction.runBlock({
                fireEmitter.particleBirthRate = 0
            })
        ]))
        
        let smokeEmitterPath = NSBundle.mainBundle().pathForResource("smoke", ofType: "sks")
        let smokeEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(smokeEmitterPath!) as! SKEmitterNode
        smokeEmitter.position = position
        smokeEmitter.zPosition = 2
        self.parent!.addChild(smokeEmitter)
        
        smokeEmitter.runAction(SKAction.sequence([
            SKAction.waitForDuration(0.1),
            SKAction.scaleBy(1.2, duration: 0.1),
            SKAction.runBlock({
                smokeEmitter.particleBirthRate = 0
                if let _ = self as? ShipNode {
                    gameScene.endGame()
                }
            })
        ]))
    }
    
    func shakeNode(node: SKNode, shake: SKAction) {
        if (node.children.count == 0) {
            return
        } else {
            for child in node.children {
                child.runAction(shake)
            }
        }
    }
    
}

class AsteroidNode: GameObjectNode {
    
    var type: AsteroidType!
    
    init(type: AsteroidType) {
        super.init()
        
        self.type = type
        
        let sprite = SKSpriteNode(imageNamed: "asteroid")
        sprite.name = "ASTEROID"
        self.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        self.addChild(sprite)

        if type == .Moving {
            self.physicsBody?.dynamic = true
            self.name = "MOVING_ASTEROID"
        } else {
            self.physicsBody?.dynamic = false
            self.name = "NORMAL_ASTEROID"
        }
        
        self.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Asteroid
        self.physicsBody?.collisionBitMask = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func collisionWithPlayer(player: SKNode) -> Bool {

        // TODO: Fix background so that no black is visible when screen shakes
        (player as! GameObjectNode).addExplosionToObject()
        self.addExplosionToObject()
        
        player.removeFromParent()
        self.removeFromParent()

        // No need to update HUD
        return false
    }
    
}

class ShipNode: GameObjectNode {
    
    var type: ShipType!
    
    init(type: ShipType) {
        super.init()
        
        self.type = type
        var sprite: SKSpriteNode!
        
        switch type {
        case .Normal:
            sprite = SKSpriteNode(imageNamed: "blueRocket")
            self.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            self.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Player
            self.physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid | CollisionCategoryBitMask.PowerUp
        case .Laser:
            sprite = SKSpriteNode(imageNamed: "redRocket")
            self.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            self.physicsBody?.categoryBitMask = CollisionCategoryBitMask.PowerUp
            self.physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid
        }
        addChild(sprite)
        
        self.physicsBody?.dynamic = false
        self.physicsBody?.allowsRotation = false
        
        // Node interaction properties
        self.physicsBody?.restitution = 1.0
        self.physicsBody?.linearDamping = 0.0
        self.physicsBody?.angularDamping = 0.0
        self.physicsBody?.friction = 0.0
        
        // Physics Body Setup
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.collisionBitMask = 0 // Dont let physics engine handle player collisions
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        if (type != .Normal) {
            // Swap player's ship for special one
            self.removeFromParent()
            
            player.removeAllChildren()
            let sprite = SKSpriteNode(imageNamed: "redRocket")
            player.addChild(sprite)
            (player as! ShipNode).type = .Laser

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
                (player as! ShipNode).flicker(0.5)
            })
        }
        
        return false
    }
    
    // Ship flickers between special and normal as time runs out
    func flicker(interval: CGFloat) {
        if (interval <= 0.05) {
            return
        } else {
            let waitTime = Int64(CGFloat(NSEC_PER_SEC) * interval)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, waitTime), dispatch_get_main_queue(), {
                self.removeAllChildren()
                let sprite: SKSpriteNode!
                if self.type == .Normal && (interval * 0.9) > 0.05 {
                    sprite = SKSpriteNode(imageNamed: "redRocket")
                    self.type = .Laser
                } else {
                    sprite = SKSpriteNode(imageNamed: "blueRocket")
                    self.type = .Normal
                }
                self.addChild(sprite)
                self.flicker(interval * 0.9)
            })
        }
        
    }
    
}

class LaserNode: GameObjectNode {
   
    override init() {
        super.init()
        
        self.name = "LASER"
        
        let sprite = SKSpriteNode(imageNamed: "laser")
        self.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        self.addChild(sprite)
        
        self.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Laser
        self.physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func collisionWithAsteroid(asteroid: AsteroidNode) -> Bool {
        asteroid.addExplosionToObject()
        asteroid.removeFromParent()
        self.removeFromParent()
        return false
    }
    
    override func checkNodeRemoval(playerY: CGFloat) {
        if let gameScene = self.scene as? GameScene {
            if (self.position.y > playerY + gameScene.size.height - 50) {
                self.removeFromParent()
            }
        }
    }
}