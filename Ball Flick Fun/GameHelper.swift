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

  var leaderBoard = [LBoard]()
  var leaderBoardLabelNode: [SKLabelNode] = []
  
  let defaults = UserDefaults.standard
  
  let textField = UITextField()
  
  // Maximum number of ball attempts
  static let maxBallNodes = 2 // AKA number of lives
  
  // Start level
  var currentLevel = 0
  
  // Defaults key for persisting the highscore
  fileprivate let kHighscoreKey = "highscore"
  
  // Hud nodes
  var hudNode: SCNNode!
  var hudNode2: SCNNode!
  fileprivate var titleLabelNode: SKLabelNode!
  fileprivate var livesLabelNode: SKLabelNode!
  fileprivate var scoreLabelNode: SKLabelNode!
  fileprivate var highScoreLabelNode: SKLabelNode!
  var timeLabelNode: SKLabelNode!
  
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
      }
      refreshLabel()
    }
  }
  
  // Highscore
  var highScore: Int {
    get {
      return UserDefaults.standard.integer(forKey: kHighscoreKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: kHighscoreKey)
      UserDefaults.standard.synchronize()
    }
  }
  
  var highScoreLabel: SKLabelNode!
  
  
  // Menu screen HUD view setup
  var menuHUDMaterial: SCNMaterial {
    
    let sceneSize = CGSize(width: 300, height: 100)
    let skScene = SKScene(size: sceneSize)
    //skScene.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
    
    //let x = SKSpriteNode(imageNamed: "ball_pink_stripe.png")
    //skScene.addChild(x)
    
    let startLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    startLabel.fontSize = 46
    startLabel.text = "👉🏼play👈🏼"
    //startLabel.fontColor = UIColor.green
    startLabel.position.x = sceneSize.width / 2
    startLabel.position.y = sceneSize.height / 2
    skScene.addChild(startLabel)
    
    highScoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    highScoreLabel.fontSize = 12
    highScoreLabel.position.x = sceneSize.width / 2
    highScoreLabel.position.y = 22
    skScene.addChild(highScoreLabel)
    
    let versionLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    versionLabelNode.text = "Version " + version!
    versionLabelNode.fontSize = 9
    versionLabelNode.position.x = sceneSize.width / 2
    versionLabelNode.position.y = 5
    skScene.addChild(versionLabelNode)
    
    /*
     TODO: redo attempt to display a TextField to capture name
     
     let rect = CGRect(origin: CGPoint(x: 5,y :5), size: CGSize(width: 100, height: 100))
     textField.frame = rect
     var x: SKNode = ""
     x.ad
     skScene.addChild(textField)
     
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
  
  
  
  // Menu screen HUD view setup
  var hsMaterial: SCNMaterial {
    
    

    let sceneSize = CGSize(width: 330, height: 360)
    let skScene = SKScene(size: sceneSize)
    skScene.backgroundColor = UIColor(white: 0.0, alpha: 0.0)

    skScene.removeAllChildren()
    leaderBoardLabelNode.removeAll()
    
    let title = SKLabelNode(fontNamed: "Menlo-Bold")
    title.fontSize = 32
    title.position.x = sceneSize.width / 2
    title.position.y = 290
    title.text = "LEADERBOARD"
    skScene.addChild(title)
    
    let heading = SKLabelNode(fontNamed: "Courier-Bold")
    heading.fontSize = 18
    heading.position = CGPoint(x: 0, y: 260)
    heading.horizontalAlignmentMode = .left
    heading.text = "POS : USERNAME : SCORE : LEVEL"
    skScene.addChild(heading)
    
    var yPos = 230
    var i = 0
    
    
    for entry in self.leaderBoard {
      
      yPos -= 30

      leaderBoardLabelNode.append(SKLabelNode(fontNamed: "Courier-Bold"))
      leaderBoardLabelNode[i].name = "l\(i)"
      leaderBoardLabelNode[i].fontSize = 18
      leaderBoardLabelNode[i].position = CGPoint(x: 0, y: yPos)
      leaderBoardLabelNode[i].horizontalAlignmentMode = .left
      leaderBoardLabelNode[i].text = "\(i+1) : \(entry.name!) : \(entry.score!) : \(entry.level!+1)"
      
      if (leaderBoardLabelNode[i].parent == nil) {
        skScene.addChild(leaderBoardLabelNode[i])
      }
      //print(". entry.dateTime = \(entry.dateTime!)")
      i += 1
    }
    
    
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = skScene
    
    return material
  }
  
  
  
  
  // Game state / screen
  enum GameStateType {
    case tapToPlay
    case playing
    case gameOver
  }
  
  static let gameEndActionKey = "game_end"
  static let ballCanCollisionAudioKey = "ball_hit_can"
  static let ballFloorCollisionAudioKey = "ball_hit_floor"
  
  // Game state
  var levels = [GameLevel]()
  var state = GameStateType.tapToPlay
  
  // Audio sources  ////////////////////////////////////////////////////////////
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
  // End: Audio sources  ///////////////////////////////////////////////////////
  
  init() {
    loadLeaderboard()
    loadAudio()
    createHud()
    refreshLabel()
  }
  
  
  func loadLeaderboard() {
    debugPrint("Loading leaderboard...")

    //Load and decode leaderboard
    
    //Encode leaderbaord to store in User Defaults
    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.leaderBoard)
    self.defaults.set(encodedData, forKey: "leaderBoard")
    self.defaults.synchronize()
    
    
    let decoded = self.defaults.object(forKey: "leaderBoard") as! Data
    
    debugPrint("decoded set...")
    
      let  decodedLBoard = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [LBoard]
      
      debugPrint("decodedLBoard set...")
      
      //sort array, so th§at highest scores are top
      self.leaderBoard = decodedLBoard.sorted(by: {$0.score > $1.score})
      
      for entry in decodedLBoard {
        print("Leaderboard entries (in GameHelper)")
        print(". entry.dateTime = \(entry.dateTime!)")
        print(". entry.name = \(entry.name!)")
        print(". entry.score = \(entry.score!)")
        print(". entry.level = \(entry.level!)")
        print("-----------")
      }
      
  }
  
  func refreshLabel() {
    guard let titleLabelNode = titleLabelNode else { return }
    guard let livesLabelNode = livesLabelNode else { return }
    guard let scoreLabelNode = scoreLabelNode else { return }
    
    titleLabelNode.text = "Level: \(currentLevel+1)"
    
    var b = "💔💔💔💔💔💔"
    
    switch ballNodes.count {
    case 0: b = "❤️❤️❤️❤️❤️❤️"
    case 1: b = "❤️❤️❤️❤️❤️💥"
    case 2: b = "❤️❤️❤️❤️💥💥"
    case 3: b = "❤️❤️❤️💥💥💥"
    case 4: b = "❤️❤️💥💥💥💥"
    case 5: b = "❤️💥💥💥💥💥"
    case 6: b = "💥💥💥💥💥💥"
    default: b = "💥💥💥💥💥💥"
    }
    livesLabelNode.text = "Lives: " + b
    scoreLabelNode.text = "Score: \(score)"
    timeLabelNode.text = "⏱"
  }
  
  func createHud() {
    let screen = UIScreen.main.bounds
    
    // Create a HUD label node in SpriteKit
    let skScene = SKScene(size: CGSize(width: screen.width, height: 150))
    skScene.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
    
    //Score
    scoreLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    scoreLabelNode.fontSize = 20
    scoreLabelNode.position.y = 70
    scoreLabelNode.position.x = screen.width
    scoreLabelNode.horizontalAlignmentMode = .right
    
    skScene.addChild(scoreLabelNode)
    
    //Lives
    livesLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    livesLabelNode.fontSize = 20
    livesLabelNode.position.y = 40
    livesLabelNode.position.x = 0
    livesLabelNode.horizontalAlignmentMode = .left
    skScene.addChild(livesLabelNode)
    
    //Level
    titleLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    titleLabelNode.fontSize = 20
    titleLabelNode.position.y = 70
    titleLabelNode.position.x = 0
    titleLabelNode.horizontalAlignmentMode = .left
    skScene.addChild(titleLabelNode)
    
    //Time
    timeLabelNode = SKLabelNode(fontNamed: "Menlo-Bold")
    timeLabelNode.fontSize = 20
    timeLabelNode.position.y = 40
    timeLabelNode.position.x = screen.width
    timeLabelNode.horizontalAlignmentMode = .right
    
    
    skScene.addChild(timeLabelNode)
    
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
