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
  
//  let gameLevels = GameLevels()
  let helper = GameHelper()
  let picker = UIImagePickerController()
  var chosenImage = UIImage()
  var textField = UITextField()
  
  
  //var boardCamera = SKCameraNode()
  
  // Scene properties
  var menuScene = SCNScene(named: "resources.scnassets/Menu.scn")!
  var levelScene = SCNScene(named: "resources.scnassets/Level.scn")!
  var gameOverScene = SCNScene(named: "resources.scnassets/GameOver.scn")!

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
    
    // TODO: uncomment to display image picker
    perform(#selector(presentImageController), with: nil, afterDelay: 0)
  }
  
  var counter = 2000
  
  func updateCounter() {
    counter -= 1
    //print("\(counter) seconds to the end of the world")

    // NOTE: could use following technique to move from Camera 1 to Camera 2, with time and increments to x,y,z & euler 
    // OR Zoom in at the start
    self.cameraNode.position.z += 0.01
    
    if counter <= 0 {
      self.helper.timeLabelNode.text = "0"
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
    
    var gameOverMessage = "Game Over \n\n  You scored \(self.helper.score) points!"
    
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
      textField.minimumFontSize = 30
    }
    
    // 3. Grab the value from the text field, and print it when the user clicks OK.
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
      self.textField = (alert?.textFields![0])! // Force unwrapping because we know it exists.
      
      // Store username in user defaults
      self.helper.defaults.set(self.textField.text, forKey: "Username")
      self.helper.defaults.set(Date(), forKey: "LastRun")
      
      self.helper.leaderBoard.append( LBoard(name: self.textField.text!, score: self.helper.score, dateTime: Date()) )

      //sort array, so th§at highest scores are top
      self.helper.leaderBoard = self.helper.leaderBoard.sorted(by: {$0.score > $1.score})
      
      
      
      //Encode leaderbaord to store in User Defaults
      let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.helper.leaderBoard)
      self.helper.defaults.set(encodedData, forKey: "leaderBoard")
      self.helper.defaults.synchronize()
      
      //Decode
      let decoded = self.helper.defaults.object(forKey: "leaderBoard") as! Data
      var decodedLBoard = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [LBoard]

      //sort array, so th§at highest scores are top
      //decodedLBoard = decodedLBoard.sorted(by: {$0.score > $1.score})
      
      for entry in decodedLBoard {
        print("Leaderboard entries (in GameViewController")
        print(". entry.dateTime = \(entry.dateTime!)")
        print(". entry.name = \(entry.name!)")
        print(". entry.score = \(entry.score!)")
        print("-----------")
      }
      
    }))
    
    // 4. Present the alert.
    self.present(alert, animated: true, completion: nil)
  }
  
  
  // MARK: - Helpers
  func presentMenu() {
    
    helper.menuHUDMaterial.diffuse.contents = chosenImage;
    
    let hudNode = menuScene.rootNode.childNode(withName: "hud", recursively: true)!
    hudNode.geometry?.materials = [helper.menuHUDMaterial]
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI))
    
    let avatarNode = menuScene.rootNode.childNode(withName: "avatar", recursively: true)!
    avatarNode.geometry?.firstMaterial?.diffuse.contents = chosenImage;
    
    let wallNode = menuScene.rootNode.childNode(withName: "wall", recursively: true)!
    wallNode.geometry?.firstMaterial?.diffuse.contents = chosenImage;
    
    helper.state = .tapToPlay
    
    var s = 0
    if self.helper.leaderBoard.count > 0 {
      s = (self.helper.leaderBoard.first?.score)!
    }
    helper.highScoreLabel.text = "Highscore: \(s) (\((self.helper.leaderBoard.first?.name)!))"
    
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
    
    //SCNMaterial
      /*
    tableNode.geometry?.materials

    let sceneSize = CGSize(width: 300, height: 100)
    let skScene = SKScene(size: sceneSize)


    var highScoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    highScoreLabel.text = "Highscore: \((self.helper.leaderBoard.first?.score)!) (\((self.helper.leaderBoard.first?.name)!))"
    highScoreLabel.fontSize = 18
    highScoreLabel.position.x = 10
    highScoreLabel.position.y = 35
    skScene.addChild(highScoreLabel)
    */
    
    helper.state = .gameOver
    
    //TODO: add leaderboard
    
    let transition = SKTransition.crossFade(withDuration: 0.4)
    
    scnView.present(
      gameOverScene,
      with: transition,
      incomingPointOfView: nil,
      completionHandler: nil
    )
    
    presentEnterUsername()
    
  }
  
  //var timer = Timer
  var myTimer : Timer = Timer()
  
  
  func presentLevel() {
    
    // Start timer
    myTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)

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

    counter = 2000
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
    
    let waitAction = SCNAction.wait(duration: 0.1)
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
      shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.35))
    )
    ballPhysicsBody.mass = 3
    ballPhysicsBody.friction = 2
    ballPhysicsBody.contactTestBitMask = 1
    
    ballNode.physicsBody = ballPhysicsBody
    ballNode.position = SCNVector3(x: -1.75, y: 1.75, z: 8.0)
    ballNode.physicsBody?.applyForce(SCNVector3(x: 0.825, y: 0, z: 0), asImpulse: true)
    
    currentBallNode = ballNode
    levelScene.rootNode.addChildNode(ballNode)
    
    // Reset camera position back to original camera position
    cameraNode.position = cameraPosition
    cameraNode.eulerAngles = cameraEuler
    
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
    if helper.ballNodes.count == GameHelper.maxBallNodes {

      // On last ball, on throw, move camera to spotlight position
      self.cameraNode.position = self.spotlightPosition
      self.cameraNode.eulerAngles = self.spotlightEuler

      myTimer.invalidate()

      let waitAction = SCNAction.wait(duration: 2.5)
      let blockAction = SCNAction.run { _ in
        self.presentGameOver()
        self.resetLevel()
        self.helper.ballNodes.removeAll()
        self.helper.currentLevel = 0
        //self.helper.score = 0
        self.counter = 0
        //TODO: add 'Game Over' sound/music
      }
      let sequenceAction = SCNAction.sequence([waitAction, blockAction])
      levelScene.rootNode.runAction(sequenceAction, forKey: GameHelper.gameEndActionKey)
      
    // Add new balls
    } else {
      // Reset camera position back to original camera position
      cameraNode.position = cameraPosition
      cameraNode.eulerAngles = cameraEuler
      
      let waitAction = SCNAction.wait(duration: 0.3)
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
    
    // TODO: runtime error if we try to pull levels in from GameLevels :-/
    // gameLevels.createLevelsFrom(baseNode: shelfNode, secondNode: shelf2Node)
    createLevelsFrom(baseNode: shelfNode, secondNode: shelf2Node)
    levelScene.rootNode.addChildNode(helper.hudNode)
  }
  
  // MARK: - Touches
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    
    if helper.state == .tapToPlay {
      self.helper.score = 0
      presentLevel()
    } else if helper.state == .gameOver {
      presentMenu()
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
  
  /*
  TODO: experiment to change move to touch location, AIM: enable view to change to ball being flicked at cans
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    
    for touch in touches {
      
      let location = touch.location(in: scnView)
      let previousLocation = touch.location(in: scnView)
      let deltaY = location.y - previousLocation.y
      //cameraNode.position.y = cameraNode.position.y + deltaY
    }
  }
  
  */
  
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
      helper.score += 1
    }
    
    if bashedCanNames.count == helper.canNodes.count {
      
      // Add additional points for any balls remaining
      let ballsRemaining = (GameHelper.maxBallNodes - helper.ballNodes.count)
      helper.score += (ballsRemaining * 5)

      helper.score += (counter * 5)
      
      
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
  
  
  func createLevelsFrom(baseNode: SCNNode, secondNode: SCNNode) {
    
    // LEVEL 1 (3 objects)
    //Row 1
    let coin1   = SCNVector3(x: secondNode.position.x - 0, y: secondNode.position.y + 2.62, z: secondNode.position.z )
    
    
    let levelOneCanOne   = SCNVector3(x: baseNode.position.x - 0.5, y: baseNode.position.y + 0.62, z: baseNode.position.z )
    let levelOneCanTwo   = SCNVector3(x: baseNode.position.x + 0.5, y: baseNode.position.y + 0.62, z: baseNode.position.z )
    //Row 2
    let levelOneCanThree = SCNVector3(x: baseNode.position.x + 0.0, y: baseNode.position.y + 1.75, z: baseNode.position.z )
    let levelOne = GameLevel(
      canPositions: [ coin1,
                      levelOneCanOne,   levelOneCanTwo,
                      levelOneCanThree
      ]
    )
    // LEVEL 2 (4 objects)
    //1st Row
    let levelTwoCanOne   = SCNVector3( x: baseNode.position.x - 0.65, y: baseNode.position.y + 0.62, z: baseNode.position.z )
    let levelTwoCanTwo   = SCNVector3( x: baseNode.position.x + 0.65, y: baseNode.position.y + 0.62, z: baseNode.position.z )
    //2nd Row
    let levelTwoCanThree = SCNVector3( x: baseNode.position.x - 0.65, y: baseNode.position.y + 1.80, z: baseNode.position.z )
    let levelTwoCanFour  = SCNVector3( x: baseNode.position.x + 0.65, y: baseNode.position.y + 1.75, z: baseNode.position.z )
    let levelTwo = GameLevel(
      canPositions: [
        levelTwoCanOne,   levelTwoCanTwo,
        levelTwoCanThree, levelTwoCanFour
      ]
    )
    // LEVEL 3 (5 objects)
    //Row 1
    let levelThreeCanOne   = SCNVector3(x: baseNode.position.x - 0.82, y: baseNode.position.y + 1.22, z: baseNode.position.z)
    let levelThreeCanTwo   = SCNVector3(x: baseNode.position.x - 0.00, y: baseNode.position.y + 1.32, z: baseNode.position.z)
    let levelThreeCanThree = SCNVector3(x: baseNode.position.x + 0.82, y: baseNode.position.y + 1.12, z: baseNode.position.z)
    //Row 2
    let levelThreeCanFour  = SCNVector3(x: baseNode.position.x - 0.40, y: baseNode.position.y + 2.75, z: baseNode.position.z)
    let levelThreeCanFive  = SCNVector3(x: baseNode.position.x + 0.40, y: baseNode.position.y + 3.15, z: baseNode.position.z)
    let levelThree = GameLevel(
      canPositions: [
        levelThreeCanOne,   levelThreeCanTwo,   levelThreeCanThree,
        levelThreeCanFour,  levelThreeCanFive
      ]
    )
    // LEVEL 4 (6 objects)
    //Row 1
    let levelFourCanOne   = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let levelFourCanTwo   = SCNVector3(x: baseNode.position.x - 0.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let levelFourCanThree = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    //Row 2
    let levelFourCanFour  = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let levelFourCanFive  = SCNVector3(x: baseNode.position.x - 0.00, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let levelFourCanSix   = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let levelFour = GameLevel(
      canPositions: [
        levelFourCanOne, levelFourCanTwo, levelFourCanThree,
        levelFourCanFour, levelFourCanFive, levelFourCanSix
      ]
    )
    // LEVEL 5 (10 objects)
    // 1st row
    let l5o1 = SCNVector3(x: baseNode.position.x - 1.30, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l5o2 = SCNVector3(x: baseNode.position.x - 0.45, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l5o3 = SCNVector3(x: baseNode.position.x + 0.45, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l5o4 = SCNVector3(x: baseNode.position.x + 1.30, y: baseNode.position.y + 0.75, z: baseNode.position.z)
    // 2nd row
    let l5o5 = SCNVector3(x: baseNode.position.x - 0.90, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l5o6 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l5o7 = SCNVector3(x: baseNode.position.x + 0.80, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    // 3rd
    let l5o8 = SCNVector3(x: baseNode.position.x - 0.45, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l5o9 = SCNVector3(x: baseNode.position.x + 0.45, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    // top
    let l5o10 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 4.00, z: baseNode.position.z)
    let l5 = GameLevel(
      canPositions: [
        l5o1, l5o2, l5o3, l5o4,
        l5o5, l5o6, l5o7,
        l5o8, l5o9,
        l5o10
      ]
    )
    // LEVEL 6 (15 objects)
    // 1st row
    let l6o1 = SCNVector3(x: baseNode.position.x - 2.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l6o2 = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l6o3 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l6o4 = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 0.75, z: baseNode.position.z)
    let l6o5 = SCNVector3(x: baseNode.position.x + 2.00, y: baseNode.position.y + 0.70, z: baseNode.position.z)
    // 2nd row
    let l6o6 = SCNVector3(x: baseNode.position.x - 1.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l6o7 = SCNVector3(x: baseNode.position.x - 0.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l6o8 = SCNVector3(x: baseNode.position.x + 0.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l6o9 = SCNVector3(x: baseNode.position.x + 1.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    // 3rd
    let l6o10 = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l6o11 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l6o12 = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    // 2nd
    let l6o13 = SCNVector3(x: baseNode.position.x - 0.50, y: baseNode.position.y + 4.50, z: baseNode.position.z)
    let l6o14 = SCNVector3(x: baseNode.position.x + 0.50, y: baseNode.position.y + 4.50, z: baseNode.position.z)
    //top
    let l6o15 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 5.80, z: baseNode.position.z)
    
    let l6 = GameLevel(
      canPositions: [
        l6o1, l6o2, l6o3, l6o4, l6o5,
        l6o6, l6o7, l6o8, l6o9,
        l6o10, l6o11, l6o12,
        l6o13, l6o14,
        l6o15
      ]
    )
    
    // LEVEL 7 (21 objects)
    // 1st row
    let l7o1 = SCNVector3(x: baseNode.position.x - 2.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l7o2 = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l7o3 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 0.62, z: baseNode.position.z)
    let l7o4 = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 0.75, z: baseNode.position.z)
    let l7o5 = SCNVector3(x: baseNode.position.x + 2.00, y: baseNode.position.y + 0.70, z: baseNode.position.z)
    let l7o6 = SCNVector3(x: baseNode.position.x + 2.00, y: baseNode.position.y + 0.70, z: baseNode.position.z)
    // 2nd row
    let l7o7 = SCNVector3(x: baseNode.position.x - 1.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l7o8 = SCNVector3(x: baseNode.position.x - 0.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l7o9 = SCNVector3(x: baseNode.position.x + 0.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l7o10 = SCNVector3(x: baseNode.position.x + 1.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    let l7o11 = SCNVector3(x: baseNode.position.x + 1.50, y: baseNode.position.y + 1.75, z: baseNode.position.z)
    // 3rd
    let l7o12 = SCNVector3(x: baseNode.position.x - 1.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l7o13 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l7o14 = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    let l7o15 = SCNVector3(x: baseNode.position.x + 1.00, y: baseNode.position.y + 2.90, z: baseNode.position.z)
    // 2nd
    let l7o16 = SCNVector3(x: baseNode.position.x - 0.50, y: baseNode.position.y + 4.50, z: baseNode.position.z)
    let l7o17 = SCNVector3(x: baseNode.position.x + 0.50, y: baseNode.position.y + 4.50, z: baseNode.position.z)
    let l7o18 = SCNVector3(x: baseNode.position.x + 0.50, y: baseNode.position.y + 4.50, z: baseNode.position.z)
    //top
    let l7o19 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 5.80, z: baseNode.position.z)
    let l7o20 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 5.80, z: baseNode.position.z)
    //top
    let l7o21 = SCNVector3(x: baseNode.position.x + 0.00, y: baseNode.position.y + 5.80, z: baseNode.position.z)
    
    let l7 = GameLevel(
      canPositions: [
        l7o1, l7o2, l7o3, l7o4, l7o5, l7o6,
        l7o7, l7o8, l7o9, l7o10, l7o11,
        l7o12, l7o13, l7o14, l7o15,
        l7o16, l7o17, l7o18,
        l7o19, l7o20,
        l7o21
      ]
    )
    helper.levels = [levelOne, levelTwo, levelThree, levelFour, l5, l6, l7]
  }

}

// Leaderboard object
class LBoard: NSObject, NSCoding{
  var name: String!
  var score: Int!
  var dateTime: Date!
  
  init(name:String, score: Int, dateTime: Date) {
    self.name = name
    self.score = score
    self.dateTime = dateTime
  }
  
  required convenience init(coder aDecoder: NSCoder) {
    let name = aDecoder.decodeObject(forKey: "name") as! String
    let score = aDecoder.decodeObject(forKey: "score") as! Int
    let dateTime = aDecoder.decodeObject(forKey: "dateTime") as! Date
    self.init(name: name, score: score, dateTime: dateTime)
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(name, forKey: "name")
    aCoder.encode(score, forKey: "score")
    aCoder.encode(dateTime, forKey: "dateTime")
  }
}
