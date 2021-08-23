//
//  GameScene.swift
//  SlicerMan
//
//  Created by Atin Agnihotri on 20/08/21.
//

import AVFoundation
import SpriteKit

enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneEnemyNoBomb, one, twoEnemyOneBomb, two, three, four, chain, fastChain
}

class GameScene: SKScene {
    
    var scoreLabel: SKLabelNode!
    var lifeImages = [SKSpriteNode]()
    var sliceBG: SKShapeNode!
    var sliceFG: SKShapeNode!
    var activeEnemies = [SKSpriteNode]()
    
    var bombSFX: AVAudioPlayer?
    
    var activeSlicePoints = [CGPoint]()
    
    var popupTime = 0.9
    var sequence = [SequenceType]()
    var sequencePosition = 0
    var chainDelay = 3.0
    var nextSequenceQueued = true
    var isGameEnded = false
    var lives = 3 {
        didSet {
            print("Setting to lives: \(lives)")
            setLives(to: lives)
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var isSwooshSoundActive = false
    
    override func didMove(to view: SKView) {
        addBackground()
        setupPhysicsWorld()
        addScoreLabel()
        addLives()
        createSlices()
        setupSequence()
    }
    
    func setupSequence() {
        sequence = [.oneEnemyNoBomb, .oneEnemyNoBomb, .twoEnemyOneBomb, .twoEnemyOneBomb, .three, .one, .chain]
        
        for _ in 0..<1000 {
            if let nextSequence = SequenceType.allCases.randomElement() {
                sequence.append(nextSequence)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tossEnemies()
        }
    }
    
    func addBackground() {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = Constants.CENTER_POINT
//        background.position = CGPoint(x: 512, y: 384)
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
            run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
            
//            for indx in (lives-1)...2 {
//                lifeImages[indx].texture = SKTexture(imageNamed: "sliceLifeGone")
//            }
            
            let lifeToChange = lifeImages[2 - lives]
            lifeToChange.texture = SKTexture(imageNamed:"sliceLifeGone")
            lifeToChange.xScale = 1.3
            lifeToChange.yScale = 1.3
            lifeToChange.run(SKAction.scale(to: 1, duration: 0.1))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGameEnded else { return }
        var bombFound = false
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombFound = true
                break
            }
        }
        
        if !bombFound {
            bombSFX?.stop()
            bombSFX = nil
        }
        
        if !activeEnemies.isEmpty && !isGameEnded {
            for (index, enemy) in activeEnemies.enumerated().reversed() {
                if enemy.position.y < -140 {
                    enemy.removeAllActions()
                    if enemy.name == "enemy" {
                        lives -= 1
                    }
                    enemy.name = ""
                    enemy.removeFromParent()
                    if !activeEnemies.isEmpty {
                        activeEnemies.remove(at: index)
                    }
                }
            }
        } else {
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [weak self] in
                    self?.tossEnemies()
                }
                
                nextSequenceQueued = true
            }
        }
        
    }
    
    func gameOver(triggeredByBomb: Bool = false) {
        guard !isGameEnded else { return }
        isGameEnded = true
        killBombSFX()
        removeActiveEnemies()
        removeHUD()
        addGameOverLabel()
        addReasonLabel(killedByBomb: triggeredByBomb)
        addFinalScoreLabel()
    }
    
    func killBombSFX() {
        bombSFX?.stop()
        bombSFX = nil
    }
    
    func addReasonLabel(killedByBomb: Bool = false) {
        let gameOver = SKLabelNode(fontNamed: "Chalkduster")
        gameOver.position = CGPoint(x: Constants.CENTER_X, y: 100)
        gameOver.zPosition = 1
        gameOver.fontSize = 48
        gameOver.horizontalAlignmentMode = .center
        gameOver.text = killedByBomb ? "Killed by a bomb" : "Ran out of lives"
        addChild(gameOver)
    }
    
    func removeActiveEnemies() {
        if !activeEnemies.isEmpty {
            for enemy in activeEnemies {
                enemy.removeFromParent()
            }
            activeEnemies.removeAll()
        }
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
        gameOver.position = Constants.CENTER_POINT
        gameOver.zPosition = 1
        gameOver.fontSize = 56
        gameOver.horizontalAlignmentMode = .center
        gameOver.text = "GAME OVER"
        addChild(gameOver)
    }
    
    func addFinalScoreLabel() {
        let finalScore = SKLabelNode(fontNamed: "Chalkduster")
        finalScore.position = CGPoint(x: Constants.CENTER_X, y: 200)
        finalScore.zPosition = 1
        finalScore.fontSize = 48
        finalScore.horizontalAlignmentMode = .center
        finalScore.text = "Final score: \(score)"
        addChild(finalScore)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
//        isSwooshSoundActive = true
        
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
        guard !isGameEnded else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
        
        checkForSlicedObjects(at: location)
        
    }
    
    func checkForSlicedObjects(at location: CGPoint) {
        let nodesAtPoint = nodes(at: location)
        
        for case let node as SKSpriteNode in nodesAtPoint {
            if node.name == "enemy" {
                hitEnemy(node: node)
            } else if node.name == "fastMover" {
                hitEnemy(node: node, isFastMover: true)
            } else if node.name == "bomb" {
                hitBomb(node: node)
            }
        }
    }
    
    func hitEnemy(node: SKSpriteNode, isFastMover: Bool = false) {
        let location = node.position
        
        node.name = ""
        node.physicsBody?.isDynamic = false
        
        node.run(getHitActionSequence())
        
        addHitFX(at: location, wasEnemy: true)
        
        if isFastMover {
            score += 5
        } else {
            score += 1
        }
        
        if let index = activeEnemies.firstIndex(of: node) {
            activeEnemies.remove(at: index)
        }
        
    }
    
    func hitBomb(node: SKSpriteNode) {
        guard let bombContainter = node.parent as? SKSpriteNode else { return }
        let location = node.position
        
        node.name = ""
        bombContainter.physicsBody?.isDynamic = false
        
        bombContainter.run(getHitActionSequence())
        
        if let index = activeEnemies.firstIndex(of: bombContainter) {
            activeEnemies.remove(at: index)
        }
        
        addHitFX(at: location, wasEnemy: false)
        
        gameOver(triggeredByBomb: true)
    }
    
    func getHitActionSequence() -> SKAction {
        let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let group = SKAction.group([scaleOut, fadeOut])
        let remove = SKAction.removeFromParent()
        return SKAction.sequence([group, remove])
    }
    
    func addHitFX(at location: CGPoint, wasEnemy: Bool) {
        let emitterFile: String
        let soundFile: String
        
        if wasEnemy {
            emitterFile = "sliceHitEnemy"
            soundFile = "whack.caf"
        } else {
            emitterFile = "sliceHitBomb"
            soundFile = "explosion.caf"
        }
        
        if let emitter = SKEmitterNode(fileNamed: emitterFile) {
            emitter.position = location
            addChild(emitter)
            
            let waitFor = SKAction.wait(forDuration: 1)
            let remove = SKAction.removeFromParent()
            let actionSequence = SKAction.sequence([waitFor, remove])
            emitter.run(actionSequence)
        }
        
        run(SKAction.playSoundFileNamed(soundFile, waitForCompletion: false))
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
    
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        run(swooshSound) { [weak self] in
            self?.isSwooshSoundActive = false
        }
    }
    
    func spawnEnemy(forceBomb: ForceBomb = .random) {
        let enemy: SKSpriteNode
        var isFastMover = false
        
        var enemyType = Int.random(in: 0...6)
        
        if forceBomb == .never {
            enemyType = 1
        } else if forceBomb == .always {
            enemyType = 0
        }
        
        if enemyType == Constants.BOMB_TYPE {
            enemy = spawnBomb()
        } else if enemyType == Constants.FAST_MOVER_TYPE {
            enemy = spawnFastMover()
            isFastMover = true
        } else {
            enemy = spawnPenguin()
        }
        
        let randomPosition = CGPoint(x: Int.random(in: Constants.ENEMY_X_MIN...Constants.ENEMY_X_MAX), y: Constants.ENEMY_Y)
        enemy.position = randomPosition
        
        let randomAngularVelocity = CGFloat.random(in: Constants.ENEMY_ANG_MIN...Constants.ENEMY_ANG_MAX)
        let randomXVelocity = getXVelocity(for: randomPosition.x)
        let randomYVelocity = Int.random(in: Constants.ENEMY_Y_VEL_MIN...Constants.ENEMY_Y_VEL_MAX)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: Constants.PHYSICS_BODY_RADIUS)
        setVelocity(for: enemy.physicsBody, dx: randomXVelocity, dy: randomYVelocity, isFastMover: isFastMover)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0 // Do it doesn't collide with anything else
//        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    func getXVelocity(for xPosition: CGFloat) -> Int {
        if xPosition < Constants.QUARTER_X {
            return Int.random(in: Constants.ENEMY_VEL_EDGES_MIN...Constants.ENEMY_VEL_EDGES_MAX)
        } else if xPosition < Constants.CENTER_X {
            return Int.random(in: Constants.ENEMY_VEL_CENTER_MIN...Constants.ENEMY_VEL_CENTER_MAX)
        } else if xPosition < Constants.THREE_QUARTER_X {
            return -Int.random(in: Constants.ENEMY_VEL_CENTER_MIN...Constants.ENEMY_VEL_CENTER_MAX)
        } else {
            return -Int.random(in: Constants.ENEMY_VEL_EDGES_MIN...Constants.ENEMY_VEL_EDGES_MAX)
        }
    }
    
    func setVelocity(for physicsBody: SKPhysicsBody?, dx: Int, dy: Int, isFastMover: Bool) {
        if isFastMover {
            physicsBody?.velocity = CGVector(dx: dx * Constants.ENEMY_VEL_FACTOR, dy: dy * Constants.ENEMY_FAST_VEL_FACTOR)
        } else {
            physicsBody?.velocity = CGVector(dx: dx * Constants.ENEMY_VEL_FACTOR, dy: dy * Constants.ENEMY_VEL_FACTOR)
        }
    }
    
    func spawnPenguin() -> SKSpriteNode {
        let enemy = SKSpriteNode(imageNamed: "penguin")
        run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
        enemy.name = "enemy"
        return enemy
    }
    
    func spawnBomb() -> SKSpriteNode {
        let enemy = SKSpriteNode()
        enemy.zPosition = 1
        enemy.name = "bombContainer"
        
        let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
        bombImage.name = "bomb"
        enemy.addChild(bombImage)
        
        if bombSFX != nil {
            bombSFX?.stop()
            bombSFX = nil
        }
        
        if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf") {
            if let sound = try? AVAudioPlayer(contentsOf: path) {
                bombSFX = sound
                sound.play()
            }
        }
        
        if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
            emitter.position = CGPoint(x: Constants.EMITTER_X, y: Constants.EMITTER_Y)
            enemy.addChild(emitter)
        }


        return enemy
    }
    
    func spawnFastMover() -> SKSpriteNode {
        let enemy = SKSpriteNode(imageNamed: "penguin")
        enemy.colorBlendFactor = 1
        enemy.color = .red
        run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
        enemy.name = "fastMover"
        return enemy
    }
    
    func tossEnemies() {
        // slowly ramp up the game speed
        rampUpGameSpeed()
        
        let sequenceType: SequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .oneEnemyNoBomb:
            spawnEnemy(forceBomb: .never)
        case .one:
            spawnEnemies(numberOf: 1)
        case .twoEnemyOneBomb:
            spawnEnemy(forceBomb: .never)
            spawnEnemy(forceBomb: .always)
        case .two:
            spawnEnemies(numberOf: 2)
        case .three:
            spawnEnemies(numberOf: 3)
        case .four:
            spawnEnemies(numberOf: 4)
        case .chain:
            spawnEnemyChain()
        case .fastChain:
            spawnEnemyChain(isFast: true)
        }
        
        if sequencePosition < sequence.count - 1 {
            sequencePosition += 1
        } else  {
            sequencePosition = 5
        }
        nextSequenceQueued = false
    }
    
    func rampUpGameSpeed() {
        popupTime *= Constants.POPUP_DECREASE_FACTOR
        chainDelay *= Constants.CHAIN_DELAY_DECREASE_FACTOR
        physicsWorld.speed *= Constants.SIMULATION_SPEED_INCREASE_FACTOR
    }
    
    func spawnEnemies(numberOf enemies: Int) {
        for _ in 0..<enemies {
            spawnEnemy()
        }
    }
    
    func spawnEnemyChain(isFast: Bool = false) {
        let divFactor: Double
        if isFast {
            divFactor = 10
        } else {
            divFactor = 5
        }
        
        spawnEnemy()
        DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / divFactor)) { [weak self] in
            self?.spawnEnemy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / divFactor * 2)) { [weak self] in
            self?.spawnEnemy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / divFactor * 3)) { [weak self] in
            self?.spawnEnemy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / divFactor * 4)) { [weak self] in
            self?.spawnEnemy()
        }
    }
}
