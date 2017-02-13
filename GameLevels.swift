//
//  Levels.swift
//

import Foundation
import SceneKit


class GameLevels {
    
    //let helper = GameHelper()
    
    func createLevelsFrom(baseNode: SCNNode, secondNode: SCNNode)-> [GameLevel] {
        
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
        return [levelOne, levelTwo, levelThree, levelFour, l5, l6, l7]
    }
}

