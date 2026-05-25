//
//  HomeScene.swift
//  FairyFlap
//

import SpriteKit

/// The title / menu scene shown at launch. Displays the last score, best score,
/// a play button, and an animated preview of the fairy over the scrolling forest.
class HomeScene: SKScene {

    let sceneBackgroundColor = SKColor(red: 120.0/255.0, green: 170.0/255.0, blue: 200.0/255.0, alpha: 1.0)
    let backgroundScrollSpeed: CGFloat = 0.35
    var backgroundMoving: SKNode!
    var moving: SKNode!

    /// Builds the home screen when the scene is presented: background layers,
    /// animated fairy preview, and UI (title, scores, play button).
    override func didMove(to view: SKView) {
        self.backgroundColor = sceneBackgroundColor

        backgroundMoving = SKNode()
        backgroundMoving.speed = backgroundScrollSpeed
        self.addChild(backgroundMoving)

        moving = SKNode()
        self.addChild(moving)

        setupScrollingBackground()
        setupFairyPreview()
        setupUI()
    }

    // MARK: - Scrolling Background

    /// Creates the parallax scrolling ground (foreground) and forest (background).
    /// The forest scrolls at 35% speed to give a sense of depth.
    private func setupScrollingBackground() {
        let groundH = addScrollingGrass(to: moving)

        let forestTexture = SKTexture(imageNamed: "forest")
        forestTexture.filteringMode = .nearest

        let forestXScale: CGFloat = 2.0
        let forestDisplayHeight = self.frame.size.height - groundH
        let forestYScale = forestDisplayHeight / forestTexture.size().height
        let forestTileWidth = forestTexture.size().width * forestXScale

        let moveForest = SKAction.moveBy(x: -forestTileWidth, y: 0,
                                         duration: TimeInterval(0.02 * forestTileWidth))
        let resetForest = SKAction.moveBy(x: forestTileWidth, y: 0, duration: 0)
        let forestLoop = SKAction.repeatForever(SKAction.sequence([moveForest, resetForest]))

        let forestTileCount = Int(ceil(Double(self.frame.size.width) / Double(forestTileWidth))) + 3
        for i in 0..<forestTileCount {
            let sprite = SKSpriteNode(texture: forestTexture)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
            sprite.xScale = forestXScale
            sprite.yScale = forestYScale
            sprite.zPosition = -20
            sprite.position = CGPoint(x: CGFloat(i) * forestTileWidth + forestTileWidth / 2.0, y: groundH)
            sprite.run(forestLoop)
            backgroundMoving.addChild(sprite)
        }
    }

    // MARK: - Fairy Preview

    /// Adds an animated fairy in the center of the screen that flaps and bobs
    /// up and down as a preview of the in-game character.
    private func setupFairyPreview() {
        let tex1 = SKTexture(imageNamed: "fairy-01")
        tex1.filteringMode = .nearest
        let tex2 = SKTexture(imageNamed: "fairy-02")
        tex2.filteringMode = .nearest

        let fairy = SKSpriteNode(texture: tex1)
        fairy.setScale(2.0)
        fairy.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 30)
        fairy.zPosition = 10

        let flap = SKAction.repeatForever(SKAction.animate(with: [tex1, tex2], timePerFrame: 0.2))
        let bob = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: 12, duration: 0.6),
                SKAction.moveBy(x: 0, y: -12, duration: 0.6)
            ])
        )
        fairy.run(flap)
        fairy.run(bob)
        self.addChild(fairy)
    }

    // MARK: - UI Labels & Button

    /// Builds the home screen UI: title, last and best score labels, pulsing play button,
    /// and a blinking "tap anywhere to start" hint.
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

        // Last score
        let lastScore = UserDefaults.standard.integer(forKey: "lastScore")
        let lastLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        lastLabel.text = "Last Score: \(lastScore)"
        lastLabel.fontSize = 26
        lastLabel.fontColor = .white
        lastLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.70)
        lastLabel.zPosition = 20
        self.addChild(lastLabel)

        // Best score
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        let bestLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        bestLabel.text = "Top Score: \(highScore)"
        bestLabel.fontSize = 26
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        bestLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height * 0.63)
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

    /// Any tap on the home screen starts the game.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        transitionToGame()
    }

    /// Fades from the home screen into a new `GameScene`.
    private func transitionToGame() {
        let scene = GameScene(size: self.size)
        scene.scaleMode = self.scaleMode
        let transition = SKTransition.fade(withDuration: 0.4)
        self.view?.presentScene(scene, transition: transition)
    }
}
