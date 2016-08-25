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
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    
    // For iPhone 6
    var scaleFactor: CGFloat!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        
        scaleFactor = self.size.width / 320.0
        
        // Set up background
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
    }
    
    func createBackgroundNode() -> SKNode {
        
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor // image dimension in pixels
        
        for i in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: "space_background%02d", i + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(19-i))
            backgroundNode.addChild(node)
        }
        
        return backgroundNode
    }
}