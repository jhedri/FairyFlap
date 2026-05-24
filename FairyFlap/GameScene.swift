//
//  GameScene.swift
//  FairyFlap
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

/// The main gameplay scene. Handles the fairy, scrolling world, stone obstacles,
/// scoring, collisions, and game-over / restart flow.
class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    
    var fairy:SKSpriteNode!
    var sceneBackgroundColor:SKColor!
    var stoneTextureUp:SKTexture!
    var stoneTextureDown:SKTexture!
    var moveStonesAndRemove:SKAction!
    var backgroundMoving:SKNode!
    var moving:SKNode!
    var stones:SKNode!
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    var highScoreLabelNode:SKLabelNode!
    var score = 0
    var groundHeight: CGFloat = 0
    
    let backgroundScrollSpeed: CGFloat = 0.35
    
    let fairyCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let stoneCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let verticalStoneGap: CGFloat = 150.0
    
    /// Called when the scene is first loaded from the .sks file. Clears any
    /// default physics body so we can configure physics in `didMove(to:)`.
    override func sceneDidLoad() {
        self.physicsBody = nil
    }

    /// Sets up the entire game when the scene is presented: physics, parallax
    /// scrolling background, ground, fairy, score labels, and stone spawning.
    override func didMove(to view: SKView) {
        
        canRestart = true
        
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
        
        // ground (foreground — scrolls at full speed)
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        groundHeight = groundTexture.size().height * 2.0
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
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
        
        // setup our fairy
        let fairyTexture1 = SKTexture(imageNamed: "fairy-01")
        fairyTexture1.filteringMode = .nearest
        let fairyTexture2 = SKTexture(imageNamed: "fairy-02")
        fairyTexture2.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [fairyTexture1, fairyTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        fairy = SKSpriteNode(texture: fairyTexture1)
        fairy.setScale(1.5)
        fairy.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        fairy.run(flap)
        
        
        fairy.physicsBody = SKPhysicsBody(circleOfRadius: fairy.size.height / 2.0)
        fairy.physicsBody?.isDynamic = true
        fairy.physicsBody?.allowsRotation = false
        
        fairy.physicsBody?.categoryBitMask = fairyCategory
        fairy.physicsBody?.collisionBitMask = worldCategory | stoneCategory
        fairy.physicsBody?.contactTestBitMask = worldCategory | stoneCategory
        
        self.addChild(fairy)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Score label
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)

        // High score label (top-right)
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        highScoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        highScoreLabelNode.position = CGPoint(x: self.frame.size.width - 12, y: 3 * self.frame.size.height / 4 - 32)
        highScoreLabelNode.horizontalAlignmentMode = .right
        highScoreLabelNode.zPosition = 100
        highScoreLabelNode.fontSize = 18
        highScoreLabelNode.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        highScoreLabelNode.text = "Best: \(highScore)"
        self.addChild(highScoreLabelNode)
        
    }
    
    /// Creates a new pair of top/bottom stone obstacles with a random gap height,
    /// plus an invisible score trigger between them, and scrolls them off-screen.
    func spawnStones() {
        let stonePair = SKNode()
        stonePair.position = CGPoint( x: self.frame.size.width + stoneTextureUp.size().width * 2, y: 0 )
        stonePair.zPosition = -10
        
        let stoneUpHeight = stoneTextureUp.size().height * 2.0
        // maxStoneY keeps the stone bottom flush with the ground; vary downward for difficulty
        let maxStoneY = groundHeight + stoneUpHeight / 2
        let variation = UInt32(self.frame.size.height / 4)
        let y = CGFloat(UInt32.random(in: 0..<variation)) + (maxStoneY - CGFloat(variation))
        
        let stoneDown = SKSpriteNode(texture: stoneTextureDown)
        stoneDown.setScale(2.0)
        stoneDown.position = CGPoint(x: 0.0, y: y + stoneDown.size.height + verticalStoneGap)
        
        stoneDown.physicsBody = SKPhysicsBody(rectangleOf: stoneDown.size)
        stoneDown.physicsBody?.isDynamic = false
        stoneDown.physicsBody?.categoryBitMask = stoneCategory
        stoneDown.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(stoneDown)
        
        let stoneUp = SKSpriteNode(texture: stoneTextureUp)
        stoneUp.setScale(2.0)
        stoneUp.position = CGPoint(x: 0.0, y: y)
        
        stoneUp.physicsBody = SKPhysicsBody(rectangleOf: stoneUp.size)
        stoneUp.physicsBody?.isDynamic = false
        stoneUp.physicsBody?.categoryBitMask = stoneCategory
        stoneUp.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(stoneUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: stoneDown.size.width + fairy.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: stoneUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = fairyCategory
        stonePair.addChild(contactNode)
        
        stonePair.run(moveStonesAndRemove)
        stones.addChild(stonePair)
    }
    
    /// Resets the game to its starting state after the player chooses to replay:
    /// repositions the fairy, clears stones, zeroes the score, and resumes scrolling.
    func resetScene (){
        // Move fairy to original position and reset velocity
        fairy.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        fairy.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        fairy.physicsBody?.collisionBitMask = worldCategory | stoneCategory
        fairy.speed = 1.0
        fairy.zRotation = 0.0
        
        // Remove all existing stones
        stones.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
        backgroundMoving.speed = backgroundScrollSpeed
    }
    /// Displays the game-over overlay with the final score, best score,
    /// and buttons to replay or return to the home screen.
    func showDeathOverlay() {
        let overlay = SKNode()
        overlay.name = "deathOverlay"
        overlay.zPosition = 200

        // Score card background
        let card = SKShapeNode(rectOf: CGSize(width: 260, height: 180), cornerRadius: 18)
        card.fillColor = SKColor(white: 0, alpha: 0.55)
        card.strokeColor = SKColor(white: 1, alpha: 0.3)
        card.lineWidth = 2
        card.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 20)
        overlay.addChild(card)

        let finalScore = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        finalScore.text = "Score: \(score)"
        finalScore.fontSize = 32
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 55)
        overlay.addChild(finalScore)

        let best = UserDefaults.standard.integer(forKey: "highScore")
        let bestLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        bestLabel.text = "Best: \(best)"
        bestLabel.fontSize = 22
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        bestLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 18)
        overlay.addChild(bestLabel)

        // Replay button
        let replayBtn = SKShapeNode(rectOf: CGSize(width: 110, height: 50), cornerRadius: 25)
        replayBtn.fillColor = SKColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1.0)
        replayBtn.strokeColor = .white
        replayBtn.lineWidth = 2
        replayBtn.position = CGPoint(x: self.frame.midX - 65, y: self.frame.midY - 30)
        replayBtn.name = "replayBtn"
        overlay.addChild(replayBtn)

        let replayLbl = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        replayLbl.text = "↩ Play"
        replayLbl.fontSize = 20
        replayLbl.fontColor = .white
        replayLbl.verticalAlignmentMode = .center
        replayLbl.name = "replayBtn"
        replayBtn.addChild(replayLbl)

        // Home button
        let homeBtn = SKShapeNode(rectOf: CGSize(width: 110, height: 50), cornerRadius: 25)
        homeBtn.fillColor = SKColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1.0)
        homeBtn.strokeColor = .white
        homeBtn.lineWidth = 2
        homeBtn.position = CGPoint(x: self.frame.midX + 65, y: self.frame.midY - 30)
        homeBtn.name = "homeBtn"
        overlay.addChild(homeBtn)

        let homeLbl = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        homeLbl.text = "⌂ Home"
        homeLbl.fontSize = 20
        homeLbl.fontColor = .white
        homeLbl.verticalAlignmentMode = .center
        homeLbl.name = "homeBtn"
        homeBtn.addChild(homeLbl)

        self.addChild(overlay)
    }

    /// Transitions back to the home screen with a fade animation.
    func goHome() {
        let scene = HomeScene(size: self.size)
        scene.scaleMode = self.scaleMode
        self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    /// Handles tap input: flaps the fairy during gameplay, or after death
    /// restarts the game or navigates home depending on which button was tapped.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0 {
            for _ in touches {
                fairy.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                fairy.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 13.5))
            }
        } else if canRestart {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let nodes = self.nodes(at: location)
            if nodes.contains(where: { $0.name == "homeBtn" }) {
                goHome()
            } else {
                self.childNode(withName: "deathOverlay")?.removeFromParent()
                self.resetScene()
            }
        }
    }
    
    /// Called every frame. Tilts the fairy sprite based on vertical velocity
    /// so it pitches up while rising and down while falling.
    override func update(_ currentTime: TimeInterval) {
        let dy = fairy.physicsBody!.velocity.dy
        let value = dy * (dy < 0 ? 0.003 : 0.001)
        fairy.zRotation = min( max(-1, value), 0.5 )
    }
    
    /// Physics contact handler. Increments score when the fairy passes through
    /// a gap, or triggers death (stop scrolling, save high score, show overlay)
    /// when the fairy hits a stone or the ground.
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Fairy has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {
                
                moving.speed = 0
                backgroundMoving.speed = 0
                
                fairy.physicsBody?.collisionBitMask = worldCategory
                fairy.run(SKAction.rotate(byAngle: .pi * fairy.position.y * 0.01, duration: 1), completion: { self.fairy.speed = 0 })
                
                
                // Save high score
                let currentBest = UserDefaults.standard.integer(forKey: "highScore")
                if self.score > currentBest {
                    UserDefaults.standard.set(self.score, forKey: "highScore")
                    self.highScoreLabelNode.text = "Best: \(self.score)"
                }

                // Flash background if contact is detected
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                        self.backgroundColor = self.sceneBackgroundColor
                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                            self.canRestart = true
                            self.showDeathOverlay()
                            })]), withKey: "flash")
            }
        }
    }
}

