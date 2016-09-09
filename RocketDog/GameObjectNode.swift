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
    static let BlackHole: UInt32 = 0x04
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
        let playerStartingY: CGFloat = 160.0
        if playerY > self.position.y + playerStartingY {
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
        background.runAction(SKAction.scaleTo(1.02, duration: 0.05), completion: {
            background.runAction(SKAction.scaleTo(1, duration: 0.05))
        })
        
        // Shake the scene
        let move1 = SKAction.moveBy(CGVectorMake(-3, -3), duration: 0.1)
        let move2 = SKAction.moveBy(CGVectorMake(0, 5), duration: 0.1)
        let move3 = SKAction.moveBy(CGVectorMake(3, -5), duration: 0.1)
        let move4 = SKAction.moveBy(CGVectorMake(0, 3), duration: 0.1)
        let move5 = SKAction.moveBy(CGVectorMake(0, 5), duration: 0.15)
        let move6 = SKAction.moveBy(CGVectorMake(3, -5), duration: 0.2)
        let move7 = SKAction.moveBy(CGVectorMake(0, 3), duration: 0.25)
        
        let shake = SKAction.sequence([move1, move2, move3, move4, move1, move5, move6, move7])
        
        for child in gameScene.children {
            if (child.name != "BACKGROUND" && child.name != "MIDGROUND") {
                shakeNode(child, shake: shake)
            }
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
    
    func drawPlusScoreLabel(score: Int, atPosition position: CGPoint) {
        let label = SKLabelNode(fontNamed: "Futura-Medium")
        label.fontSize = 30
        label.fontColor = SKColor.whiteColor()
        label.text = "+\(score)"
        label.position = position
        label.zPosition = 3
        self.parent!.addChild(label)
        let fade = SKAction.fadeAlphaTo(0, duration: 0.5)
        label.runAction(fade)
    }
    
}

class AsteroidNode: GameObjectNode {
    
    var type: AsteroidType!
    
    init(type: AsteroidType) {
        super.init()
        
        self.type = type
        
        let sprite = SKSpriteNode(imageNamed: "asteroid")
        sprite.name = "ASTEROID"
        physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        addChild(sprite)

        if type == .Moving {
            physicsBody?.dynamic = true
            name = "MOVING_ASTEROID"
        } else {
            physicsBody?.dynamic = false
            name = "NORMAL_ASTEROID"
        }
        
        physicsBody?.categoryBitMask = CollisionCategoryBitMask.Asteroid
        physicsBody?.collisionBitMask = 0
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
    var extraPowerUpTime = 0
    var height: CGFloat!
    var hasSeenLaser = false // determine if we should show instructions
    var simulatePhysics = true
    
    init(type: ShipType) {
        super.init()
        
        self.type = type
        
        var sprite: SKSpriteNode!
        
        switch type {
        case .Normal:
            sprite = SKSpriteNode(imageNamed: "blueShip")
            physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            physicsBody?.categoryBitMask = CollisionCategoryBitMask.Player
            physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid | CollisionCategoryBitMask.PowerUp | CollisionCategoryBitMask.BlackHole
        case .Laser:
            sprite = SKSpriteNode(imageNamed: "redShip")
            physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            physicsBody?.categoryBitMask = CollisionCategoryBitMask.PowerUp
            physicsBody?.contactTestBitMask = CollisionCategoryBitMask.Asteroid | CollisionCategoryBitMask.BlackHole
        }
        addChild(sprite)
        height = sprite.size.height
        
        physicsBody?.dynamic = false
        physicsBody?.allowsRotation = false
        
        // Node interaction properties
        physicsBody?.restitution = 1.0
        physicsBody?.linearDamping = 0.0
        physicsBody?.angularDamping = 0.0
        physicsBody?.friction = 0.0
        
        // Physics Body Setup
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.collisionBitMask = 0 // Dont let physics engine handle player collisions
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        // Power Up ship and player collided

        player.removeAllChildren()
        
        let sprite = SKSpriteNode(imageNamed: "redShip")
        player.addChild(sprite)
        (player as! ShipNode).type = .Laser
        (player as! ShipNode).extraPowerUpTime += 1
        
        if (!(player as! ShipNode).hasSeenLaser) {
            let point = CGPoint(x: (scene!.size.width / 2), y: 40)
            let label = makeInstructionLabel("TAP TO SHOOT!", atPosition: point)
            (scene as! GameScene).addChild(label)
            (player as! ShipNode).hasSeenLaser = true
        }
        self.removeFromParent()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
            (player as! ShipNode).extraPowerUpTime -= 1
            if (player as! ShipNode).extraPowerUpTime == 0 {
                (player as! ShipNode).flicker(0.5)
            }
        })
        
        return false
    }
    
    // Ship flickers between special and normal as time runs out
    func flicker(interval: CGFloat) {
        if (interval <= 0.05) {
            return
        } else if extraPowerUpTime > 0 {
            removeAllChildren()
            let sprite = SKSpriteNode(imageNamed: "redShip")
            addChild(sprite)
            type = .Laser
            return
        } else {
            let waitTime = Int64(CGFloat(NSEC_PER_SEC) * interval)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, waitTime), dispatch_get_main_queue(), {
                self.removeAllChildren()
                let sprite: SKSpriteNode!
                if self.type == .Normal && (interval * 0.9) > 0.05 {
                    sprite = SKSpriteNode(imageNamed: "redShip")
                    self.type = .Laser
                } else {
                    sprite = SKSpriteNode(imageNamed: "blueShip")
                    self.type = .Normal
                }
                self.addChild(sprite)
                self.flicker(interval * 0.9)
            })
        }
    }
    
    func addThrust() {
        let thrustEmitterPath = NSBundle.mainBundle().pathForResource("RocketThrust", ofType: "sks")
        let thrustEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(thrustEmitterPath!) as! SKEmitterNode
        thrustEmitter.position.y -= (height / 2)
        thrustEmitter.zPosition = 2
        addChild(thrustEmitter)
    }
    
    func makeInstructionLabel(text: String, atPosition point: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Futura-Medium")
        label.fontSize = 30
        label.fontColor = SKColor.whiteColor()
        label.text = text
        label.position = point
        label.zPosition = 3
        let fade = SKAction.fadeAlphaTo(0, duration: 5)
        label.runAction(fade)
        return label
    }
    
}

class LaserNode: GameObjectNode {
   
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        name = "LASER"
        
        let sprite = SKSpriteNode(imageNamed: "laser")
        physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        addChild(sprite)
        
        physicsBody?.categoryBitMask = CollisionCategoryBitMask.Laser
        physicsBody?.contactTestBitMask = (CollisionCategoryBitMask.Asteroid | CollisionCategoryBitMask.BlackHole)
        physicsBody?.collisionBitMask = 0
        physicsBody?.usesPreciseCollisionDetection = true
    }
    
    func collisionWithAsteroid(asteroid: AsteroidNode) -> Bool {
        asteroid.addExplosionToObject()
        let points = (asteroid.type == .Normal) ? 50 : 100
        drawPlusScoreLabel(points, atPosition: asteroid.position)
        asteroid.removeFromParent()

        if let gameScene = scene as? GameScene {
            gameScene.extraPoints += points
        }

        removeFromParent()
        
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

class BlackHoleNode: GameObjectNode {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        name = "BLACKHOLE"
        
        let sprite = SKSpriteNode(imageNamed: "blackHole")
        physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        addChild(sprite)
        
        physicsBody?.dynamic = false
        physicsBody?.categoryBitMask = CollisionCategoryBitMask.BlackHole
        physicsBody?.collisionBitMask = 0
    }
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        (player as! ShipNode).simulatePhysics = false // do not use accelerometer to set ship rotation

        // Spin and shrink ship as it enters black hole
        let fallSound = SKAction.playSoundFileNamed("fall.wav", waitForCompletion: false)
        runAction(fallSound)

        player.runAction(SKAction.moveTo(position, duration: 1))
        player.runAction(SKAction.rotateByAngle(CGFloat(M_PI * 2), duration: 1))
        player.runAction(SKAction.scaleTo(0.1, duration: 1), completion: {
            player.removeFromParent()
            guard let gameScene = self.scene as? GameScene else {
                return
            }
            gameScene.endGame()
        })
        
        return false
    }
    
    func collisionWithLaser(laser: LaserNode) -> Bool {
        
        laser.runAction(SKAction.moveTo(position, duration: 1))
        laser.runAction(SKAction.rotateByAngle(CGFloat(M_PI * 2), duration: 1))
        laser.runAction(SKAction.scaleTo(0.1, duration: 1), completion: {
            laser.removeFromParent()
        })
        
        return false
    }
    
}