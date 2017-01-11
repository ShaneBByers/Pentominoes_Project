//
//  BoardModel.swift
//  Pentominoes
//
//  Created by Shane Byers on 9/13/16.
//  Copyright © 2016 Shane Byers. All rights reserved.
//

import Foundation

class BoardModel {
    let numberOfBoards = 6
    let pieceNames = Array(arrayLiteral: "F","I","L","N","P","T","U","V","W","X","Y","Z")
    fileprivate var boardButtonFilenames = [String]()
    fileprivate var boardFilenames = [String]()
    fileprivate var pieceFilenames = [String]()
    
    struct Transformation {
        var x : Int?
        var y : Int?
        var rotations : Int?
        var flips : Int?
    }
    
    fileprivate var transformations : [Int:[String:Transformation]] = [:]
    
    init() {
        for i in pieceNames {
            pieceFilenames.append("tile\(i).png")
        }
        for i in 0..<numberOfBoards {
            boardButtonFilenames.append("Board\(i)button.png")
            boardFilenames.append("Board\(i).png")
        }
        
        var solutionsArray = [[String:[String:Int]]]()
        
        if let solutionsFilepath = Bundle.main.path(forResource: "Solutions", ofType: "plist"),
            let nsArray = NSArray(contentsOfFile: solutionsFilepath) {
            solutionsArray = Array(nsArray as! [[String:[String:Int]]])
        }
        
        for (boardNumber, boardDictionary) in solutionsArray.enumerated() {
            var pieceSolutions : [String:Transformation] = [:]
            for pieceName in pieceNames {
                if let transformation = boardDictionary[pieceName] {
                    if let x = transformation["x"],
                        let y = transformation["y"],
                        let rotations = transformation["rotations"],
                        let flips = transformation["flips"] {
                            pieceSolutions[pieceName] = Transformation(x: x, y: y, rotations: rotations, flips: flips)
                        
                    }
                }
            }
            transformations[boardNumber + 1] = pieceSolutions
        }
        
        
        
    }
    
    func solutionForBoardIndex(_ boardIndex: Int, forPieceIndex pieceIndex: Int) -> Transformation? {
        let pieceName = pieceNames[pieceIndex]
        if let boardSolution = transformations[boardIndex],
            let transformation = boardSolution[pieceName] {
                return transformation
        }
        return nil
    }
    
    func getPieceFilenames() -> [String] {
        return pieceFilenames
    }
    
    func getBoardButtonFilenames() -> [String] {
        return boardButtonFilenames
    }
    
    func getBoardFilenames() -> [String] {
        return boardFilenames
    }
    
    func boardFilenameAtIndex(_ index: Int) -> String {
        return boardFilenames[index]
    }
    
    func getNumberOfBoards() -> Int {
        return numberOfBoards
    }
    
    func pieceFilenameAtIndex(_ index: Int) -> String {
        return pieceFilenames[index]
    }
    
}
