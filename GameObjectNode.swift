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
}

class GameObjectNode: SKNode {

    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 100.0 {
            self.removeFromParent()
        }
    }
    
    func addExplosionToObject() {
        
        let gameScene = self.scene! as! GameScene
        
        let explosionSound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        gameScene.runAction(explosionSound)
        
        // Pulsate Background
        let background = gameScene.background
        background.runAction(SKAction.scaleTo(1.05, duration: 0.05), completion: {
            background.runAction(SKAction.scaleTo(1, duration: 0.05))
        })
        
        // Shake the scene
        let moveX1 = SKAction.moveBy(CGVectorMake(-7, 0), duration: 0.05)
        let moveX2 = SKAction.moveBy(CGVectorMake(10, 0), duration: 0.05)
        let moveX3 = SKAction.moveBy(CGVectorMake(-10, 0), duration: 0.05)
        let moveX4 = SKAction.moveBy(CGVectorMake(7, 0), duration: 0.05)
        
        let moveY1 = SKAction.moveBy(CGVectorMake(0, -7), duration: 0.05)
        let moveY2 = SKAction.moveBy(CGVectorMake(0, 10), duration: 0.05)
        let moveY3 = SKAction.moveBy(CGVectorMake(0, -10), duration: 0.05)
        let moveY4 = SKAction.moveBy(CGVectorMake(0, 7), duration: 0.05)
        
        let shakeX = SKAction.sequence([moveX1, moveX2, moveX3, moveX4])
        let shakeY = SKAction.sequence([moveY1, moveY2, moveY3, moveY4])
        
        for child in gameScene.children {
            child.runAction(shakeX)
            child.runAction(shakeY)
        }
        
        let fireEmitterPath = NSBundle.mainBundle().pathForResource("fire", ofType: "sks")
        let fireEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(fireEmitterPath!) as! SKEmitterNode
        fireEmitter.position = position
        fireEmitter.zPosition = 2
        gameScene.addChild(fireEmitter)
        
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
        gameScene.addChild(smokeEmitter)
        
        smokeEmitter.runAction(SKAction.sequence([
            SKAction.waitForDuration(0.1),
            SKAction.scaleBy(1.2, duration: 0.1),
            SKAction.runBlock({
                smokeEmitter.particleBirthRate = 0
            })
        ]))
    }
    
}

class AsteroidNode: GameObjectNode {
    
    // TODO: Explode ship and Asteroid
    override func collisionWithPlayer(player: SKNode) -> Bool {

        (player as! GameObjectNode).addExplosionToObject()
        self.addExplosionToObject()
        player.removeFromParent()
        self.removeFromParent()
        
        // HUD needs updated
        return true
    }
    
}
