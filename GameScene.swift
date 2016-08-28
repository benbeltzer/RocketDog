//
//  GameScene.swift
//  RocketDog
//
//  Created by Benjamin Beltzer on 8/24/16.
//  Copyright (c) 2016 Benjamin Beltzer. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    // Layers
    var background: SKNode!
    var midground: SKNode!
    var foreground: SKNode!
    var hud: SKNode!
    
    var player: SKNode!
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0 // value from accelerometer
    var rotation: CGFloat = 0.0
    
    var maxLevelY: CGFloat = 2000.0
    var backgroundHeight: CGFloat!
    var backgroundImageHeight: CGFloat!
    
    var levelData: NSDictionary!
    
    // music
    var backgroundMusic: SKAudioNode!
    
    // For iPhone 6
    var scaleFactor: CGFloat!
    
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    var scoreLabel: SKLabelNode!
    
    var gameOver = false
    
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
        
        GameState.sharedInstance.score = 0
        gameOver = false
        
        // Setup Background
        background = createBackground(0)
        background.zPosition = 0
        addChild(background)
        backgroundHeight = 64.0 * scaleFactor * 20
        backgroundImageHeight = 64.0 * scaleFactor * 20
        
        // Setup Midground
        midground = createMidground()
        midground.zPosition = 1
        addChild(midground)
        
        // Setup Foreground
        foreground = SKNode()
        foreground.name = "FOREGROUND"
        foreground.zPosition = 2
        addChild(foreground)
        
        // HUD
        hud = SKNode()
        hud.name = "HUD"
        hud.zPosition = 3
        addChild(hud)
        
        // Load level
        let levelPlist = NSBundle.mainBundle().pathForResource("Level_Singles", ofType: "plist")
        levelData = NSDictionary(contentsOfFile: levelPlist!)!
        drawAsteroids(startingAt: 300)
        
        // Player
        player = createPlayer()
        player.name = "PLAYER"
        foreground.addChild(player)
        
        // Tap to Start
        // TODO: Change this image to something else, like Blast Off!
        tapToStartNode.name = "TAPTOSTART"
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 200.0)
        tapToStartNode.zPosition = player.zPosition + 1
        hud.addChild(tapToStartNode)
        
        createHUD()
        
        initMotionManager()
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if gameOver {
            return
        }
        
        // Update Score
        GameState.sharedInstance.score = Int(player.position.y) - 79
        scoreLabel.text = "\(GameState.sharedInstance.score)"
        
        // Remove past objects
        foreground.enumerateChildNodesWithName("ASTEROID_NODE", usingBlock: {
            (node, stop) in
            let asteroid = node as! AsteroidNode
            asteroid.checkNodeRemoval(self.player.position.y)
        })
        
        // Paralax Effect
        if (player.physicsBody!.dynamic) {
            background.position.y -= 0.2
            midground.position.y -=  0.5
            foreground.position.y -= 2
            player.position.y += 2
        }
        
        // Check if we need to add more asteroids
        if player.position.y > maxLevelY - 1000 {
            maxLevelY += 1000
            drawAsteroids(startingAt: maxLevelY - 1000)
        }
        
        // Check if we should add a flying asteroid
        let r = random()
        if (r % 100) == 0 {
            print("Drawing Asteroid!!")
             drawMovingAsteroid(r)
        }
        
        // Check if we need to reload background
        if (player.position.y > backgroundHeight - self.size.height - 50) {
            backgroundHeight = backgroundHeight + backgroundImageHeight
            let newBackground = createBackground(Int(backgroundHeight / backgroundImageHeight) - 1)
            newBackground.zPosition = 0
            background.addChild(newBackground)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // If already started ignore touches
        // TODO: Change this when power ups incorporated
        if player.physicsBody!.dynamic {
            return
        }
        
        tapToStartNode.removeFromParent()
        
        if let musicURL = NSBundle.mainBundle().URLForResource("rocket_thrust", withExtension: "wav") {
            backgroundMusic = SKAudioNode(URL: musicURL)
            addChild(backgroundMusic)
        }
        
        player.physicsBody?.dynamic = true
    }
    
    override func didSimulatePhysics() {
        player.physicsBody?.velocity.dx = xAcceleration * 400.0
        player.zRotation = self.rotation
        
        // Check x bounds for wrap around
        if player.position.x < -20.0 {
            player.position.x = self.size.width + 20.0
        } else if (player.position.x > self.size.width + 20.0) {
            player.position.x = -20.0
        }
    }
    
    // MARK: Node Creating
    
    func createBackground(offset: Int) -> SKNode {
        
        let background = SKNode()
        let ySpacing = 64.0 * scaleFactor // image dimension in pixels

        // load 20 background nodes
        for i in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: "space_background%02d", i + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            
            // offset used to calculate y when ship climbs beyond background already loaded
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * (CGFloat(20 * offset + 19 - i)))
            background.addChild(node)
        }
        background.name = "BACKGROUND"
        return background
    }
    
    func createMidground() -> SKNode {
        
        let midgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat!
        
        // Draw Planets
        let planets = ["moon", "mars", "jupiter", "saturn", "uranus", "neptune", "pluto"]
        
        for index in 0...(planets.count - 1) {
            let r = arc4random() % 2
            if r > 0 {
                // Right side
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = self.size.width + 25.0
            } else {
                // Left side
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition = -25.0
            }
         
            let planetNode = SKSpriteNode(imageNamed: planets[index])
            planetNode.anchorPoint = anchor
            planetNode.position = CGPoint(x: xPosition, y: 1000.0 * CGFloat(index + 1))
            midgroundNode.addChild(planetNode)
        }
        midgroundNode.name = "MIDGROUND"
        return midgroundNode
    }
    
    func createPlayer() -> GameObjectNode {
        
        let playerNode = GameObjectNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "blueRocket")
        playerNode.addChild(sprite)
        
        playerNode.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        playerNode.physicsBody?.dynamic = false
        playerNode.physicsBody?.allowsRotation = false

        // Node interaction properties
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
    
    func createHUD() {

        // TODO: Change this dumb font
        scoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        
        scoreLabel.text = "0"
        hud.addChild(scoreLabel)
    }
    
    // For creating stationary asteroids
    // TODO: Create seperate method for creating asteroid at position with force (vector)
    func drawAsteroidAtPosition(position: CGPoint, ofType type: AsteroidType) -> AsteroidNode {
        
        let node = AsteroidNode()
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.type = type
        
        var sprite: SKSpriteNode!
        if type == .Moving {
            sprite = SKSpriteNode(imageNamed: "asteroidWithTrail")
            node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            node.physicsBody?.dynamic = true
            node.name = "MOVING_ASTEROID"
        } else {
            sprite = SKSpriteNode(imageNamed: "asteroid")
            node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
            node.physicsBody?.dynamic = false
            node.name = "NORMAL_ASTEROID"
        }
        node.addChild(sprite)
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitMask.Asteroid
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    // Draw pattern at location and return max y height
    func drawPattern(pattern: [NSDictionary], patternX: CGFloat, patternY: CGFloat) -> CGFloat {

        var maxY: CGFloat = 0
        
        for asteroidPoint in pattern {
            let x = asteroidPoint["x"]?.floatValue
            let y = asteroidPoint["y"]?.floatValue
            let positionX = CGFloat(x!) + patternX
            let positionY = CGFloat(y!) + patternY
            
            let asteroidNode = drawAsteroidAtPosition(CGPoint(x: positionX, y: positionY), ofType: .Normal)
            foreground.addChild(asteroidNode)
            maxY = (positionY > maxY) ? positionY : maxY
        }
        
        return maxY
    }
    
    func drawAsteroids(startingAt y: CGFloat) {
        let patterns = (levelData["Asteroids"] as! NSDictionary)["Patterns"] as! NSDictionary
        let numPatterns = patterns.count
        var pattern: [NSDictionary]!
        var currentY = y
        var nextY: CGFloat!
        var xPosition: CGFloat!
        var r = 0
        
        while (currentY < maxLevelY) {
            // Get random pattern
            r = random()
            pattern = patterns.allValues[r % numPatterns] as! [NSDictionary]
            
            // Get rancdom xPosition between 30 and self.size.width - 30
            xPosition = (CGFloat(r) % (self.size.width - 60)) + 30
            
            nextY = drawPattern(pattern, patternX: xPosition, patternY: currentY)
            currentY = nextY + 100
        }
    }
    
    func drawMovingAsteroid(randomValue: Int) {
        let xPosition = CGFloat(randomValue) % self.size.width
        let asteroid = drawAsteroidAtPosition(CGPoint(x: xPosition, y: player.position.y + self.size.height), ofType: .Moving)
        foreground.addChild(asteroid)

        // Get random dx between -5 and 5, random dy between -10 and 5        
        let dx = (random() % 10) - 5
        let dy = dx - 20

        asteroid.zRotation = atan2(CGFloat(dy), CGFloat(dx)) + CGFloat(M_PI_2)
        asteroid.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }
    
    // MARK: Motion Manager Setup
    
    func initMotionManager() {
        
        // Get xAcceleration
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
            (accelerometerData: CMAccelerometerData?, error: NSError?) in
            let acceleration = accelerometerData!.acceleration
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        })
        
        // Get rotation
        motionManager.deviceMotionUpdateInterval = 0.02
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
            (motion: CMDeviceMotion?, error: NSError?) in
            if let gravity = motion?.gravity {
                self.rotation = CGFloat(atan2(gravity.x, gravity.y) - M_PI)
            }
        })
    }
    
    // MARK: End Game
    
    func endGame() {
        
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        
        gameOver = true
        GameState.sharedInstance.saveState()
        
        let reveal = SKTransition.fadeWithDuration(0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
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
            scoreLabel.text = "\(GameState.sharedInstance.score)"
        }
    }
    
}