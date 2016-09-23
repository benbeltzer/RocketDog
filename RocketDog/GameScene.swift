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
    
    // Layer Speeds
    var backgroundSpeed: CGFloat!
    var midgroundSpeed: CGFloat!
    var foregroundSpeed: CGFloat!
    var playerSpeed: CGFloat!
    var paralaxRate: CGFloat = 1
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0 // value from accelerometer
    var rotation: CGFloat = 0.0
    
    var maxLevelY: CGFloat = 2000.0
    var backgroundHeight: CGFloat!
    var backgroundImageHeight: CGFloat!
    var backgroundReflected = false
    
    var levelInterval = 1
    var blackHoleInterval = 1
    var extraPoints = 0
    var laserBar: SKShapeNode!
    
    // Shield
    var shieldAvailable = true
    
    // music
    var backgroundMusic: SKAudioNode!
    
    // For iPhone 6
    var scaleFactor: CGFloat!
    
    let tapToUseShieldNode = SKLabelNode(fontNamed: "Futura-Medium")
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
        
        // Paralax Effect parameters
        setLayerSpeeds()
        
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
        drawAsteroids(startingAt: 400)
        
        // Player
        player = createPlayer()
        player.name = "PLAYER"
        player.zPosition = 3
        foreground.addChild(player)
        
        // Tap to Use Shield
        tapToUseShieldNode.name = "TAPTOUSESHIELD"
        tapToUseShieldNode.fontSize = 15
        tapToUseShieldNode.fontColor = SKColor.whiteColor()
        tapToUseShieldNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        tapToUseShieldNode.text = "TAP TO USE SHIELD AT ANY TIME"
        tapToUseShieldNode.position = CGPoint(x: self.size.width - 20, y: 30)
        tapToUseShieldNode.zPosition = player.zPosition + 1
        hud.addChild(tapToUseShieldNode)
        
        // Tap to Start
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
        GameState.sharedInstance.score = max(Int(player.position.y) + extraPoints - 160, 0)
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
            if player.type != .Boost {
                setLayerSpeeds()
            }
            background.position.y -= backgroundSpeed
            midground.position.y -=  midgroundSpeed
            foreground.position.y -= foregroundSpeed
            player.position.y += playerSpeed
        }
        
        // Check if we need to add more asteroids
        if player.position.y > maxLevelY - 1000 {
            maxLevelY += 1000
            drawAsteroids(startingAt: maxLevelY - 1000)
        }
        
        // Check if we should add a flying asteroid
        if (player.physicsBody!.dynamic) {
            if (Int(arc4random()) % 150) == 0 {
                drawMovingAsteroid()
            }
        }
        
        // Draw black hole at distance intervals of 500
        if Int(player.position.y) > blackHoleInterval * 500 {
            blackHoleInterval += 1
            drawSpecialNode(BlackHoleNode())
        }
        
        // Draw an power up at distance intervals of 1500
        if Int(player.position.y) > levelInterval * 1500 {
            levelInterval += 1

            // draw laser ships 3/4 of time and boost 1/4 of time
            if (Int(arc4random()) % 4) < 3 {
                drawSpecialNode(ShipNode(type: .Laser))
            } else {
                drawSpecialNode(ShipNode(type: .Boost))
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
    
    func setLayerSpeeds(backgroundRate: CGFloat = 0.2, midgroundRate: CGFloat = 0.5, foregroundRate: CGFloat = 2, playerRate: CGFloat = 2) {
        // 1000 ft increase in height: 10% increase in speed. Max rate is 3
        if let height = player?.position.y {
            paralaxRate = min(1 + 0.05 * (height / 1000), 4)
            if paralaxRate > 2 {
                paralaxRate = 2 + (((paralaxRate - 2) % 2.01) * 0.5)
            }
        }
        
        backgroundSpeed = backgroundRate * paralaxRate
        midgroundSpeed =  midgroundRate * paralaxRate
        foregroundSpeed = foregroundRate * paralaxRate
        playerSpeed = playerRate * paralaxRate
    }
    
    func createLaserBar() {
        if (laserBar == nil) {
            laserBar = SKShapeNode(path: CGPathCreateWithRoundedRect(CGRect(x: 0, y: 0, width: 100, height: 15), 5, 5, nil))
            laserBar.strokeColor = .blackColor()
            laserBar.fillColor = .redColor()
            laserBar.position = CGPoint(x: 10, y: self.size.height - 20)
            laserBar.zPosition = 10
            laserBar.name = "LASER_BAR"
            addChild(laserBar)
        } else {
            laserBar.xScale = 1
            if laserBar.parent == nil {
                addChild(laserBar)
            }
        }
    }
    
    func shrinkLaserBar() {
        if (laserBar != nil) {
            laserBar.xScale -= 0.04
            if laserBar.xScale <= 0 {
                laserBar.removeFromParent()
                
                // swap ship
                player.removeAllChildren()
                player.type = .Normal
                player.addChild(SKSpriteNode(imageNamed: "blueShip"))
            }
        }
    }
    
    // addLaser: play laser sound and shoot a laser node from the player's ship
    func addLaser() {
        
        let laserSound = SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false)
        runAction(laserSound)
        
        let laser = LaserNode()
        laser.position = player.position
        laser.physicsBody?.velocity.dx = (player.physicsBody?.velocity.dx)! * 2
        laser.zRotation = player.zRotation
        foreground.addChild(laser)
        laser.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50 * paralaxRate))
        shrinkLaserBar()
    }
    
    // Protects player for 1 second
    func useShield() {
        shieldAvailable = false
        player.invincible = true
        
        // Remove Shield Image from HUD
        hud.enumerateChildNodesWithName("SHIELD") { (node, bool) in
            node.removeFromParent()
        }
        
        // Play sound
        let shieldSound = SKAction.playSoundFileNamed("shield.wav", waitForCompletion: false)
        runAction(shieldSound)
        
        // Add force field around ship for 1 second
        let sprite = SKSpriteNode(imageNamed: "force_field")
        player.addChild(sprite)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
            sprite.removeFromParent()
            self.player.invincible = false
            
            // After 4 more seconds, recharge shield
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
                self.shieldAvailable = true
                self.drawShield()
            })
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (shieldAvailable && player.type == .Normal && player.physicsBody!.dynamic) {
            useShield()
            return
        }
        else if (player.physicsBody!.dynamic && player.type != .Laser) {
            // ignore touches if not laser and not using shield
            return
        } else if (player.type == .Laser) {
            addLaser()
            return
        }
    
        initMotionManager()
        tapToStartNode.removeFromParent()
        tapToUseShieldNode.removeFromParent()
        
        if let musicURL = NSBundle.mainBundle().URLForResource("rocket_thrust", withExtension: "wav") {
            backgroundMusic = SKAudioNode(URL: musicURL)
            addChild(backgroundMusic)
        }
        
        player.physicsBody?.dynamic = true
        player.addThrust() // should only happen at launch
    }
    
    override func didSimulatePhysics() {
        if (!player.simulatePhysics) {
            return
        }
        
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

        // Score Label
        scoreLabel = SKLabelNode(fontNamed: "Futura-Medium")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        scoreLabel.text = "0"
        hud.addChild(scoreLabel)
        
        // Shield
        drawShield()
    }
    
    func drawShield() {
        let sprite = SKSpriteNode(imageNamed: "shield")
        sprite.position = CGPoint(x: 25, y: 35)
        sprite.name = "SHIELD"
        hud.addChild(sprite)
    }
    
    // For creating stationary asteroids
    func createAsteroidAtPosition(position: CGPoint, ofType type: AsteroidType) -> AsteroidNode {
        let node = AsteroidNode(type: type)
        node.position = CGPoint(x: position.x * scaleFactor, y: position.y)
        return node
    }
    
    func drawAsteroids(startingAt y: CGFloat) {
        var currentY = y
        var xPosition: CGFloat!
        var r = 0
        
        while (currentY < maxLevelY) {
            r = Int(arc4random())

            // Get random xPosition between 0 and self.size.width - 30
            xPosition = (CGFloat(r) % (self.size.width - 30))
            
            let asteroid = createAsteroidAtPosition(CGPoint(x: xPosition, y: currentY), ofType: .Normal)
            foreground.addChild(asteroid)
            currentY += 100
        }
    }
    
    func drawMovingAsteroid() {
        let r = Int(arc4random())
        let xPosition = CGFloat(r) % self.size.width
        let asteroid = createAsteroidAtPosition(CGPoint(x: xPosition, y: player.position.y + self.size.height), ofType: .Moving)
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
    func checkForIntersectionWithObjects(node: GameObjectNode) -> GameObjectNode {
        foreground.enumerateChildNodesWithName("*", usingBlock: {
            (child, stop) in
            
            if ((child.name != nil) && (child.name != "PLAYER")) {
                let origin = CGPoint(x: child.position.x - 100, y: child.position.y - 100)
                let size = CGSize(width: 200, height: 200)
                let frame = CGRect(origin: origin, size: size)

                if (CGRectContainsPoint(frame, node.position)) {
                    node.position.x = ((node.position.x + 150) % (self.size.width - 30)) + 10
                    stop.memory = true
                }
            }
        })
        return node
    }

    // TODO: For now pick a LaserShip, later we will choose random power up from plist
    // plist will just store a list of power up types, or use an enum in gameobjectnode
    func drawSpecialNode(node: GameObjectNode) {
        let xPosition = (CGFloat(arc4random()) % (self.size.width - 60)) + 30
        let yPosition = player.position.y + self.size.height
        
        node.position = CGPoint(x: xPosition * scaleFactor, y: yPosition)
        let modifiedNode = checkForIntersectionWithObjects(node)
        foreground.addChild(modifiedNode)
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
        let endScene = EndGameScene(size: self.size)
        self.view!.presentScene(endScene, transition: reveal)
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBeginContact(contact: SKPhysicsContact) {

        if (contact.bodyA.node != player && contact.bodyB.node != player) {
            
            // Collision between laser and something
            if let asteroid = contact.bodyA.node as? AsteroidNode,
                laser = (contact.bodyB.node as? LaserNode) {
                laser.collisionWithAsteroid(asteroid)
            } else if let asteroid = contact.bodyB.node as? AsteroidNode,
                laser = contact.bodyA.node as? LaserNode {
                laser.collisionWithAsteroid(asteroid)
            } else if let laser = contact.bodyA.node as? LaserNode,
                blackHole = contact.bodyB.node as? BlackHoleNode {
                blackHole.collisionWithLaser(laser)
            } else if let blackHole = contact.bodyA.node as? BlackHoleNode,
                laser = contact.bodyB.node as? LaserNode {
                blackHole.collisionWithLaser(laser)
            }
            
        } else {
            // Collision between player and something
            let nonPlayerNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
            if let other = nonPlayerNode as? GameObjectNode {
                if let ship = (other as? ShipNode) where ship.type == .Laser && player.type != .Boost {
                    createLaserBar()
                }
                other.collisionWithPlayer(player)
            }
        }

    }
    
}
