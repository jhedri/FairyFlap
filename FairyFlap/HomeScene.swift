//
//  HomeScene.swift
//  FairyFlap
//

import SpriteKit

class HomeScene: SKScene {

    let skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    var moving: SKNode!

    override func didMove(to view: SKView) {
        self.backgroundColor = skyColor

        moving = SKNode()
        self.addChild(moving)

        setupScrollingBackground()
        setupBirdPreview()
        setupUI()
    }

    // MARK: - Scrolling Background

    private func setupScrollingBackground() {
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        let groundH = groundTexture.size().height * 2.0

        let moveGround = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0,
                                         duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGround = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0)
        let groundLoop = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        let tileCount = 2 + Int(self.frame.size.width / (groundTexture.size().width * 2))
        for i in 0..<tileCount {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(groundLoop)
            moving.addChild(sprite)
        }

        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest

        let moveSky = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0,
                                      duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSky = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0)
        let skyLoop = SKAction.repeatForever(SKAction.sequence([moveSky, resetSky]))

        let skyTileWidth = skyTexture.size().width * 2.0
        let skyTileCount = Int(ceil(Double(self.frame.size.width) / Double(skyTileWidth))) + 3
        for i in 0..<skyTileCount {
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width,
                                      y: sprite.size.height / 2.0 + groundH)
            sprite.run(skyLoop)
            moving.addChild(sprite)
        }
    }

    // MARK: - Bird Preview

    private func setupBirdPreview() {
        let tex1 = SKTexture(imageNamed: "bird-01")
        tex1.filteringMode = .nearest
        let tex2 = SKTexture(imageNamed: "bird-02")
        tex2.filteringMode = .nearest

        let bird = SKSpriteNode(texture: tex1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 30)
        bird.zPosition = 10

        let flap = SKAction.repeatForever(SKAction.animate(with: [tex1, tex2], timePerFrame: 0.2))
        let bob = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: 12, duration: 0.6),
                SKAction.moveBy(x: 0, y: -12, duration: 0.6)
            ])
        )
        bird.run(flap)
        bird.run(bob)
        self.addChild(bird)
    }

    // MARK: - UI Labels & Button

    private func setupUI() {
        // Title
        let title = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        title.text = "Fairy Flap"
        title.fontSize = 52
        title.fontColor = .white
        title.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.78)
        title.zPosition = 20

        let shadowTitle = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        shadowTitle.text = "Fairy Flap"
        shadowTitle.fontSize = 52
        shadowTitle.fontColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        shadowTitle.position = CGPoint(x: self.frame.midX + 3, y: self.frame.height * 0.78 - 3)
        shadowTitle.zPosition = 19
        self.addChild(shadowTitle)
        self.addChild(title)

        // High score
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        let bestLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        bestLabel.text = "Best: \(highScore)"
        bestLabel.fontSize = 26
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        bestLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.70)
        bestLabel.zPosition = 20
        self.addChild(bestLabel)

        // Play button background
        let buttonBg = SKShapeNode(rectOf: CGSize(width: 200, height: 64), cornerRadius: 32)
        buttonBg.fillColor = SKColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1.0)
        buttonBg.strokeColor = .white
        buttonBg.lineWidth = 3
        buttonBg.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.25)
        buttonBg.zPosition = 20
        buttonBg.name = "playButton"
        self.addChild(buttonBg)

        let playLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        playLabel.text = "▶  PLAY"
        playLabel.fontSize = 30
        playLabel.fontColor = .white
        playLabel.verticalAlignmentMode = .center
        playLabel.position = .zero
        playLabel.zPosition = 1
        playLabel.name = "playButton"
        buttonBg.addChild(playLabel)

        // Pulse the button
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ]))
        buttonBg.run(pulse)

        // Tap hint
        let hint = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        hint.text = "tap anywhere to start"
        hint.fontSize = 16
        hint.fontColor = SKColor(white: 1.0, alpha: 0.7)
        hint.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.16)
        hint.zPosition = 20

        let blink = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.7),
            SKAction.fadeAlpha(to: 0.9, duration: 0.7)
        ]))
        hint.run(blink)
        self.addChild(hint)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        transitionToGame()
    }

    private func transitionToGame() {
        let scene = GameScene(size: self.size)
        scene.scaleMode = self.scaleMode
        let transition = SKTransition.fade(withDuration: 0.4)
        self.view?.presentScene(scene, transition: transition)
    }
}
