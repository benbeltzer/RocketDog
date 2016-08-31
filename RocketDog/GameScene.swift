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
    
    var player: ShipNode!
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0 // value from accelerometer
    var rotation: CGFloat = 0.0
    
    var maxLevelY: CGFloat = 2000.0
    var backgroundHeight: CGFloat!
    var backgroundImageHeight: CGFloat!
    var backgroundReflected = false
    
    var levelData: NSDictionary!
    
    // music
    var backgroundMusic: SKAudioNode!
    
    // For iPhone 6
    var scaleFactor: CGFloat!
    
    let tapToStartNode = SKLabelNode(fontNamed: "Futura-Medium")
    
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
        // background moves at 10% speed of foreground, so divide by 0.1
        backgroundImageHeight = (64.0 * scaleFactor * 20) / 0.1
        backgroundHeight = backgroundImageHeight
        
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
        drawAsteroids(startingAt: 400)
        
        // Player
        player = createPlayer()
        player.name = "PLAYER"
        foreground.addChild(player)
        
        // Tap to Start
        // TODO: Change this image to something else, like Blast Off!
        tapToStartNode.name = "TAPTOSTART"
        tapToStartNode.fontSize = 30
        tapToStartNode.fontColor = SKColor.whiteColor()
        tapToStartNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        tapToStartNode.text = "TAP TO BLAST OFF!"
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: player.position.y + 100)
        tapToStartNode.zPosition = player.zPosition + 1
        hud.addChild(tapToStartNode)
        
        createHUD()
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if gameOver {
            return
        }
        
        // Update Score
        GameState.sharedInstance.score = max(Int(player.position.y) - 160, 0)
        scoreLabel.text = "\(GameState.sharedInstance.score)"
        
        // Remove past objects
        foreground.enumerateChildNodesWithName("*", usingBlock: {
            (node, stop) in
            
            if let name = node.name {
                switch name {
                case "MOVING_ASTEROID", "NORMAL_ASTEROID":
                    let asteroid = node as! AsteroidNode
                    asteroid.checkNodeRemoval(self.player.position.y)
                case "LASER":
                    let laser = node as! LaserNode
                    laser.checkNodeRemoval(self.player.position.y)
                default: break
                }
            }
            
            
            if (node.name == "MOVING_ASTEROID" || node.name == "NORMAL_ASTEROID") {
                let asteroid = node as! AsteroidNode
                asteroid.checkNodeRemoval(self.player.position.y)
            }
            
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
        
        
        // Check if we should spawn a power up
        if (random() % 1000) == 0 {
            drawPowerUp()
        }
        
        // Check if we should add a flying asteroid
        if (player.physicsBody!.dynamic) {
            if (random() % 150) == 0 {
                drawMovingAsteroid()
            }
        }
        
        // Check if we need to reload background
        // Divide height by 0.1 because background moves at 10% speed of foreground
        if (player.position.y > backgroundHeight - self.size.height / 0.1) {
            backgroundHeight = backgroundHeight + backgroundImageHeight
            let newBackground = createBackground(Int(backgroundHeight / backgroundImageHeight) - 1)
            newBackground.zPosition = 0
            background.addChild(newBackground)
        }
    }
    
    // addLaser: play laser sound and shoot a laser node from the player's ship
    func addLaser() {
        
        if let laserSoundURL = NSBundle.mainBundle().URLForResource("laser", withExtension: "wav") {
            let laserSound = SKAudioNode(URL: laserSoundURL)
            laserSound.autoplayLooped = false
            laserSound.runAction(SKAction.changeVolumeTo(0.2, duration: 0))
            laserSound.runAction(SKAction.play())
            addChild(laserSound)
        }
        
        let laser = LaserNode()
        laser.position = player.position
        foreground.addChild(laser)
        laser.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // If already started ignore touches
        if (player.physicsBody!.dynamic && player.type == .Normal) {
            return
        } else if (player.type == .Laser) {
            addLaser()
            return
        }
        
        initMotionManager()
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
        let imageName = (backgroundReflected) ? "space_background_reflected%02d" : "space_background%02d"
        
        // load 20 background nodes
        for i in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: imageName, i + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            
            // offset used to calculate y when ship climbs beyond background already loaded
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * (CGFloat(20 * offset + 19 - i)))
            background.addChild(node)
        }
        background.name = "BACKGROUND"
        backgroundReflected = !backgroundReflected
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
    
    func createPlayer() -> ShipNode {
        
        let playerNode = ShipNode(type: .Normal)
        playerNode.position = CGPoint(x: self.size.width / 2, y: 160.0)
        
        return playerNode
    }
    
    func createHUD() {

        // TODO: Change this dumb font
        scoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        
        scoreLabel.text = "0"
        hud.addChild(scoreLabel)
    }
    
    // For creating stationary asteroids
    func drawAsteroidAtPosition(position: CGPoint, ofType type: AsteroidType) -> AsteroidNode {
        
        let node = AsteroidNode(type: type)
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        
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
    
    func drawMovingAsteroid() {
        let r = random()
        let xPosition = CGFloat(r) % self.size.width
        let asteroid = drawAsteroidAtPosition(CGPoint(x: xPosition, y: player.position.y + self.size.height), ofType: .Moving)
        foreground.addChild(asteroid)

        // Get random dx between -5 and 5, random dy between -15 and -5
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

    // If a node is near an asteroid, it will move it over
    func checkForIntersectionWithAsteroid(node: GameObjectNode) -> GameObjectNode {
        foreground.enumerateChildNodesWithName("NORMAL_ASTEROID", usingBlock: {
            (asteroidNode, stop) in
            
            let sprite = asteroidNode.childNodeWithName("ASTEROID")! as! SKSpriteNode
            let origin = CGPoint(x: asteroidNode.position.x - sprite.size.width / 2,
                y: asteroidNode.position.y - sprite.size.height / 2)
            let size = CGSize(width: sprite.size.width * 2, height: sprite.size.height * 2)
            
            let frame = CGRect(origin: origin, size: size)
            
            if (CGRectContainsPoint(frame, node.position)) {
                node.position.x = ((node.position.x + 50) % (self.size.width - 60)) + 30
                stop.memory = true
            }
        })
        return node
    }
    
    func drawPowerUp() {
        // TODO: For now pick a LaserShip, later we will choose random power up from plist
        // plist will just store a list of power up types, or use an enum in gameobjectnode
        let xPosition = (CGFloat(random()) % (self.size.width - 60)) + 30
        let yPosition = player.position.y + self.size.height + 100
        
        var node = ShipNode(type: .Laser)
        node.position = CGPoint(x: xPosition * scaleFactor, y: yPosition)
        node = checkForIntersectionWithAsteroid(node) as! ShipNode
        foreground.addChild(node)
    }
    
    // MARK: Motion Manager Setup
    
    func initMotionManager() {
        
        // Get xAcceleration
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
            (accelerometerData: CMAccelerometerData?, error: NSError?) in
            let acceleration = accelerometerData!.acceleration
            self.xAcceleration = ((CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)) * 1.5
        })
        
        // Get rotation
        motionManager.deviceMotionUpdateInterval = 0.02
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
            (motion: CMDeviceMotion?, error: NSError?) in
            if let gravity = motion?.gravity {
                // make sure rotation never makes ship look upside down
                self.rotation = CGFloat(atan2(gravity.x, min(gravity.y, -gravity.y)) + M_PI)
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

        if (contact.bodyA.node != player && contact.bodyB.node != player) {
            
            // Collision between laser and asteroid
            if let asteroid = contact.bodyA.node as? AsteroidNode,
                laser = (contact.bodyB.node as? LaserNode) {
                updateHUD = laser.collisionWithAsteroid(asteroid)
            } else if let asteroid = contact.bodyB.node as? AsteroidNode,
                laser = contact.bodyA.node as? LaserNode {
                updateHUD = laser.collisionWithAsteroid(asteroid)
            }
            
        } else {
            // Collision between player and something
            let nonPlayerNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
            if let other = nonPlayerNode as? GameObjectNode {
                updateHUD = other.collisionWithPlayer(player)
            }
        }
        
        // Update the HUD if necessary
        if updateHUD {
            scoreLabel.text = "\(GameState.sharedInstance.score)"
        }
    }
    
}