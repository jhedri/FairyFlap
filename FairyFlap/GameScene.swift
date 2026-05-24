//
//  GameScene.swift
//  FairyFlap
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    
    var bird:SKSpriteNode!
    var skyColor:SKColor!
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var movePipesAndRemove:SKAction!
    var moving:SKNode!
    var pipes:SKNode!
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    var highScoreLabelNode:SKLabelNode!
    var score = 0
    var groundHeight: CGFloat = 0
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let verticalPipeGap: CGFloat = 150.0
    
    override func sceneDidLoad() {
        self.physicsBody = nil
    }

    override func didMove(to view: SKView) {
        
        canRestart = true
        
        // setup physics
        self.physicsBody = nil
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
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
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        let skyTileWidth = skyTexture.size().width * 2.0
        let skyTileCount = Int(ceil(Double(self.frame.size.width) / Double(skyTileWidth))) + 3
        for i in 0 ..< skyTileCount {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // create the pipes movement actions
        let scaledPipeWidth = pipeTextureUp.size().width * 2.0
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * scaledPipeWidth)
        let duration = TimeInterval(0.01 * distanceToMove)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: duration)
        let waitBeforeFade = SKAction.wait(forDuration: duration * 0.7)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.3)
        let moveAndFade = SKAction.group([movePipes, SKAction.sequence([waitBeforeFade, fadeOut])])
        movePipesAndRemove = SKAction.sequence([moveAndFade, SKAction.removeFromParent()])
        
        // spawn the pipes
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        // setup our bird
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(1.5)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.run(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
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
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
        pipePair.zPosition = -10
        
        let pipeUpHeight = pipeTextureUp.size().height * 2.0
        // maxPipeY keeps the pipe bottom flush with the ground; vary downward for difficulty
        let maxPipeY = groundHeight + pipeUpHeight / 2
        let variation = UInt32(self.frame.size.height / 4)
        let y = CGFloat(UInt32.random(in: 0..<variation)) + (maxPipeY - CGFloat(variation))
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + pipeDown.size.height + verticalPipeGap)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
        
    }
    
    func resetScene (){
        // Move bird to original position and reset velocity
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
    }
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

    func goHome() {
        let scene = HomeScene(size: self.size)
        scene.scaleMode = self.scaleMode
        self.view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0 {
            for _ in touches {
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 13.5))
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
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        let dy = bird.physicsBody!.velocity.dy
        let value = dy * (dy < 0 ? 0.003 : 0.001)
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {
                
                moving.speed = 0
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(SKAction.rotate(byAngle: .pi * bird.position.y * 0.01, duration: 1), completion: { self.bird.speed = 0 })
                
                
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
                        self.backgroundColor = self.skyColor
                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                            self.canRestart = true
                            self.showDeathOverlay()
                            })]), withKey: "flash")
            }
        }
    }
}

