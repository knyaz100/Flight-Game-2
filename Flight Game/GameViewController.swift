//
//  GameViewController.swift
//  Flight Game
//
//  Created by Vasily Churbanov on 2021-01-21.
//

import SceneKit
import AVFoundation

class GameViewController: UIViewController {
    
    // MARK: - Outlets
    let scoreLabel = UILabel()
    let restartButton = UIButton()
    let highScoreLabel = UILabel()
    let resetHSButton = UIButton()
    
    // MARK: - Stored Properties
    var duration: TimeInterval = 10
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var highScore = 0 {
        didSet {
            highScoreLabel.text = "High Score: \(highScore)"
        }
    }
    
    let cameraNode = SCNNode()
    var initialPointOfView = SCNNode()
    var initialCameraPointOfView = SCNNode()
    var initialShipOrientation = SCNVector4()
    var runCount = 0
    
    var isGameOver = false
    
    // MARK: - Computed Properties
    var scene: SCNScene? {
        (view as! SCNView).scene!
    }
        
    var ship: SCNNode? {
        scene?.rootNode.childNode(withName: "ship", recursively: true)
    }
    
    
    // MARK: - Methods
    
    fileprivate func addLabels() {
        
        scoreLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFont.systemFont(ofSize: 30)
        scoreLabel.textColor = .white
        scoreLabel.numberOfLines = 2
        view.addSubview(scoreLabel)
        score = 0
        
        highScoreLabel.frame = CGRect(x: 2, y: -15, width: view.bounds.width, height: 50)
        highScoreLabel.textAlignment = .left
        highScoreLabel.font = UIFont.systemFont(ofSize: 15)
        highScoreLabel.textColor = .green
        highScoreLabel.numberOfLines = 1
        view.addSubview(highScoreLabel)
        highScore = getHighScore()
        
    }
    
    fileprivate func addRestartButton(){
        restartButton.frame = CGRect(x: 0, y: view.bounds.maxY-50, width: view.bounds.width, height: 30)
        restartButton.setTitle("RESTART", for: UIControl.State())
        restartButton.addTarget(self, action:#selector(restartButtonPressed), for: UIControl.Event.touchUpInside)
        view.addSubview(restartButton)
    }
    
    fileprivate func addResetHSButton(){
        resetHSButton.frame = CGRect(x: 0, y: view.bounds.maxY-20, width: view.bounds.width, height: 20)
        resetHSButton.setTitle("reset high score", for: UIControl.State())
        
        resetHSButton.setTitleColor(UIColor(ciColor: .green), for: UIControl.State())
        resetHSButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        resetHSButton.addTarget(self, action:#selector(resetHSButtonPressed), for: UIControl.Event.touchUpInside)
        view.addSubview(resetHSButton)
    }
    
    @objc func resetHSButtonPressed(Sender: UIButton! ) {
        self.resetHighScore()
    }
    
    @objc func restartButtonPressed(Sender: UIButton! ) {
        score = 0
        duration = 10
        runCount += 1
        addShip()
    }
    
    fileprivate func addShip() {
        
        //add ship and scene additional initialization
        self.isGameOver = false
        self.restartButton.isHidden = true
        self.resetHSButton.isHidden = true
        
        let scnView = self.view as! SCNView
        scnView.allowsCameraControl = false
        
        
        //set ship position
        let x = Int.random(in: -30 ... 30)
        let y = Int.random(in: -30 ... 30)
        let z = -95
        
        ship?.position = SCNVector3(x, y, z)
        
        //remove previous ship animation
        ship?.removeAllActions()
        
        // replace the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        //restore initial point of view and ship orientation
        scnView.pointOfView = initialPointOfView
        ship?.orientation = initialShipOrientation
        
        ship?.look(at: SCNVector3(2 * x, 2 * y, 2 * z))
        
        
        //animate ship
        ship?.runAction(SCNAction.move(to: SCNVector3(), duration: duration)) {
            DispatchQueue.main.async {
                self.scoreLabel.text = "GAME OVER\nScore: \(self.score)"
                self.setHighScore(newHighScore: self.score)
                self.isGameOver = true
                // to play sound
                AudioServicesPlaySystemSound (1027)
                self.ship?.runAction(SCNAction.rotate(by: CGFloat(10*Double.pi), around: SCNVector3(x: 0, y: 0, z: 1), duration: 3))
                scnView.allowsCameraControl = true
                self.restartButton.isHidden = false
                self.resetHSButton.isHidden = false
            }
        }
        
        duration *= 0.9
        
    }
    
    fileprivate func getHighScore() -> Int {
        let savedScore = UserDefaults.standard.integer(forKey: "highScore")
        self.highScore = savedScore
        return self.highScore
    }
    
    fileprivate func setHighScore(newHighScore: Int) {
        
        if(newHighScore > self.highScore) {
            self.highScore = newHighScore
            UserDefaults.standard.set(newHighScore, forKey: "highScore")
        }
    }
    fileprivate func resetHighScore() {
        
        self.highScore = 0
        UserDefaults.standard.set(0, forKey: "highScore")

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // create and add a camera to the scene
        //let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera and remember Point of View Orientation
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        initialPointOfView = scnView.pointOfView!
        initialShipOrientation = ship?.orientation ?? SCNVector4()
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        //add labels&button
        addLabels()
        addRestartButton()
        self.restartButton.isHidden = true
        addResetHSButton()
        self.resetHSButton.isHidden = true
        
        //add ship
        addShip()
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        
        // check that we clicked on at least one object
        if hitResults.count > 0 && !self.isGameOver {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                
                material.emission.contents = UIColor.black
                DispatchQueue.main.async {
                    self.addShip()
                }
                self.score += 1
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
            let hapticFeedback = UINotificationFeedbackGenerator()
            hapticFeedback.notificationOccurred(.error)
            // to play sound
            AudioServicesPlaySystemSound (1004)
            
        }
    }
    
    // MARK: - Inhiereted Methods
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
}

