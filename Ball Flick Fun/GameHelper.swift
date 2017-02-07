/**
 *
 */

import SpriteKit
import SceneKit

// Information about a level
struct GameLevel {
  let canPositions: [SCNVector3]
}

class GameHelper {
    
  // Defaults key for persisting the highscore
  fileprivate let kHighscoreKey = "highscore"
  
  // Hud nodes
  var hudNode: SCNNode!
  fileprivate var titleLabelNode: SKLabelNode!
  fileprivate var labelNode: SKLabelNode!
  fileprivate var scoreLabelNode: SKLabelNode!
  
  // Gameplay references
  var canNodes = [SCNNode]()
  var ballNodes = [SCNNode]() {
    didSet {
      refreshLabel()
    }
  }
  
  // Game's score
  var score = 0 {
    didSet {
      if score > highScore {
        highScore = score
        //todo - display score is now new High score
      }
      refreshLabel()
    }
  }
  
  var highScore: Int {
    get {
      return UserDefaults.standard.integer(forKey: kHighscoreKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: kHighscoreKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var highScoreLabelNode: SKLabelNode!
  
  var menuHUDMaterial: SCNMaterial {
    // Create a HUD label node in SpriteKit
    let sceneSize = CGSize(width: 300, height: 100)
    
    let skScene = SKScene(size: sceneSize)
    skScene.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
    
    
    let x = SKSpriteNode(imageNamed: "ball_pink_stripe.png")
    
    //NOTE: location of image different from SKSPrintNote - picked up in resources folder
   // x.texture = SKTexture(imageNamed: "alice_face.png")
    
    skScene.addChild(x)
    
    let instructionLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    instructionLabel.fontSize = 50
    instructionLabel.text = "👉🏼START👈🏼"
    instructionLabel.position.x = sceneSize.width / 2
    instructionLabel.position.y = 55
    skScene.addChild(instructionLabel)
    
    highScoreLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    highScoreLabelNode.fontSize = 18
    highScoreLabelNode.position.x = sceneSize.width / 2
    highScoreLabelNode.position.y = 35
    skScene.addChild(highScoreLabelNode)
    
    let versionLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    versionLabelNode.text = "Version 0.1"
    versionLabelNode.fontSize = 9
    versionLabelNode.position.x = sceneSize.width / 2
    versionLabelNode.position.y = 5
    skScene.addChild(versionLabelNode)
    
    /*
    let picLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    picLabelNode.text = "Select Pics 📷"
    picLabelNode.fontSize = 30
    picLabelNode.position.x = sceneSize.width / 2
    picLabelNode.position.y = 35
    skScene.addChild(picLabelNode)
    */
 
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = skScene
    
    return material
  }
  
  // Game state
  enum GameStateType {
    case tapToPlay
    case playing
    case gameOver
  }
  
  // Maximum number of ball attempts
  static let maxBallNodes = 1 // AKA number of lives
  static let gameEndActionKey = "game_end"
  static let ballCanCollisionAudioKey = "ball_hit_can"
  static let ballFloorCollisionAudioKey = "ball_hit_floor"
  
  // Game state
  var currentLevel = 0
  var levels = [GameLevel]()
  var state = GameStateType.tapToPlay
  
  // Audio sources
  lazy var whooshAudioSource: SCNAudioSource = {
    let source = SCNAudioSource(fileNamed: "sounds/whoosh.aiff")!
    
    source.isPositional = false
    source.volume = 1.00
    
    return source
  }()
  lazy var ballCanAudioSource: SCNAudioSource = {
    let source = SCNAudioSource(fileNamed: "sounds/Smashing-Yuri_Santana-1233262689.mp3")!
    
    source.isPositional = false
    source.volume = 2.0
    
    return source
  }()
  lazy var ballFloorAudioSource: SCNAudioSource = {
    let source = SCNAudioSource(fileNamed: "sounds/ball_floor.aiff")!
    
    source.isPositional = false
    source.volume = 2.0
    
    return source
  }()
  lazy var canFloorAudioSource: SCNAudioSource = {
    let source = SCNAudioSource(fileNamed: "sounds/can_floor.aiff")!
    
    source.isPositional = false
    source.volume = 2.0
    
    return source
  }()
  
  init() {
    loadAudio()
    createHud()
    refreshLabel()
  }
  
  func refreshLabel() {
    guard let titleLabelNode = titleLabelNode else { return }
    guard let labelNode = labelNode else { return }
    guard let scoreLabelNode = scoreLabelNode else { return }
    
    titleLabelNode.text = "Level: \(currentLevel+1)"
    
    //let ballsRemaining = (GameHelper.maxBallNodes - ballNodes.count)
    var b = "💔💔💔💔💔💔"
    var c = ""
    
    switch ballNodes.count {
    case 0: b = "❤️❤️❤️❤️❤️❤️"
    case 1: b = "❤️❤️❤️❤️❤️💥"
    case 2: b = "❤️❤️❤️❤️💥💥"
    case 3: b = "❤️❤️❤️💥💥💥"
    case 4: b = "❤️❤️💥💥💥💥"
    case 5: b = "❤️💥💥💥💥💥"
    case 5: b = "💥💥💥💥💥💥"
    default: b = "💥💥💥💥💥💥"
    }
    labelNode.text = "Lives: " + b
    
    c="\(score)"
    scoreLabelNode.text = "Score: " + c
  }
  
  func createHud() {
    let screen = UIScreen.main.bounds
    
    // Create a HUD label node in SpriteKit
    let skScene = SKScene(size: CGSize(width: screen.width, height: 150))
    skScene.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
    
    //Level
    titleLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    titleLabelNode.fontSize = 35
    titleLabelNode.position.y = 0
    titleLabelNode.position.x = screen.width / 2
    skScene.addChild(titleLabelNode)

    //Lives
    labelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    labelNode.fontSize = 35
    labelNode.position.y = 40
    labelNode.position.x = screen.width / 2
    skScene.addChild(labelNode)

    //Score
    scoreLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    scoreLabelNode.fontSize = 35
    scoreLabelNode.position.y = 80
    scoreLabelNode.position.x = screen.width / 2
    skScene.addChild(scoreLabelNode)

    // Add the SKScene to a plane node
    let plane = SCNPlane(width: 8, height: 3)
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = skScene
    plane.materials = [material]
    
    // Add the hud to the level
    hudNode = SCNNode(geometry: plane)
    hudNode.name = "hud"
    hudNode.position = SCNVector3(x: 0.0, y: 9.0, z: -4.5)
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI))
  }
  
  func loadAudio() {
    let sources = [
      whooshAudioSource,
      ballCanAudioSource,
      ballFloorAudioSource,
      canFloorAudioSource
    ]
    
    for source in sources {
      source.load()
    }
  }
  
}
