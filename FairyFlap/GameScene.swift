//
//  GameScene.swift
//  FairyFlap
//
//  Created by Jeff Hedrick on 5/24/2026.
//  Copyright © 2026 Jeff Hedrick. All rights reserved. 
//

import SpriteKit

/// The main gameplay scene. Handles the fairy, scrolling world, stone obstacles,
/// scoring, collisions, and automatic return to home after death.
class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    
    var fairy:SKSpriteNode!
    var sceneBackgroundColor:SKColor!
    var stoneTextureUp:SKTexture!
    var stoneTextureDown:SKTexture!
    var moveStonesAndRemove:SKAction!
    var backgroundMoving:SKNode!
    var moving:SKNode!
    var stones:SKNode!
    var dustClouds:SKNode!
    var spikeBalls:SKNode!
    var scoreLabelNode:SKLabelNode!
    var highScoreLabelNode:SKLabelNode!
    var fairyTexture1: SKTexture!
    var fairyTexture2: SKTexture!
    var unicornTexture1: SKTexture!
    var unicornTexture2: SKTexture!
    var score = 0
    var groundHeight: CGFloat = 0
    var isInvincible = false
    var isUnicorn = false
    var justAchievedHighScore = false
    var stonesSinceLastCollectible = 0
    var stonesUntilNextCollectible = Int.random(in: 3...5)
    
    let backgroundScrollSpeed: CGFloat = 0.35
    
    let fairyCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let stoneCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let dustCategory: UInt32 = 1 << 4
    let spikeBallCategory: UInt32 = 1 << 5
    let verticalStoneGap: CGFloat = 150.0
    let fairyScale: CGFloat = 1.5
    let collectibleStoneIntervalRange: ClosedRange<Int> = 3...5
    
    /// Called when the scene is first loaded from the .sks file. Clears any
    /// default physics body so we can configure physics in `didMove(to:)`.
    override func sceneDidLoad() {
        self.physicsBody = nil
    }

    /// Sets up the entire game when the scene is presented.
    ///
    /// Configures physics, the parallax scrolling background, grass, the fairy,
    /// score labels, stone spawning, and collectible scheduling.
    ///
    /// - Parameter view: The view that is presenting this scene.
    override func didMove(to view: SKView) {
        
        // setup physics
        self.physicsBody = nil
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color (matches forest sky at top)
        sceneBackgroundColor = SKColor(red: 120.0/255.0, green: 170.0/255.0, blue: 200.0/255.0, alpha: 1.0)
        self.backgroundColor = sceneBackgroundColor
        
        backgroundMoving = SKNode()
        backgroundMoving.speed = backgroundScrollSpeed
        self.addChild(backgroundMoving)
        
        moving = SKNode()
        self.addChild(moving)
        stones = SKNode()
        moving.addChild(stones)
        dustClouds = SKNode()
        moving.addChild(dustClouds)
        spikeBalls = SKNode()
        moving.addChild(spikeBalls)
        
        // Grass (foreground — scrolls at full speed)
        groundHeight = addScrollingGrass(to: moving)
        
        // forest background (scrolls slower via backgroundMoving.speed)
        let forestTexture = SKTexture(imageNamed: "forest")
        forestTexture.filteringMode = .nearest
        
        let forestXScale: CGFloat = 2.0
        let forestDisplayHeight = self.frame.size.height - groundHeight
        let forestYScale = forestDisplayHeight / forestTexture.size().height
        let forestTileWidth = forestTexture.size().width * forestXScale
        
        let moveForestSprite = SKAction.moveBy(x: -forestTileWidth, y: 0, duration: TimeInterval(0.02 * forestTileWidth))
        let resetForestSprite = SKAction.moveBy(x: forestTileWidth, y: 0, duration: 0.0)
        let moveForestSpritesForever = SKAction.repeatForever(SKAction.sequence([moveForestSprite, resetForestSprite]))
        
        let forestTileCount = Int(ceil(Double(self.frame.size.width) / Double(forestTileWidth))) + 3
        for i in 0 ..< forestTileCount {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: forestTexture)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
            sprite.xScale = forestXScale
            sprite.yScale = forestYScale
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * forestTileWidth + forestTileWidth / 2.0, y: groundHeight)
            sprite.run(moveForestSpritesForever)
            backgroundMoving.addChild(sprite)
        }
        
        // create the stone textures
        stoneTextureUp = SKTexture(imageNamed: "StoneUp")
        stoneTextureUp.filteringMode = .nearest
        stoneTextureDown = SKTexture(imageNamed: "StoneDown")
        stoneTextureDown.filteringMode = .nearest
        
        // create the stones movement actions
        let scaledStoneWidth = stoneTextureUp.size().width * 2.0
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * scaledStoneWidth)
        let duration = TimeInterval(0.01 * distanceToMove)
        let moveStones = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: duration)
        let waitBeforeFade = SKAction.wait(forDuration: duration * 0.7)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.3)
        let moveAndFade = SKAction.group([moveStones, SKAction.sequence([waitBeforeFade, fadeOut])])
        moveStonesAndRemove = SKAction.sequence([moveAndFade, SKAction.removeFromParent()])
        
        // spawn the stones
        let spawn = SKAction.run(spawnStones)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        stonesSinceLastCollectible = 0
        stonesUntilNextCollectible = Int.random(in: collectibleStoneIntervalRange)
        
        // setup our fairy
        fairyTexture1 = SKTexture(imageNamed: "fairy-01")
        fairyTexture1.filteringMode = .nearest
        fairyTexture2 = SKTexture(imageNamed: "fairy-02")
        fairyTexture2.filteringMode = .nearest
        unicornTexture1 = SKTexture(imageNamed: "unicorn-01")
        unicornTexture1.filteringMode = .nearest
        unicornTexture2 = SKTexture(imageNamed: "unicorn-02")
        unicornTexture2.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [fairyTexture1, fairyTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        fairy = SKSpriteNode(texture: fairyTexture1)
        fairy.setScale(fairyScale)
        fairy.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        fairy.run(flap, withKey: "flap")
        
        
        fairy.physicsBody = SKPhysicsBody(circleOfRadius: fairy.size.height / 2.0)
        fairy.physicsBody?.isDynamic = true
        fairy.physicsBody?.allowsRotation = false
        
        fairy.physicsBody?.categoryBitMask = fairyCategory
        fairy.physicsBody?.collisionBitMask = worldCategory | stoneCategory
        fairy.physicsBody?.contactTestBitMask = worldCategory | stoneCategory | dustCategory | spikeBallCategory
        
        self.addChild(fairy)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundHeight / 2.0)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundHeight))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Score label
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        scoreLabelNode.isAccessibilityElement = true
        scoreLabelNode.accessibilityIdentifier = AccessibilityID.scoreLabel
        scoreLabelNode.accessibilityLabel = String(score)
        self.addChild(scoreLabelNode)

        // High score label (top-right)
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        highScoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        highScoreLabelNode.position = CGPoint(x: self.frame.size.width - 12, y: 3 * self.frame.size.height / 4 - 32)
        highScoreLabelNode.horizontalAlignmentMode = .right
        highScoreLabelNode.zPosition = 100
        highScoreLabelNode.fontSize = 18
        highScoreLabelNode.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        highScoreLabelNode.text = "Top Score: \(highScore)"
        self.addChild(highScoreLabelNode)
        
    }
    
    /// Creates a new pair of top/bottom stone obstacles with a random gap height,
    /// plus an invisible score trigger between them, and scrolls them off-screen.
    func spawnStones() {
        let stonePair = SKNode()
        stonePair.position = CGPoint( x: self.frame.size.width + stoneTextureUp.size().width * 2, y: 0 )
        stonePair.zPosition = -10
        
        let stoneScale: CGFloat = 2.0
        let stoneUpHeight = stoneTextureUp.size().height * stoneScale
        
        // Vary gap height while keeping the bottom stone near the ground.
        let maxStoneY = groundHeight + stoneUpHeight / 2
        let variation = max(1, UInt32(self.frame.size.height / 4))
        let y = CGFloat(UInt32.random(in: 0..<variation)) + (maxStoneY - CGFloat(variation))
        
        let stoneUp = SKSpriteNode(texture: stoneTextureUp)
        stoneUp.setScale(stoneScale)
        stoneUp.position = CGPoint(x: 0.0, y: y)
        stoneUp.physicsBody = SKPhysicsBody(rectangleOf: stoneUp.size)
        stoneUp.physicsBody?.isDynamic = false
        stoneUp.physicsBody?.categoryBitMask = stoneCategory
        stoneUp.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(stoneUp)
        
        let stoneDown = SKSpriteNode(texture: stoneTextureDown)
        stoneDown.setScale(stoneScale)
        stoneDown.position = CGPoint(x: 0.0, y: y + stoneDown.size.height + verticalStoneGap)
        stoneDown.physicsBody = SKPhysicsBody(rectangleOf: stoneDown.size)
        stoneDown.physicsBody?.isDynamic = false
        stoneDown.physicsBody?.categoryBitMask = stoneCategory
        stoneDown.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(stoneDown)
        
        // Stack extra segments above the gap stone so obstacles always reach the top.
        let segmentHeight = stoneDown.size.height
        var fillY = stoneDown.position.y + segmentHeight / 2
        while fillY < self.frame.size.height {
            let filler = SKSpriteNode(texture: stoneTextureDown)
            filler.setScale(stoneScale)
            filler.anchorPoint = CGPoint(x: 0.5, y: 0)
            filler.position = CGPoint(x: 0, y: fillY)
            filler.physicsBody = SKPhysicsBody(rectangleOf: filler.size)
            filler.physicsBody?.isDynamic = false
            filler.physicsBody?.categoryBitMask = stoneCategory
            filler.physicsBody?.contactTestBitMask = fairyCategory
            stonePair.addChild(filler)
            fillY += segmentHeight
        }
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: stoneDown.size.width + fairy.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: stoneUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(contactNode)
        
        stonePair.run(moveStonesAndRemove)
        stones.addChild(stonePair)
        handleCollectibleSpawnAfterStone(stonePair)
    }
    
    /// Attempts to spawn fairy dust or a spike ball after a new stone pair appears.
    ///
    /// A collectible is placed every 3–5 stone pairs, randomly chosen as dust or
    /// a spike ball, and only when no other collectible is on screen.
    ///
    /// - Parameter stonePair: The stone obstacle pair that just spawned.
    func handleCollectibleSpawnAfterStone(_ stonePair: SKNode) {
        guard moving.speed > 0 else { return }
        
        stonesSinceLastCollectible += 1
        guard stonesSinceLastCollectible >= stonesUntilNextCollectible else { return }
        guard dustClouds.children.isEmpty, spikeBalls.children.isEmpty else { return }
        
        let spawned = Bool.random()
            ? spawnDustCloud(on: stonePair)
            : spawnSpikeBall(on: stonePair)
        
        if spawned {
            stonesSinceLastCollectible = 0
            stonesUntilNextCollectible = Int.random(in: collectibleStoneIntervalRange)
        }
    }
    
    /// Returns a random point inside the flyable gap of a specific stone pair.
    ///
    /// - Parameters:
    ///   - stonePair: The stone obstacle pair to search.
    ///   - radius: The collectible's collision radius.
    ///   - margin: Extra clearance kept between the collectible and gap edges.
    /// - Returns: A position in scene coordinates, or nil when the gap is too small.
    func collectPositionInGap(for stonePair: SKNode, radius: CGFloat, margin: CGFloat = 12) -> CGPoint? {
        guard let gap = gapBounds(for: stonePair) else { return nil }
        let padding = radius + margin
        guard gap.top - gap.bottom >= padding * 2 else { return nil }
        let y = CGFloat.random(in: gap.bottom + padding ... gap.top - padding)
        return CGPoint(x: gap.x, y: y)
    }
    
    /// Returns the horizontal center and vertical bounds of the flyable gap in a stone pair.
    ///
    /// - Parameter stonePair: A stone obstacle node containing bottom, gap-lip,
    ///   and filler segment sprites.
    /// - Returns: The gap center X and bottom/top Y in scene coordinates, or nil
    ///   when the pair does not contain a valid gap.
    func gapBounds(for stonePair: SKNode) -> (x: CGFloat, bottom: CGFloat, top: CGFloat)? {
        var bottomStone: SKSpriteNode?
        for case let stone as SKSpriteNode in stonePair.children {
            guard stone.physicsBody?.categoryBitMask == stoneCategory else { continue }
            if bottomStone == nil || stone.position.y < bottomStone!.position.y {
                bottomStone = stone
            }
        }
        guard let bottom = bottomStone else { return nil }
        
        var gapLipStone: SKSpriteNode?
        for case let stone as SKSpriteNode in stonePair.children {
            guard stone.physicsBody?.categoryBitMask == stoneCategory else { continue }
            if stone.position.y > bottom.position.y {
                if gapLipStone == nil || stone.position.y < gapLipStone!.position.y {
                    gapLipStone = stone
                }
            }
        }
        guard let lip = gapLipStone else { return nil }
        
        let gapBottom = stonePair.position.y + bottom.position.y + bottom.size.height / 2
        let gapTop = stonePair.position.y + lip.position.y - lip.size.height / 2
        guard gapTop > gapBottom else { return nil }
        
        return (stonePair.position.x, gapBottom, gapTop)
    }
    
    /// Creates a small fairy dust cloud inside a stone gap.
    ///
    /// Collecting one makes the character glow and become invincible for five seconds.
    ///
    /// - Returns: `true` when the cloud was spawned; `false` when no gap was available.
    @discardableResult
    func spawnDustCloud(on stonePair: SKNode) -> Bool {
        guard let position = collectPositionInGap(for: stonePair, radius: 14) else { return false }
        return spawnDustCloud(at: position)
    }
    
    @discardableResult
    func spawnDustCloud(at position: CGPoint) -> Bool {
        let cloud = SKNode()
        cloud.position = position
        cloud.zPosition = -5
        
        let dustColors: [SKColor] = [
            SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.8),
            SKColor(red: 1.0, green: 0.75, blue: 0.9, alpha: 0.8),
            SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.8),
            SKColor(red: 1.0, green: 1.0, blue: 0.85, alpha: 0.7)
        ]
        
        let particleCount = Int.random(in: 4...7)
        for _ in 0..<particleCount {
            let radius = CGFloat.random(in: 2.5...5.0)
            let dot = SKShapeNode(circleOfRadius: radius)
            dot.fillColor = dustColors.randomElement()!
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: CGFloat.random(in: -10...10),
                y: CGFloat.random(in: -10...10)
            )
            cloud.addChild(dot)
        }
        
        let twinkle = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.35, duration: TimeInterval.random(in: 0.3...0.5)),
            SKAction.fadeAlpha(to: 0.95, duration: TimeInterval.random(in: 0.3...0.5))
        ]))
        cloud.run(twinkle)
        
        cloud.physicsBody = SKPhysicsBody(circleOfRadius: 14)
        cloud.physicsBody?.isDynamic = false
        cloud.physicsBody?.categoryBitMask = dustCategory
        cloud.physicsBody?.contactTestBitMask = fairyCategory
        cloud.physicsBody?.collisionBitMask = 0
        
        cloud.run(moveStonesAndRemove)
        dustClouds.addChild(cloud)
        return true
    }
    
    /// Creates a rolling spike ball inside a stone gap.
    ///
    /// Touching one turns the fairy into a unicorn for ten seconds, awards five
    /// points, and does not interrupt gameplay.
    ///
    /// - Returns: `true` when the ball was spawned; `false` when no gap was available.
    @discardableResult
    func spawnSpikeBall(on stonePair: SKNode) -> Bool {
        let ballRadius: CGFloat = 16
        guard let position = collectPositionInGap(for: stonePair, radius: ballRadius) else { return false }
        return spawnSpikeBall(at: position, radius: ballRadius)
    }
    
    @discardableResult
    func spawnSpikeBall(at position: CGPoint, radius ballRadius: CGFloat = 16) -> Bool {
        let ball = makeSpikeBallNode(radius: ballRadius)
        ball.position = position
        ball.zPosition = -5
        
        let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2.5))
        ball.run(spin)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody?.isDynamic = false
        ball.physicsBody?.categoryBitMask = spikeBallCategory
        ball.physicsBody?.contactTestBitMask = fairyCategory
        ball.physicsBody?.collisionBitMask = 0
        
        ball.run(moveStonesAndRemove)
        spikeBalls.addChild(ball)
        return true
    }
    
    /// Builds a spiky ball from simple shapes so no extra art assets are needed.
    ///
    /// - Parameter radius: The overall radius of the spike ball.
    /// - Returns: A node containing a circular core and radial spike shapes.
    func makeSpikeBallNode(radius: CGFloat) -> SKNode {
        let ball = SKNode()
        
        let core = SKShapeNode(circleOfRadius: radius * 0.72)
        core.fillColor = SKColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)
        core.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
        core.lineWidth = 2
        ball.addChild(core)
        
        let spikeCount = 10
        for i in 0..<spikeCount {
            let angle = (CGFloat(i) / CGFloat(spikeCount)) * .pi * 2
            let spikePath = CGMutablePath()
            spikePath.move(to: CGPoint(x: 0, y: radius * 0.35))
            spikePath.addLine(to: CGPoint(x: -radius * 0.18, y: -radius * 0.05))
            spikePath.addLine(to: CGPoint(x: radius * 0.18, y: -radius * 0.05))
            spikePath.closeSubpath()
            
            let spike = SKShapeNode(path: spikePath)
            spike.fillColor = SKColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1.0)
            spike.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
            spike.lineWidth = 1
            spike.position = CGPoint(x: cos(angle) * radius * 0.55, y: sin(angle) * radius * 0.55)
            spike.zRotation = angle - .pi / 2
            ball.addChild(spike)
        }
        
        return ball
    }
    
    /// Turns the fairy into a flying unicorn for ten seconds. Gameplay continues normally.
    /// Touching another spike ball while transformed resets the timer.
    func applyUnicornTransform() {
        fairy.removeAction(forKey: "unicornTransform")
        isUnicorn = true
        
        fairy.removeAction(forKey: "flap")
        fairy.setScale(fairyScale)
        fairy.color = .white
        fairy.colorBlendFactor = 0
        
        let unicornAnim = SKAction.animate(with: [unicornTexture1, unicornTexture2], timePerFrame: 0.2)
        fairy.run(SKAction.repeatForever(unicornAnim), withKey: "unicornFlap")
        
        let revert = SKAction.run { self.restoreFairyAppearance() }
        fairy.run(SKAction.sequence([SKAction.wait(forDuration: 10.0), revert]), withKey: "unicornTransform")
    }
    
    /// Restores the fairy sprite, flap animation, and tint after a unicorn transform ends.
    ///
    /// Preserves the glowing invincible appearance when fairy dust is still active.
    func restoreFairyAppearance() {
        isUnicorn = false
        fairy.removeAction(forKey: "unicornFlap")
        fairy.setScale(fairyScale)
        
        if isInvincible {
            fairy.color = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
            fairy.colorBlendFactor = 0.55
        } else {
            fairy.color = .white
            fairy.colorBlendFactor = 0
        }
        
        let anim = SKAction.animate(with: [fairyTexture1, fairyTexture2], timePerFrame: 0.2)
        fairy.run(SKAction.repeatForever(anim), withKey: "flap")
    }
    
    /// Applies a glowing aura for five seconds. While glowing the character is
    /// invincible and bounces off obstacles. Collecting another dust cloud
    /// while glowing resets the timer.
    func applyFairyGlow() {
        fairy.removeAction(forKey: "fairyGlow")
        fairy.childNode(withName: "glow")?.removeFromParent()
        isInvincible = true
        
        if !isUnicorn {
            fairy.color = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
            fairy.colorBlendFactor = 0.55
        }
        
        let glowRadius = fairy.size.height * 0.55
        let glow = SKShapeNode(circleOfRadius: glowRadius)
        glow.name = "glow"
        glow.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.45)
        glow.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 0.6)
        glow.lineWidth = 2
        glow.zPosition = -1
        glow.glowWidth = 4
        fairy.addChild(glow)
        
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.35, duration: 0.25),
            SKAction.fadeAlpha(to: 0.85, duration: 0.25)
        ]))
        glow.run(pulse, withKey: "pulse")
        
        let removeGlow = SKAction.run {
            glow.removeFromParent()
            self.isInvincible = false
            if !self.isUnicorn {
                self.fairy.colorBlendFactor = 0
                self.fairy.color = .white
            }
        }
        fairy.run(SKAction.sequence([SKAction.wait(forDuration: 5.0), removeGlow]), withKey: "fairyGlow")
    }
    
    /// Pushes the fairy away from an obstacle when invincible.
    ///
    /// - Parameter contact: The physics contact between the fairy and an obstacle.
    func bounceFairy(from contact: SKPhysicsContact) {
        guard let body = fairy.physicsBody else { return }
        
        let awayFromObstacle: CGVector
        if (contact.bodyA.categoryBitMask & fairyCategory) != 0 {
            awayFromObstacle = CGVector(dx: -contact.contactNormal.dx, dy: -contact.contactNormal.dy)
        } else {
            awayFromObstacle = contact.contactNormal
        }
        
        let bounceStrength: CGFloat = 9.0
        body.velocity = CGVector(
            dx: body.velocity.dx * 0.25 + awayFromObstacle.dx * bounceStrength,
            dy: body.velocity.dy * 0.25 + awayFromObstacle.dy * bounceStrength
        )
        
        let hitGround = (contact.bodyA.categoryBitMask & worldCategory) != 0
            || (contact.bodyB.categoryBitMask & worldCategory) != 0
        if hitGround && body.velocity.dy < 10 {
            body.velocity.dy = 10
        }
    }
    
    /// Transitions back to the home screen with a fade animation.
    ///
    /// Passes along whether the run ended on a new high score so the home screen
    /// can celebrate with fireworks.
    func goHome() {
        let scene = HomeScene(size: self.size)
        scene.scaleMode = self.scaleMode
        scene.celebrateNewHighScore = justAchievedHighScore
        self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }
    
    /// Ends the run, saves scores, flashes the screen, and returns home.
    func die() {
        guard moving.speed > 0 else { return }
        
        moving.speed = 0
        backgroundMoving.speed = 0
        isInvincible = false
        isUnicorn = false
        fairy.removeAction(forKey: "fairyGlow")
        fairy.removeAction(forKey: "unicornTransform")
        fairy.removeAction(forKey: "unicornFlap")
        fairy.removeAction(forKey: "flap")
        fairy.childNode(withName: "glow")?.removeFromParent()
        fairy.colorBlendFactor = 0
        fairy.color = .white
        fairy.setScale(fairyScale)
        fairy.zRotation = 0
        
        fairy.physicsBody?.collisionBitMask = worldCategory
        fairy.run(SKAction.rotate(byAngle: .pi * fairy.position.y * 0.01, duration: 1), completion: { self.fairy.speed = 0 })
        
        UserDefaults.standard.set(score, forKey: "lastScore")
        let currentBest = UserDefaults.standard.integer(forKey: "highScore")
        if score > currentBest {
            UserDefaults.standard.set(score, forKey: "highScore")
            highScoreLabelNode.text = "Top Score: \(score)"
            justAchievedHighScore = true
        } else {
            justAchievedHighScore = false
        }
        
        removeAction(forKey: "flash")
        run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
            self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        }), SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
            self.backgroundColor = self.sceneBackgroundColor
        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count: 4), SKAction.run({
            self.goHome()
        })]), withKey: "flash")
    }
    
    /// Returns whether the fairy has moved completely outside the visible scene.
    ///
    /// - Returns: `true` when the fairy is off any edge of the frame.
    func fairyIsOffScreen() -> Bool {
        let margin = max(fairy.size.width, fairy.size.height) / 2
        let pos = fairy.position
        return pos.x < -margin
            || pos.x > frame.size.width + margin
            || pos.y < -margin
            || pos.y > frame.size.height + margin
    }

    /// Handles tap input to flap the fairy during gameplay.
    ///
    /// - Parameters:
    ///   - touches: The touches that began on the scene.
    ///   - event: The event containing touch information.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0 {
            for _ in touches {
                fairy.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                fairy.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 13.5))
            }
        }
    }
    
    /// Called every frame to update fairy rotation and check for off-screen death.
    ///
    /// Tilts the sprite based on vertical velocity so it pitches up while rising
    /// and down while falling.
    ///
    /// - Parameter currentTime: The time elapsed since the scene began.
    override func update(_ currentTime: TimeInterval) {
        let dy = fairy.physicsBody!.velocity.dy
        let value = dy * (dy < 0 ? 0.003 : 0.001)
        fairy.zRotation = min( max(-1, value), 0.5 )
        
        if moving.speed > 0 && fairyIsOffScreen() {
            die()
        }
    }
    
    /// Physics contact handler for gameplay collisions.
    ///
    /// Collects fairy dust, spike balls, and score triggers; bounces off obstacles
    /// while invincible; otherwise triggers death on stone or ground contact.
    ///
    /// - Parameter contact: The physics bodies that just came into contact.
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & dustCategory ) == dustCategory || ( contact.bodyB.categoryBitMask & dustCategory ) == dustCategory {
                let dustNode = (contact.bodyA.categoryBitMask & dustCategory) == dustCategory ? contact.bodyA.node : contact.bodyB.node
                dustNode?.removeFromParent()
                applyFairyGlow()
            } else if ( contact.bodyA.categoryBitMask & spikeBallCategory ) == spikeBallCategory || ( contact.bodyB.categoryBitMask & spikeBallCategory ) == spikeBallCategory {
                let spikeNode = (contact.bodyA.categoryBitMask & spikeBallCategory) == spikeBallCategory ? contact.bodyA.node : contact.bodyB.node
                spikeNode?.removeFromParent()
                score += 5
                scoreLabelNode.text = String(score)
                scoreLabelNode.accessibilityLabel = String(score)
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
                applyUnicornTransform()
            } else if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Fairy has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                scoreLabelNode.accessibilityLabel = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else if isInvincible {
                bounceFairy(from: contact)
            } else {
                die()
            }
        }
    }
}

extension SKScene {
    /// Tiles and scrolls the grass foreground as a seamless looping strip.
    ///
    /// - Parameters:
    ///   - parent: The node that should contain the scrolling grass layer.
    ///   - scale: Uniform scale applied to each grass tile.
    /// - Returns: The display height of one scaled grass strip.
    @discardableResult
    func addScrollingGrass(to parent: SKNode, scale: CGFloat = 2.0) -> CGFloat {
        let texture = SKTexture(imageNamed: "grass")
        texture.filteringMode = .nearest

        let tileWidth = texture.size().width * scale
        let tileHeight = texture.size().height * scale

        let scrollNode = SKNode()
        scrollNode.name = "grassScroll"
        parent.addChild(scrollNode)

        let tileCount = Int(ceil(frame.size.width / tileWidth)) + 2
        for i in 0 ..< tileCount {
            let sprite = SKSpriteNode(texture: texture)
            sprite.anchorPoint = .zero
            sprite.setScale(scale)
            sprite.position = CGPoint(x: CGFloat(i) * tileWidth, y: 0)
            scrollNode.addChild(sprite)
        }

        let scrollDuration = TimeInterval(0.02 * tileWidth)
        let scroll = SKAction.moveBy(x: -tileWidth, y: 0, duration: scrollDuration)
        let wrap = SKAction.run { [weak scrollNode] in
            scrollNode?.position.x += tileWidth
        }
        scrollNode.run(SKAction.repeatForever(SKAction.sequence([scroll, wrap])))

        return tileHeight
    }
}
