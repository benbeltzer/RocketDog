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

enum AsteroidType: Int {
    case Normal = 0
    case Moving
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
        
        let gameScene = self.scene! as! GameScene
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
