//
//  ViewController.swift
//  Pentominoes
//
//  Created by Shane Byers on 9/13/16.
//  Copyright © 2016 Shane Byers. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Outlet Variables
    //
    @IBOutlet weak var boardImage: UIImageView!
    
    @IBOutlet weak var piecesView: UIView!
    
    @IBOutlet weak var solveButton: UIButton!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet var boardButtons: [UIButton]!
    
    @IBOutlet weak var hintButton: UIButton!
    
    // MARK: - Internal Variables
    //
    let boardCellSize = 30
    
    var boardNumber = 0
    
    let boardModel = BoardModel()
    
    var pieces = [Piece]()
    
    var boardButtonImages = [UIImage]()
    
    var boardImages = [UIImage]()
    
    var isSolved = false
    
    var piecesNeedPlaced = true
    
    var isResetting = false
    
    var piecesPlacedCounter = 0
    
    var hintPiecesShown = 0
    
    var currentOrientation = UIDevice.current.orientation
    
    // MARK: - Initializer Functions
    //
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let boardButtonFilenames = boardModel.getBoardButtonFilenames()
        let boardFilenames = boardModel.getBoardFilenames()
        
        let pieceFilenames = boardModel.getPieceFilenames()
        
        for filename in pieceFilenames {
            pieces.append(Piece(imageFilename: filename))
        }
        
        for i in boardButtonFilenames {
            boardButtonImages.append(UIImage(named: i)!)
        }
        
        for i in boardFilenames {
            boardImages.append(UIImage(named: i)!)
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        for piece in pieces {
            piece.getImageView().isUserInteractionEnabled = true
            
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.pieceDoubleTapped(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            piece.getImageView().addGestureRecognizer(doubleTapRecognizer)
            
            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.pieceSingleTapped(_:)))
            singleTapRecognizer.numberOfTapsRequired = 1
            singleTapRecognizer.require(toFail: doubleTapRecognizer)
            piece.getImageView().addGestureRecognizer(singleTapRecognizer)
            
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.piecePanned(_:)))
            piece.getImageView().addGestureRecognizer(panRecognizer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        placePiecesInPiecesView()
    }
    
    // MARK: - Segues
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "ShowHintSegue":
                if hintPiecesShown < pieces.count {
                    hintPiecesShown += 1
                }
                if let hintViewController = segue.destination as? HintViewController {
                    var hintPieces : [UIImageView] = []
                    for i in 0..<hintPiecesShown {
                        let newPieceImage = UIImageView(image: UIImage(named: boardModel.pieceFilenameAtIndex(i))!)
                        hintPieces.append(newPieceImage)
                    }
                    hintViewController.configureWithBoard(boardImages[boardNumber], atIndex: boardNumber, withPieces: hintPieces, usingBoardModel: boardModel)
                    hintViewController.dismissCompletionBlock = {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                
            default: assert (false, "Unhandled Segue")
            }
        }
    }
    
    // MARK: - Piece Interactions
    //
    func pieceSingleTapped(_ recognizer: UITapGestureRecognizer) {
        
        if let pieceView = recognizer.view {
            if pieceView.superview == self.boardImage {
                hintPiecesShown = 0
                hintButton.isEnabled = true
                UIView.animate(withDuration: 1, animations: {
                    for piece in self.pieces {
                        if piece.getImageView() == pieceView {
                            if piece.isFlipped() {
                                pieceView.transform = pieceView.transform.rotated(by: CGFloat(M_PI/(-2.0)))
                            } else {
                                pieceView.transform = pieceView.transform.rotated(by: CGFloat(M_PI/2.0))
                            }
                        }
                    }
                    
                    }, completion: { (true) in
                        for piece in self.pieces {
                            if piece.getImageView() == pieceView {
                                piece.addRotation()
                            }
                        }
                })
                snapPieceToBoardView(pieceView)
            }
        }
        
    }
    
    func pieceDoubleTapped(_ recognizer: UITapGestureRecognizer) {

        
        if let pieceView = recognizer.view {
            if pieceView.superview == self.boardImage {
                hintPiecesShown = 0
                hintButton.isEnabled = true
                UIView.animate(withDuration: 1, animations: {
                    for piece in self.pieces {
                        if piece.getImageView() == pieceView {
                            if piece.rotations() % 2 == 0 {
                                pieceView.transform = pieceView.transform.scaledBy(x: 1.0,y: -1.0)
                            } else {
                                pieceView.transform = pieceView.transform.scaledBy(x: -1.0,y: 1.0)
                            }
                        }
                    }
                    
                    }, completion: { (true) in
                        for piece in self.pieces {
                            if piece.getImageView() == pieceView {
                                piece.flip()
                            }
                        }
                })
            }
        }
    }
    
    func piecePanned(_ recognizer: UIPanGestureRecognizer) {
        
        let magnificationFactor : CGFloat = 2
        
        let animationSeconds : TimeInterval = 1
        
        switch recognizer.state {
        case .began:
            if let pieceView = recognizer.view {
                let pointInSuperview = recognizer.location(in: self.view)
                pieceView.frame = CGRect(origin: pointInSuperview, size: pieceView.frame.size)
                self.view.addSubview(pieceView)
                pieceView.transform = pieceView.transform.scaledBy(x: magnificationFactor, y: magnificationFactor)
                pieceView.center = pointInSuperview
            }
        case .changed:
            let translation = recognizer.translation(in: self.view)
            
            if let pieceView = recognizer.view {
                let newCenter = CGPoint(x: pieceView.center.x + translation.x, y: pieceView.center.y + translation.y)
                pieceView.center = newCenter
                recognizer.setTranslation(CGPoint.zero, in: self.view)
            }
        case .ended:
            if let pieceView = recognizer.view {
                
                pieceView.transform = pieceView.transform.scaledBy(x: 0.5, y: 0.5)
                
                let locationInBoardView = self.view.convert(pieceView.center, to: self.boardImage)
                
                if (locationInBoardView.x >= self.boardImage.bounds.minX &&
                    locationInBoardView.x <= self.boardImage.bounds.maxX &&
                    locationInBoardView.y >= self.boardImage.bounds.minY &&
                    locationInBoardView.y <= self.boardImage.bounds.maxY) &&
                    boardNumber != 0 {
                    
                    hintPiecesShown = 0
                    hintButton.isEnabled = true
                    resetButton.isEnabled = true
                    
                    pieceView.frame.origin = self.boardImage.convert(pieceView.frame.origin, from: pieceView.superview)
                    
                    self.boardImage.addSubview(pieceView)
                    
                    snapPieceToBoardView(pieceView)

                } else {
                    
                    resetButton.isEnabled = false
                    
                    for piece in pieces {
                        if piece.getImageView() == pieceView {
                           UIView.animate(withDuration: animationSeconds, animations: {
                            pieceView.transform = CGAffineTransform.identity
                            pieceView.center = self.view.convert(piece.originalPoint, from: self.piecesView)
                            }, completion: { (true) in
                                pieceView.frame = CGRect(origin: self.piecesView.convert(pieceView.frame.origin, from: pieceView.superview), size: pieceView.frame.size)
                                self.piecesView.addSubview(pieceView)
                           })
                        }
                        if piece.getImageView().superview == self.boardImage {
                            resetButton.isEnabled = true
                        }
                    }
                }
            }
        case .cancelled:
            
            if let pieceView = recognizer.view {
                pieceView.transform = CGAffineTransform.identity
                
                for piece in pieces {
                    if piece.getImageView() == pieceView {
                        UIView.animate(withDuration: animationSeconds, animations: {
                            pieceView.center = self.view.convert(piece.originalPoint, from: self.piecesView)
                            }, completion: { (true) in
                                pieceView.frame = CGRect(origin: self.piecesView.convert(pieceView.frame.origin, from: pieceView.superview), size: pieceView.frame.size)
                                self.piecesView.addSubview(pieceView)
                        })
                    }
                }
            }
        default: break
        }
    }
    
    // MARK: - Internal Functions
    //
    func snapPieceToBoardView(_ pieceView : UIView) {
        
        let animationSeconds : TimeInterval = 0.5
        
        UIView.animate(withDuration: animationSeconds, animations: {
            var cellNumberX = 0
            var cellNumberY = 0
            
            let origin = self.boardImage.convert(pieceView.frame.origin, from: pieceView.superview)
            if Double(origin.x).truncatingRemainder(dividingBy: Double(self.boardCellSize)) > Double(self.boardCellSize)/2.0 {
                cellNumberX = (Int(origin.x)/self.boardCellSize) + 1
            } else {
                cellNumberX = (Int(origin.x)/self.boardCellSize)
            }
            if Double(origin.y).truncatingRemainder(dividingBy: Double(self.boardCellSize)) > Double(self.boardCellSize)/2.0 {
                cellNumberY = (Int(origin.y)/self.boardCellSize) + 1
            } else {
                cellNumberY = (Int(origin.y)/self.boardCellSize)
            }
            
            let newXInBoardView : CGFloat = CGFloat(Double(cellNumberX * self.boardCellSize))
            let newYInBoardView : CGFloat = CGFloat(Double(cellNumberY * self.boardCellSize))
            
            pieceView.frame = CGRect(origin: CGPoint(x: newXInBoardView, y: newYInBoardView), size: pieceView.frame.size)
            })
        
    }
    
    func placePiecesInPiecesView() {
        
        if currentOrientation != UIDevice.current.orientation || piecesNeedPlaced {
            piecesNeedPlaced = false
            
            let isPortraitOrientation = UIDevice.current.orientation.isPortrait
            
            let piecesViewNumCols : Int
            let piecesViewNumRows : Int
            
            if isPortraitOrientation {
                piecesViewNumCols = 4
                piecesViewNumRows = 3
            } else {
                piecesViewNumCols = 6
                piecesViewNumRows = 2
            }
            
            let piecesViewOutsideBuffer = 10.0
        
            let piecesViewAvailableX = Double(self.piecesView.frame.width) - 2*piecesViewOutsideBuffer
            let piecesViewAvailableY = Double(self.piecesView.frame.height) - 2*piecesViewOutsideBuffer
        
            let onePieceAvailableX = piecesViewAvailableX/Double(piecesViewNumCols)
            let onePieceAvailableY = piecesViewAvailableY/Double(piecesViewNumRows)
        
            for (i, piece) in self.pieces.enumerated() {
                let rowNum = i/piecesViewNumCols
                let colNum = i%piecesViewNumCols
                let x = piecesViewOutsideBuffer + onePieceAvailableX*Double(colNum) + onePieceAvailableX/2.0
                let y = piecesViewOutsideBuffer + onePieceAvailableY*Double(rowNum) + onePieceAvailableY/2.0
                piece.originalPoint = CGPoint(x: x,y: y)
                if piece.getImageView().superview != self.boardImage {
                    piece.setCenter(x, y: y)
                    piecesView.addSubview(piece.getImageView())
                }
                
            }
            currentOrientation = UIDevice.current.orientation
        }
    }
    
    func setBoardButtonsEnabled(_ enabled: Bool) {
        for button in boardButtons {
            button.isEnabled = enabled
        }
    }
    
    // MARK: - Button Iteractions
    //
    @IBAction func boardButtonPressed(_ sender: UIButton) {
        
        if isSolved {
            self.resetButtonPressed(resetButton)
        }

        boardNumber = sender.tag
        
        if boardNumber == 0 {
            solveButton.isEnabled = false
            resetButton.isEnabled = false
            hintButton.isEnabled = false
            hintPiecesShown = 0
        } else {
            solveButton.isEnabled = true
            hintButton.isEnabled = true
            hintPiecesShown = 0
        }
        
        boardImage.image = UIImage(named: boardModel.boardFilenameAtIndex(boardNumber))

    }
    
    @IBAction func solveButtonPressed(_ sender: UIButton) {
        
        hintPiecesShown = 0
        
        let delaySeconds = 0.2
        
        let animationSeconds: TimeInterval = 1
        
        solveButton.isEnabled = false
        resetButton.isEnabled = false
        hintButton.isEnabled = false
        setBoardButtonsEnabled(false)
        
        piecesPlacedCounter = 0
        
        for (i, piece) in pieces.enumerated() {
            
            let currentPointInSuperview = self.view.convert(piece.getImageView().frame.origin , from: piece.getImageView().superview)
            piece.getImageView().frame.origin = currentPointInSuperview
            self.view.addSubview(piece.getImageView())
            
            UIView.animate(withDuration: animationSeconds, delay: TimeInterval(Double(i)*delaySeconds), options: UIViewAnimationOptions(), animations: {
                if let solution = self.boardModel.solutionForBoardIndex(self.boardNumber, forPieceIndex: i),
                    let newX = solution.x,
                    let newY = solution.y,
                    let rotations = solution.rotations,
                    let flips = solution.flips {
                    
                    piece.getImageView().transform = CGAffineTransform.identity
                    
                    piece.getImageView().transform = piece.getImageView().transform.rotated(by: CGFloat(Double(rotations)*M_PI/2.0))
                    if (flips == 1) {
                        piece.getImageView().transform = piece.getImageView().transform.scaledBy(x: -1.0,y: 1.0)
                    }
                    
                    let boardPointInSuperview = self.boardImage.convert(CGPoint(x: self.boardCellSize * newX, y: self.boardCellSize * newY),to: self.view)
                    
                    piece.getImageView().frame.origin = boardPointInSuperview
                    
                    if rotations%2 != 0 {
                        piece.swapWidthAndHeight()
                    }
                }
            }, completion: {(value: Bool) in
                
                let pointInBoardImage = self.boardImage.convert(piece.getImageView().frame.origin, from: self.view)
                
                piece.getImageView().frame.origin = pointInBoardImage
                
                self.boardImage.addSubview(piece.getImageView())
                
                self.piecesPlacedCounter += 1
                
                if self.piecesPlacedCounter == self.pieces.count {
                    
                    self.resetButton.isEnabled = true
                    self.setBoardButtonsEnabled(true)
                    self.isSolved = true
                }
            })
        }
    }

    @IBAction func resetButtonPressed(_ sender: UIButton) {
        
        hintPiecesShown = 0
    
        solveButton.isEnabled = false
        resetButton.isEnabled = false
        hintButton.isEnabled = false
        
        setBoardButtonsEnabled(false)
        
        let animationSeconds : TimeInterval = 1
        
        for piece in pieces {
            
            let pointInSuperview = self.view.convert(piece.getImageView().frame.origin, from: piece.getImageView().superview)
            
            piece.getImageView().frame.origin = pointInSuperview
            
            self.view.addSubview(piece.getImageView())
            
        }
        
        for piece in pieces {
            
            UIView.animate(withDuration: animationSeconds, animations: {

                piece.getImageView().transform = CGAffineTransform.identity
                
                piece.resetManualTransformations()

                piece.getImageView().center = self.view.convert(piece.originalPoint, from: self.piecesView)
                
                }, completion: {(value: Bool) in
                
                    let pointInPiecesView = self.piecesView.convert(piece.getImageView().frame.origin, from: self.view)
                    
                    piece.getImageView().frame.origin = pointInPiecesView
                    
                    self.piecesView.addSubview(piece.getImageView())
                    
                    if self.boardNumber != 0 {
                        self.solveButton.isEnabled = true
                        self.hintButton.isEnabled = true
                    }
                    self.setBoardButtonsEnabled(true)
                    self.isSolved = false
            })
        }
    }
}
