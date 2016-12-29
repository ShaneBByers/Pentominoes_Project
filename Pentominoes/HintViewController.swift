//
//  HintViewController.swift
//  Pentominoes
//
//  Created by Shane Byers on 9/24/16.
//  Copyright © 2016 Shane Byers. All rights reserved.
//

import UIKit

class HintViewController: UIViewController {
    
    @IBOutlet weak var boardImage: UIImageView!
    
    private var board : UIImage? = nil
    
    private var hintPieces : [UIImageView]? = nil
    
    private var myBoardModel : BoardModel? = nil
    
    private var currentBoardIndex : Int = 0
    
    private let boardCellSize : Int = 30
    
    var dismissCompletionBlock : (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boardImage.image = board
        placePiecesOnBoard()
    }
    
    func placePiecesOnBoard() {
        if let pieces = hintPieces,
            let boardModel = myBoardModel {
            for (i, piece) in pieces.enumerate() {
                self.boardImage.addSubview(piece)
                if let solution = boardModel.solutionForBoardIndex(currentBoardIndex, forPieceIndex: i),
                    let newX = solution.x,
                    let newY = solution.y,
                    let rotations = solution.rotations,
                    let flips = solution.flips {
                    piece.transform = CGAffineTransformRotate(piece.transform, CGFloat(Double(rotations)*M_PI/2))
                    
                    if flips == 1 {
                        piece.transform = CGAffineTransformScale(piece.transform,-1.0,1.0)
                    }
                    
                    piece.frame.origin = CGPoint(x: self.boardCellSize * newX, y: self.boardCellSize * newY)
                    
                    if rotations % 2 != 0 {
                        let newWidth = piece.image!.size.height
                        let newHeight = piece.image!.size.width
                        
                        piece.frame.size = CGSize(width: newWidth, height: newHeight)
                    }
                    
                }
            }
        }
    }
    
    func configureWithBoard(aBoardImage: UIImage, atIndex boardIndex: Int, withPieces somePieces: [UIImageView], usingBoardModel aBoardModel: BoardModel) {
        currentBoardIndex = boardIndex
        board = aBoardImage
        hintPieces = somePieces
        myBoardModel = aBoardModel
    }
    

    @IBAction func dismissView(sender: UIButton) {
        if let dismissCompletionBlock = dismissCompletionBlock {
            dismissCompletionBlock()
        }
    }
    
}
