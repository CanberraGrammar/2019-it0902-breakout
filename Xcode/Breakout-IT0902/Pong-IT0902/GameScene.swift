//
//  GameScene.swift
//  Pong-IT0902
//
//  Created by MPP on 9/9/19.
//  Copyright © 2019 Matthew Purcell. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let BallCategory: UInt32 = 0x1 << 0
    let BottomCategory: UInt32 = 0x1 << 2
    let BrickCategory: UInt32 = 0x1 << 3
        
    var bottomPaddle: SKSpriteNode!
    var fingerOnBottomPaddle: Bool = false
    var bottomScoreLabel: SKLabelNode!
    
    var ball: SKSpriteNode!
    
    var gameRunning: Bool = false
    
    var topScore = 0
    var bottomScore = 0
    
    var numberOfBricks = 6
    var hitCount = 0
       
    override func didMove(to view: SKView) {
        
        bottomPaddle = childNode(withName: "bottomPaddle") as? SKSpriteNode
        bottomPaddle.physicsBody = SKPhysicsBody(rectangleOf: bottomPaddle.frame.size)
        bottomPaddle.physicsBody!.isDynamic = false
        
        bottomScoreLabel = childNode(withName: "bottomScoreLabel") as? SKLabelNode
        
        ball = childNode(withName: "ball") as? SKSpriteNode
        ball.physicsBody = SKPhysicsBody(rectangleOf: ball.frame.size)
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.friction = 0
        ball.physicsBody!.linearDamping = 0
        ball.physicsBody!.angularDamping = 0
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody!.contactTestBitMask = BottomCategory
        ball.physicsBody!.allowsRotation = false
                
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        let bottomNode = SKNode()
        let bottomLeftPoint = CGPoint(x: -(self.size.width / 2), y: -(self.size.height / 2))
        let bottomRightPoint = CGPoint(x: self.size.width / 2, y: -(self.size.height / 2))
        bottomNode.physicsBody = SKPhysicsBody(edgeFrom: bottomLeftPoint, to: bottomRightPoint)
        bottomNode.physicsBody!.categoryBitMask = BottomCategory
        self.addChild(bottomNode)
        
        // Generate the bricks
        generateBricks(numberOfBricks)
                
        /* let testNode = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        testNode.position = CGPoint(x: 100, y: 200)
        self.addChild(testNode) */
        
    }
    
    func generateBricks(_ numberOfBricks: Int) {
        
        let brickWidth = self.size.width / CGFloat(numberOfBricks)
        
        for i in 0..<numberOfBricks {
            
            let xCoordinate = (CGFloat(i) * brickWidth) - (self.size.width / 2) + (brickWidth / 2)
            
            let brickColor = (i % 2 == 0 ? UIColor.blue : UIColor.red)
            let brickNode = SKSpriteNode(color: brickColor, size: CGSize(width: brickWidth, height: 25))
            brickNode.position = CGPoint(x: xCoordinate, y: (self.size.height / 2 - 100))
            
            brickNode.physicsBody = SKPhysicsBody(rectangleOf: brickNode.size)
            brickNode.physicsBody!.isDynamic = false
            brickNode.physicsBody!.categoryBitMask = BrickCategory
            brickNode.physicsBody!.contactTestBitMask = BallCategory
            brickNode.name = "brick"
            
            self.addChild(brickNode)
            
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first!
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
                
        if touchedNode.name == "bottomPaddle" {
            fingerOnBottomPaddle = true
        }
        
        if gameRunning == false {
            
            // Generate a random number between 0 and 1 (inclusive)
            let randomNumber = Int(arc4random_uniform(2))
            
            if randomNumber == 0 {
            
                // Apply an impulse to the ball
                ball.physicsBody!.applyImpulse(CGVector(dx: 10, dy: 10))
                
            }
            
            else {
                
                ball.physicsBody!.applyImpulse(CGVector(dx: -10, dy: -10))
                
            }
            
            gameRunning = true
            
        }
                
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first!
        let touchLocation = touch.location(in: self)
        let previousTouchLocation = touch.previousLocation(in: self)
                
        let distanceToMove = touchLocation.x - previousTouchLocation.x
                
        if fingerOnBottomPaddle && touchLocation.y < 0 {
         
            let paddleNewX = bottomPaddle.position.x + distanceToMove
            
            if (paddleNewX - bottomPaddle.size.width / 2) > -(self.size.width / 2) && (paddleNewX + bottomPaddle.size.width / 2 < (self.size.width / 2)) {
            
                bottomPaddle.position.x = paddleNewX
                
            }
            
        }
                
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
                
        if fingerOnBottomPaddle {
            fingerOnBottomPaddle = false
        }
        
    }
    
    func resetGame() {
        
        // Reset the ball - center of the screen
        ball.position.x = 0
        ball.position.y = 0
        
        // Reset the paddles to their original location
        bottomPaddle.position.x = 0
        
        // Stop the ball from moving
        ball.physicsBody!.isDynamic = false
        ball.physicsBody!.isDynamic = true
        
        // Alternative way to stop the ball from moving
        // ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
        
        // Remove all remaining bricks from the scene
        self.enumerateChildNodes(withName: "brick") { (brickNode, finished) in
            brickNode.removeFromParent()
        }
                
        // Regenerate a new set of bricks
        generateBricks(numberOfBricks)
        
        // Reset the hitCount
        hitCount = 0
        
        // Unpause the view
        self.view!.isPaused = false
        
    }
    
    func gameOver(playerWon: Bool) {
        
        // Pause the game
        self.view!.isPaused = true
        self.gameRunning = false
        
        // Create a default message
        var winMessage = "You lost :("
        
        // The player has won
        if playerWon {
            winMessage = "You won :)"
            bottomScore += 1
            bottomScoreLabel.text = String(bottomScore)
        }
        
        // Show an alert
        let gameOverAlert = UIAlertController(title: "Game Over", message: winMessage, preferredStyle: .alert)
        let gameOverAction = UIAlertAction(title: "Okay", style: .default) { (theAlertAction) in
            
            // Reset game
            self.resetGame()
            
        }
        
        gameOverAlert.addAction(gameOverAction)
        
        self.view!.window!.rootViewController!.present(gameOverAlert, animated: true, completion: nil)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if (contact.bodyA.categoryBitMask == BottomCategory) || (contact.bodyB.categoryBitMask == BottomCategory) {
            
            print("Bottom collision")
                        
            gameOver(playerWon: false)
            
        }
        
        else if (contact.bodyA.categoryBitMask == BrickCategory) {
            
            contact.bodyA.node!.removeFromParent()
            hitCount += 1
            
        }
        
        else if (contact.bodyB.categoryBitMask == BrickCategory) {
            
            contact.bodyB.node!.removeFromParent()
            hitCount += 1
            
        }
        
        // Check if the player has won
        if hitCount == numberOfBricks {
            
            gameOver(playerWon: true)
            
        }
        
    }
    
}
