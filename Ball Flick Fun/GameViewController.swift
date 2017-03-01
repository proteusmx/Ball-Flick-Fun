/**
 * GameViewController.swift
 *
 */

import UIKit
import GameplayKit
import SceneKit
import SpriteKit
import AVFoundation


class GameViewController: UIViewController,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
  
  let gameLevels = GameLevels()
  let helper = GameHelper()
  let picker = UIImagePickerController()
  var chosenImage = UIImage()
  var textField = UITextField()
  
  // Scene properties
  var menuScene = SCNScene(named: "resources.scnassets/Menu.scn")!
  var levelScene = SCNScene(named: "resources.scnassets/Level.scn")!
  var gameOverScene = SCNScene(named: "resources.scnassets/GameOver.scn")!
  var levelSelectorScene = SCNScene(named: "resources.scnassets/LevelSelector.scn")!

  // Node properties
  var cameraNode: SCNNode!
  var spotlightNode: SCNNode!
  var shelfNode: SCNNode!
  var shelf2Node: SCNNode!
  var baseCanNode: SCNNode!
  var currentBallNode: SCNNode?
  
  // Ball throwing mechanics
  var startTouchTime: TimeInterval!
  var endTouchTime: TimeInterval!
  var startTouch: UITouch?
  var endTouch: UITouch?
  
  var bashedCanNames: [String] = []
  
  
  var spotlightPosition: SCNVector3!
  var spotlightEuler: SCNVector3!
  var cameraPosition:  SCNVector3!
  var cameraEuler: SCNVector3!
  
  var myTimer : Timer = Timer()
  var myTimer2 : Timer = Timer()
  
  var originalCameraZPosition: Float = 0.0
  
  // Node that intercept touches in the scene
  lazy var touchCatchingPlaneNode: SCNNode = {
    let node = SCNNode(geometry: SCNPlane(width: 40, height: 40))
    node.opacity = 0.001
    node.castsShadow = false
    return node
  }()
  
  
  
  // Accessor for the SCNView
  var scnView: SCNView {
    let scnView = view as! SCNView
    
    scnView.backgroundColor = UIColor.black
    
    return scnView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    picker.delegate = self
    
    presentMenu()
    createScene()
  }
  
  var counter = 2000 // Level countdown
  
  func updateCounter() {
    counter -= 1
    //print("\(counter) seconds to the end of the world")

    // NOTE: could use following technique to move from Camera 1 to Camera 2, with time and increments to x,y,z & euler 
    // OR Zoom in at the start
    //self.cameraNode.position.z += 0.01
    
    if counter <= 0 {
      self.helper.timeLabelNode.text = "0"
      
      // Move camera to spotlight position at end of game
      self.cameraNode.position = self.spotlightPosition
      self.cameraNode.eulerAngles = self.spotlightEuler
      
    } else {
      self.helper.timeLabelNode.text = "⏱: " + String(counter)
    }
    
    if counter == 0 {
      let waitAction = SCNAction.wait(duration: 0.5)
      let blockAction = SCNAction.run { _ in
        
        self.presentGameOver()
        self.resetLevel()
        self.helper.ballNodes.removeAll()
        self.helper.currentLevel = 0
        //self.helper.score = 0
        self.counter = 0
        self.myTimer.invalidate()

        //TODO: add 'Game Over' sound/music
      }
    let sequenceAction = SCNAction.sequence([waitAction, blockAction])
    levelScene.rootNode.runAction(sequenceAction, forKey: GameHelper.gameEndActionKey)
    }
    
  }
  var modifier: Float = 0.5
  
  func zoomIn() {
    
    if self.cameraNode.position.z > self.originalCameraZPosition {
      /*
      if self.cameraNode.position.z > 80 {
        modifier = 0.8
      } else if self.cameraNode.position.z > 50 && self.cameraNode.position.z <= 80 {
        modifier = 0.4
      } else if self.cameraNode.position.z > 30 && self.cameraNode.position.z <= 50 {
        modifier = 0.2
      } else {
        if modifier > 0.01 {
          modifier = modifier - 0.0009
        } else {
          modifier = 0.01
        }
      }
      */
      if modifier > 0.01 {
        modifier = modifier - 0.002
      } else {
        modifier = 0.01
      }
      
      //debugPrint("Modifier = \(modifier) :: Z = \(self.cameraNode.position.z)")
      self.cameraNode.position.z -= modifier
    }
  }
  
  
  func presentImageController() {
    // Show image picker
    picker.allowsEditing = false
    picker.sourceType = .photoLibrary
    picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
    picker.modalPresentationStyle = .popover
    picker.delegate=self
    present(picker, animated: true, completion: nil)
  }
  
  var backgroundMusicPlayer = AVAudioPlayer()
  
  func playBackgroundMusic(filename: String) {
    let url = Bundle.main.url(forResource: filename, withExtension: nil)
    guard let newURL = url else {
      print("Could not find file: \(filename)")
      return
    }
    do {
      backgroundMusicPlayer = try AVAudioPlayer(contentsOf: newURL)
      backgroundMusicPlayer.numberOfLoops = -1
      backgroundMusicPlayer.prepareToPlay()
      backgroundMusicPlayer.play()
    } catch let error as NSError {
      print(error.description)
    }
  }
  
  
  func presentEnterUsername() {
    // ** Capture name for highscore table
    //1. Create the alert controller.
    
    let levelsCompleted = helper.defaults.integer(forKey: "LevelReached")
    
    var gameOverMessage = "Game Over \n\n  You scored \(self.helper.score) points! You reached level \(levelsCompleted)"
    
    if self.helper.score == 0 {
      gameOverMessage += " \n\nCome on, try harder!!"
    }
    else if self.helper.score > 10 && self.helper.score < self.helper.highScore {
      gameOverMessage += " \n\nGood effort, you're getting better!"
    }
    else if self.helper.score >= self.helper.highScore {
      gameOverMessage += " \n\nWell done, you're the new high scorer!"
    }
    
    let alert = UIAlertController(title: gameOverMessage, message: "Enter your username", preferredStyle: .alert)
    
    let usernameFromDefaults = UserDefaults.standard.string(forKey: "Username")
    
    //2. Add the text field. You can configure it however you need.
    alert.addTextField { (textField) in
      textField.text = usernameFromDefaults
      textField.minimumFontSize = 60
    }
    
    // 3. Grab the value from the text field, and print it when the user clicks OK.
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
      self.textField = (alert?.textFields![0])! // Force unwrapping because we know it exists.
      
      // Store username in user defaults
      self.helper.defaults.set(self.textField.text, forKey: "Username")
      self.helper.defaults.set(Date(), forKey: "LastRun")
      
      self.helper.leaderBoard.append( LBoard(name: self.textField.text!, score: self.helper.score, dateTime: Date(), level: self.helper.currentLevel) )

      //sort array, so th§at highest scores are top
      self.helper.leaderBoard = self.helper.leaderBoard.sorted(by: {$0.score > $1.score})
      
      //Encode leaderbaord to store in User Defaults
      let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.helper.leaderBoard)
      self.helper.defaults.set(encodedData, forKey: "leaderBoard")
      self.helper.defaults.synchronize()
      
      //Decode
      let decoded = self.helper.defaults.object(forKey: "leaderBoard") as! Data
      let decodedLBoard = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [LBoard]

      //sort array, so th§at highest scores are top
      //decodedLBoard = decodedLBoard.sorted(by: {$0.score > $1.score})
      
      for entry in decodedLBoard {
        print("Leaderboard entries (in GameViewController")
        print(". entry.dateTime = \(entry.dateTime!)")
        print(". entry.name = \(entry.name!)")
        print(". entry.score = \(entry.score!)")
        print(". entry.level = \(entry.level!)")
        print("-----------")
      }
      
      self.presentGameOver()
    }))
    
    // 4. Present the alert.
    self.present(alert, animated: true, completion: nil )
  }
  
  
  // MARK: - Helpers
  func presentMenu() {
    
    //helper.menuHUDMaterial.diffuse.contents = chosenImage;
    
    let hudNode = menuScene.rootNode.childNode(withName: "hud", recursively: true)!
    hudNode.geometry?.materials = [helper.menuHUDMaterial]
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI))
    
    let avatarNode = menuScene.rootNode.childNode(withName: "avatar", recursively: true)!
    avatarNode.geometry?.firstMaterial?.diffuse.contents = chosenImage;
    
    //let wallNode = menuScene.rootNode.childNode(withName: "wall", recursively: true)!
    //wallNode.geometry?.firstMaterial?.diffuse.contents = chosenImage;
    
    helper.state = .tapToPlay
    
    var s = 0
    if self.helper.leaderBoard.count > 0 {
      s = (self.helper.leaderBoard.first?.score)!
      helper.highScoreLabel.text = "Highscore: \(s) (\((self.helper.leaderBoard.first?.name)!))"
    }
    
    // clearing leadboard from user defaults
    //self.helper.defaults.set(nil, forKey: "leaderBoard")
    
    let transition = SKTransition.crossFade(withDuration: 0.4)
    
    scnView.present(
      menuScene,
      with: transition,
      incomingPointOfView: nil,
      completionHandler: nil
    )

  }
  
  //MARK: - Delegates
  internal func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [String : Any])
  {
    chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
 
    dismiss(animated:true, completion: nil) //5
    
    presentMenu()
    createScene()
  }
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
  
  
  // Present ** GAME OVER **  Scene
  func presentGameOver() {
    let tableNode = gameOverScene.rootNode.childNode(withName: "table", recursively: true)!
    
    tableNode.geometry?.materials = [self.helper.hsMaterial]
    tableNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI))

    helper.state = .gameOver
    helper.defaults.set(self.helper.currentLevel, forKey: "LevelReached")
    
    let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.4)
    
    scnView.present(
      gameOverScene,
      with: transition,
      incomingPointOfView: nil,
      completionHandler: self.resetLevel
    )
    
  }
  
  
  func presentLevel() {
    
    // Start timer, game countdown
    myTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    // STart timer, level zoom in
    myTimer2 = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(zoomIn), userInfo: nil, repeats: true)
    
    resetLevel()
    setupNextLevel()
    helper.state = .playing
    
    playBackgroundMusic(filename: "resources.scnassets/01.forever-bound-stereo-madness.mp3")

    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
    scnView.present(
      levelScene,
      with: transition,
      incomingPointOfView: nil,
      completionHandler: nil
    )
  }
  
  func resetLevel() {

    self.cameraNode.position = cameraPosition
    self.cameraNode.eulerAngles = cameraEuler
    self.originalCameraZPosition = self.cameraNode.position.z
    self.cameraNode.position.z = 80  //start camera z position for zoom in
    self.counter = 2000 // Game over countdown
    self.modifier = 0.5 // level zoom in
    currentBallNode?.removeFromParentNode()
    bashedCanNames.removeAll()
    
    for canNode in helper.canNodes {
      canNode.removeFromParentNode()
    }
    helper.canNodes.removeAll()
    
    for ballNode in helper.ballNodes {
      ballNode.removeFromParentNode()
    }
  }
  
  
  func setupNextLevel() {
    if helper.ballNodes.count > 0 {
      helper.ballNodes.removeLast()
    }

    // Reset camera position back to original camera position
//    cameraNode.position = cameraPosition
//    cameraNode.position.z = self.originalCameraZPosition
//    cameraNode.eulerAngles = cameraEuler
    
    
    let level = helper.levels[helper.currentLevel]
    
    for idx in 0..<level.canPositions.count {
      let canNode = baseCanNode.clone()
      canNode.geometry = baseCanNode.geometry?.copy() as? SCNGeometry
      canNode.geometry?.firstMaterial = baseCanNode.geometry?.firstMaterial?.copy() as? SCNMaterial
      
      let shouldCreateBaseVariation = GKRandomSource.sharedRandom().nextInt() % 2 == 0
      
      canNode.eulerAngles = SCNVector3(x: 0, y: shouldCreateBaseVariation ? -110 : 55, z: 0)
      canNode.name = "Can #\(idx)"
    
      
      if let materials = canNode.geometry?.materials {
        for material in materials where material.multiply.contents != nil {
          if shouldCreateBaseVariation {
            material.multiply.contents = self.chosenImage 
          } else {
            material.multiply.contents = "resources.scnassets/sophie_face.png"
          }
        }
      }
      
      let canPhysicsBody = SCNPhysicsBody(
        type: .dynamic,
        shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.33, height: 1.125), options: nil)
      )
      canPhysicsBody.mass = 0.75
      canPhysicsBody.contactTestBitMask = 1
      canNode.physicsBody = canPhysicsBody
      canNode.position = level.canPositions[idx]
      
      levelScene.rootNode.addChildNode(canNode)
      helper.canNodes.append(canNode)
    }
    
    let waitAction = SCNAction.wait(duration: 0.4)
    let blockAction = SCNAction.run { _ in
      self.dispenseNewBall()
    }
    let sequenceAction = SCNAction.sequence([waitAction, blockAction])
    levelScene.rootNode.runAction(sequenceAction)
  }
  
  
  func dispenseNewBall() {
    
    let ballScene = SCNScene(named: "resources.scnassets/Ball.scn")!
    let ballNode = ballScene.rootNode.childNode(withName: "sphere", recursively: true)!
    ballNode.name = "ball"
    let ballPhysicsBody = SCNPhysicsBody(
      type: .dynamic,
      shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.5))
    )
    ballPhysicsBody.mass = 2
    ballPhysicsBody.friction = 10
    ballPhysicsBody.contactTestBitMask = 1
    
    
    ballNode.physicsBody = ballPhysicsBody
    ballNode.position = SCNVector3(x: -3.0, y: 4.75, z: 8.0)
    ballNode.physicsBody?.applyForce(SCNVector3(x: 0.825, y: 0, z: 0), asImpulse: true)
    
    currentBallNode = ballNode
    levelScene.rootNode.addChildNode(ballNode)
  }
  
  
  func throwBall() {
    guard let ballNode = currentBallNode else { return }
    guard let endingTouch = endTouch else { return }
    
    let firstTouchResult = scnView.hitTest(
      endingTouch.location(in: view),
      options: nil
      ).filter({
        $0.node == touchCatchingPlaneNode
    }).first
    
    guard let touchResult = firstTouchResult else { return }
    
    levelScene.rootNode.runAction(
      SCNAction.playAudio(
        helper.whooshAudioSource,
        waitForCompletion: false
      )
    )
    
    let timeDifference = endTouchTime - startTouchTime
    let velocityComponent = Float(min(max(1 - timeDifference, 0.1), 1.0))
    
    let impulseVector = SCNVector3(
      x: touchResult.localCoordinates.x * 2,
      y: touchResult.localCoordinates.y * velocityComponent * 3,
      z: shelf2Node.position.z * velocityComponent * 15
    )
    
    // NOTE: attempt at positioing camera/viewpoint with the ball, doesn't work!
//    cameraPosition.x = impulseVector.x
//    cameraPosition.y = impulseVector.y
//    cameraPosition.z = impulseVector.z
    
    ballNode.physicsBody?.applyForce(impulseVector, asImpulse: true)
    
    helper.ballNodes.append(ballNode)

    // NOTE: 2nd attempt at positioing camera/viewpoint with the ball, doesn't work!
//    self.cameraNode.position.x = ballNode.position.x
//    self.cameraNode.position.y = ballNode.position.y
//    self.cameraNode.position.z = ballNode.position.x
    
    // Reset
    currentBallNode = nil
    startTouchTime = nil
    endTouchTime = nil
    startTouch = nil
    endTouch = nil
    
    // End of game *************************************************************
    if helper.ballNodes.count == GameHelper.maxBallNodes+1 {


      // On last ball, on throw, move camera to spotlight position
      self.cameraNode.position = self.spotlightPosition
      self.cameraNode.eulerAngles = self.spotlightEuler

      myTimer.invalidate()
      
      // TODO: save current level to user defaults
      
      
      let waitAction = SCNAction.wait(duration: 1.5)
      let blockAction = SCNAction.run { _ in

        //self.presentGameOver()
        //self.resetLevel()
        self.helper.ballNodes.removeAll()
        //self.helper.currentLevel = 0
        //self.helper.score = 0
        self.counter = 0
        
        //let waitAction2 = SCNAction.wait(duration: 1.5)
        //let blockAction2 = SCNAction.run { _ in
          // CAPTURE USERNAME
          self.presentEnterUsername()
        //}
        
      }
      let sequenceAction = SCNAction.sequence([waitAction, blockAction])
      levelScene.rootNode.runAction(sequenceAction, forKey: GameHelper.gameEndActionKey)

      
    // Add new balls
    } else {
      // Reset camera position back to original camera position
      cameraNode.position = cameraPosition
      cameraNode.eulerAngles = cameraEuler
      
      let waitAction = SCNAction.wait(duration: 0.1)
      let blockAction = SCNAction.run { _ in
        self.dispenseNewBall()
      }
      
      let sequenceAction = SCNAction.sequence([waitAction, blockAction])
      levelScene.rootNode.runAction(sequenceAction)
    }
    
    //Hide ball after a delay
    let waitAction = SCNAction.wait(duration: 2.0)
    let fadeOutAction = SCNAction.fadeOut(duration: 1.0)
    let blockAction = SCNAction.run { _ in
      ballNode.physicsBody = nil
    }
    let sequenceAction = SCNAction.sequence([waitAction, fadeOutAction, blockAction])
    
    ballNode.runAction(sequenceAction)
  }
  
  // MARK: - Creation
  func createScene() {
    levelScene.physicsWorld.contactDelegate = self
    
    // NOTE: technique to change the image of the wall on the level
    //let levelNode = levelScene.rootNode.childNode(withName: "wall", recursively: true)!.childNode(withName: "wall", recursively: true)!
    //levelNode.geometry?.firstMaterial?.diffuse.contents = chosenImage;
    
    cameraNode = levelScene.rootNode.childNode(withName: "camera", recursively: true)!
    spotlightNode = levelScene.rootNode.childNode(withName: "spot", recursively: true)!

    // Capture original camera position and euler
    cameraPosition = cameraNode.position
    cameraEuler = cameraNode.eulerAngles

    // Capture spotlight position and euler
    spotlightPosition = spotlightNode.position
    spotlightEuler = spotlightNode.eulerAngles

    shelfNode = levelScene.rootNode.childNode(withName: "shelf", recursively: true)!
    shelf2Node = levelScene.rootNode.childNode(withName: "shelf2", recursively: true)!
    
    guard let canScene = SCNScene(named: "resources.scnassets/Can.scn") else { return }
    baseCanNode = canScene.rootNode.childNode(withName: "can", recursively: true)!
    
    let shelfPhysicsBody = SCNPhysicsBody(
      type: .static, shape: SCNPhysicsShape(geometry: shelfNode.geometry!)
    )
    shelfPhysicsBody.isAffectedByGravity = false
    shelfNode.physicsBody = shelfPhysicsBody
    
    let shelf2PhysicsBody = SCNPhysicsBody(
      type: .static, shape: SCNPhysicsShape(geometry: shelf2Node.geometry!)
    )
    shelf2PhysicsBody.isAffectedByGravity = false
    shelf2Node.physicsBody = shelf2PhysicsBody
    
    levelScene.rootNode.addChildNode(touchCatchingPlaneNode)
    
    touchCatchingPlaneNode.position = SCNVector3(x: 0, y: 0, z: shelfNode.position.z)
    //touchCatchingPlaneNode.position = SCNVector3(x: 0, y: 0, z: shelf2Node.position.z)
    touchCatchingPlaneNode.eulerAngles = cameraNode.eulerAngles
    
    helper.levels = gameLevels.createLevelsFrom(baseNode: shelfNode, secondNode: shelf2Node)
    
    levelScene.rootNode.addChildNode(helper.hudNode)
  }
  
  // MARK: - Touches
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    
    // Menu view
    if helper.state == .tapToPlay {
      self.helper.score = 0
      
      guard let firstTouch = touches.first else { return }
      
      let point = firstTouch.location(in: scnView)
      let hitResults = scnView.hitTest(point, options: [:])
      
      let hudNode = menuScene.rootNode.childNode(withName: "hud", recursively: true)!
      let avatarNode = menuScene.rootNode.childNode(withName: "avatar", recursively: true)!
      let titleNode = menuScene.rootNode.childNode(withName: "title", recursively: true)!
      
      if hitResults.first?.node == titleNode {
        //hitResults.first?.node.position
        //self.cameraNode.position.x = (hitResults.first?.worldCoordinates.x)!
      }
      
      let levelsCompleted = helper.defaults.integer(forKey: "LevelReached")
      
      if hitResults.first?.node == hudNode {
        //presentLevel()
        
        // Select Level
        let transition = SKTransition.doorway(withDuration: 0.5)
        
        
        // TODO: denote which levels have been completed to date
        
        
        //for n in 1...4 {
          //let lSS = levelSelectorScene.rootNode.childNode(withName: "box\(n)", recursively: true)
          //lSS?.geometry?.materials[0].diffuse.contents = UIColor.green
        //}
        for n in levelsCompleted+1...9 {
          let lSS = levelSelectorScene.rootNode.childNode(withName: "box\(n)", recursively: true)
          lSS?.geometry?.materials[0].diffuse.contents = UIColor.red
        }
        let lSS = levelSelectorScene.rootNode.childNode(withName: "box\(levelsCompleted+1)", recursively: true)
        lSS?.geometry?.materials[0].diffuse.contents = UIColor.green
      
        scnView.present(
          levelSelectorScene,
          with: transition,
          incomingPointOfView: nil,
          completionHandler: nil
        )
      }

      if hitResults.first?.node == avatarNode {
        self.presentImageController()
      }


      let n:String = hitResults.first!.node.name!

      // Set level to the selected one on the LevelSelector screen
      if n.contains("box") {
        
        var temp  = n.characters.map{String($0)}
        let o = Int(String(temp[3]))
        
        if o! <= levelsCompleted+1 {
          helper.currentLevel = o! - 1
          presentLevel()
        }
        
        //hitResults.first?.node.position.z = -4
        //hitResults.first?.node.geometry?.materials[0].diffuse.contents = UIColor.blue
      }

      //let camNode = menuScene.rootNode.childNode(withName: "camera", recursively: true)!
      //camNode.position.x = (hitResults.first?.worldCoordinates.x)!
      
      print("Touch location: X = \(hitResults.first?.worldCoordinates.x), Y = \(hitResults.first?.worldCoordinates.y)), Z = \(hitResults.first?.worldCoordinates.z))")
      
      print("Node Name = \(hitResults.first?.node.name)")
      print("Node = \(hitResults.first?.node.description)")
      
      
    // Game over view
    } else if helper.state == .gameOver {
      presentMenu()
      
    // Level view
    } else {
      guard let firstTouch = touches.first else { return }
      
      let point = firstTouch.location(in: scnView)
      let hitResults = scnView.hitTest(point, options: [:])
      
      if hitResults.first?.node == currentBallNode {
        startTouch = touches.first
        startTouchTime = Date().timeIntervalSince1970
      }
    }
 
  }
  
  
  //TODO: experiment to change move to touch location, AIM: enable view to change to ball being flicked at cans
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    
    if helper.state == .tapToPlay {
      
      guard let firstTouch = touches.first else { return }
      
      let point = firstTouch.location(in: scnView)
      let hitResults = scnView.hitTest(point, options: [:])
      
      //let camNode = menuScene.rootNode.childNode(withName: "camera", recursively: true)!
      
      //camNode.position.x = (hitResults.first?.worldCoordinates.x)!
      //camNode.position.y = (hitResults.first?.worldCoordinates.y)!
      //camNode.position.z = (hitResults.first?.worldCoordinates.z)!
      
      debugPrint("Touch pos= X: \(hitResults.first?.worldCoordinates.x), Y: \(hitResults.first?.worldCoordinates.y)), Z: \(hitResults.first?.worldCoordinates.z))")
    
    }
    
  }
 
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    
    guard startTouch != nil else { return }
    
    endTouch = touches.first
    endTouchTime = Date().timeIntervalSince1970
    
    throwBall()
    
    //cameraNode.position = spotlightPosition
    //cameraNode.eulerAngles = spotlightEuler
  }
  
  
  // NOTE: if we want to hige status bar change to 'false'
  //override var prefersStatusBarHidden : Bool {
  //  return true
  //}
  
  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
  }
  
}

extension GameViewController: SCNPhysicsContactDelegate {
  
  // MARK: SCNPhysicsContactDelegate
  func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    guard let nodeNameA = contact.nodeA.name else { return }
    guard let nodeNameB = contact.nodeB.name else { return }
    
    var ballFloorContactNode: SCNNode?
    if nodeNameA == "ball" && nodeNameB == "floor" {
      ballFloorContactNode = contact.nodeA
    } else if nodeNameB == "ball" && nodeNameA == "floor" {
      ballFloorContactNode = contact.nodeB
    }
    
    if let ballNode = ballFloorContactNode {
      guard ballNode.action(forKey: GameHelper.ballFloorCollisionAudioKey) == nil else { return }
      
      ballNode.runAction(
        SCNAction.playAudio(
          helper.ballFloorAudioSource,
          waitForCompletion: true
        ),
        forKey: GameHelper.ballFloorCollisionAudioKey
      )
      return
    }
    
    var ballCanContactNode: SCNNode?
    if nodeNameA.contains("Can") && nodeNameB == "ball" {
      ballCanContactNode = contact.nodeA
    } else if nodeNameB.contains("Can") && nodeNameA == "ball" {
      ballCanContactNode = contact.nodeB
    }
    
    if let canNode = ballCanContactNode {
      guard canNode.action(forKey: GameHelper.ballCanCollisionAudioKey) == nil else {
        return
      }
      
      canNode.runAction(
        SCNAction.playAudio(
          helper.ballCanAudioSource,
          waitForCompletion: true
        ),
        forKey: GameHelper.ballCanCollisionAudioKey
      )
      return
    }
    
    if bashedCanNames.contains(nodeNameA) || bashedCanNames.contains(nodeNameB) { return }
    
    var canNodeWithContact: SCNNode?
    if nodeNameA.contains("Can") && nodeNameB == "floor" {
      canNodeWithContact = contact.nodeA
    } else if nodeNameB.contains("Can") && nodeNameA == "floor" {
      canNodeWithContact = contact.nodeB
    }
    
    if let bashedCan = canNodeWithContact {
      bashedCan.runAction(
        SCNAction.playAudio(
          helper.canFloorAudioSource,
          waitForCompletion: false
        )
      )
      bashedCanNames.append(bashedCan.name!)
      
      // points for bashed cans
      helper.score += 1
    }
    
    if bashedCanNames.count == helper.canNodes.count {
      
      // Add additional points for any balls remaining
      let ballsRemaining = (GameHelper.maxBallNodes - helper.ballNodes.count)
      
      // extra points for ball remaining
      helper.score += (ballsRemaining * 2)
      
      // extra points for time remaining
      helper.score += (counter / 100)
      
      
      if levelScene.rootNode.action(forKey: GameHelper.gameEndActionKey) != nil {
        levelScene.rootNode.removeAction(forKey: GameHelper.gameEndActionKey)
      }
      
      let maxLevelIndex = helper.levels.count - 1
      
      if helper.currentLevel == maxLevelIndex {
        helper.currentLevel = 0
      } else {
        helper.currentLevel += 1
        self.helper.ballNodes.removeAll()
      }
      
      let waitAction = SCNAction.wait(duration: 1.0)
      let blockAction = SCNAction.run { _ in
        self.resetLevel()
        self.setupNextLevel()
      }
      let sequenceAction = SCNAction.sequence([waitAction, blockAction])
      levelScene.rootNode.runAction(sequenceAction)
    }
  }
  
}

// Leaderboard object
class LBoard: NSObject, NSCoding{
  var name: String!
  var score: Int!
  var dateTime: Date!
  var level: Int!
  
  init(name:String, score: Int, dateTime: Date, level: Int) {
    self.name = name
    self.score = score
    self.dateTime = dateTime
    self.level = level
  }
  
  required convenience init(coder aDecoder: NSCoder) {
    let name = aDecoder.decodeObject(forKey: "name") as! String
    let score = aDecoder.decodeObject(forKey: "score") as! Int
    let dateTime = aDecoder.decodeObject(forKey: "dateTime") as! Date
    let level = aDecoder.decodeObject(forKey: "level") as! Int
    self.init(name: name, score: score, dateTime: dateTime, level: level)
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(name, forKey: "name")
    aCoder.encode(score, forKey: "score")
    aCoder.encode(dateTime, forKey: "dateTime")
    aCoder.encode(level, forKey: "level")
  }
}
