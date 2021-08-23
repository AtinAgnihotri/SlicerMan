//
//  GameScene.swift
//  SlicerMan
//
//  Created by Atin Agnihotri on 20/08/21.
//

import SpriteKit

class GameScene: SKScene {
    
    var scoreLabel: SKLabelNode!
    var lifeImages = [SKSpriteNode]()
    var sliceBG: SKShapeNode!
    var sliceFG: SKShapeNode!
    
    var activeSlicePoints = [CGPoint]()
    
    var lives = 3 {
        didSet {
            setLives(to: lives)
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        addBackground()
        setupPhysicsWorld()
        addScoreLabel()
        addLives()
        createSlices()
    }
    
    func addBackground() {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.zPosition = -1
        background.blendMode = .replace
        addChild(background)
    }
    
    func setupPhysicsWorld() {
        // Slightly slower gravity accelaration and simulation speed to give player time to react
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
    }
    
    func addScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontSize = 48
        scoreLabel.position = CGPoint(x: 20, y: 700)
        scoreLabel.zPosition = 1
        score = 0
        addChild(scoreLabel)
    }
    
    func addLives() {
        for i in 0...2 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            let xPos = CGFloat(834 + (i * 70))
            spriteNode.position = CGPoint(x: xPos, y: 720)
            spriteNode.zPosition = 1
            addChild(spriteNode)
            lifeImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        sliceBG = SKShapeNode()
        sliceFG = SKShapeNode()
        
        sliceBG.zPosition = 2
        sliceFG.zPosition = 3
        
        sliceBG.strokeColor = .orange
        sliceFG.strokeColor = .white
        
        sliceBG.lineWidth = 9
        sliceFG.lineWidth = 5
        
        addChild(sliceBG)
        addChild(sliceFG)
    }
    
    func setLives(to lives: Int) {
        if lives == 0 {
            gameOver()
        } else {
            for indx in (lives-1)...2 {
                lifeImages[indx].texture = SKTexture(imageNamed: "sliceLifeGone")
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func gameOver() {
        removeHUD()
        addGameOverLabel()
        addFinalScoreLabel()
    }
    
    func removeHUD() {
        // Remove score label
        scoreLabel.removeFromParent()
        
        // Remove Life images
        for image in lifeImages {
            image.removeFromParent()
        }
    }
    
    func addGameOverLabel() {
        let gameOver = SKLabelNode(fontNamed: "Chalkduster")
        gameOver.position = CGPoint(x: 512, y: 384)
        gameOver.zPosition = 1
        gameOver.fontSize = 56
        gameOver.horizontalAlignmentMode = .center
        gameOver.text = "GAME OVER"
        addChild(gameOver)
    }
    
    func addFinalScoreLabel() {
        let finalScore = SKLabelNode(fontNamed: "Chalkduster")
        finalScore.position = CGPoint(x: 512, y: 200)
        finalScore.zPosition = 1
        finalScore.fontSize = 48
        finalScore.horizontalAlignmentMode = .center
        finalScore.text = "Final score: \(score)"
        addChild(finalScore)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        
        sliceBG.removeAllActions()
        sliceFG.removeAllActions()
        
        sliceBG.alpha = 1
        sliceFG.alpha = 1
        
        redrawActiveSlice()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        sliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        sliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    func redrawActiveSlice() {
        if activeSlicePoints.count < 2 {
            sliceBG.path = nil
            sliceFG.path = nil
            
            return
        }
        
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1..<activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        sliceBG.path = path.cgPath
        sliceFG.path = path.cgPath
    }
}
