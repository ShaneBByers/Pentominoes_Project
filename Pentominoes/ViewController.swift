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
    
    var currentOrientation = UIDevice.currentDevice().orientation
    
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
            piece.getImageView().userInteractionEnabled = true
            
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.pieceDoubleTapped(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            piece.getImageView().addGestureRecognizer(doubleTapRecognizer)
            
            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.pieceSingleTapped(_:)))
            singleTapRecognizer.numberOfTapsRequired = 1
            singleTapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "ShowHintSegue":
                if hintPiecesShown < pieces.count {
                    hintPiecesShown += 1
                }
                if let hintViewController = segue.destinationViewController as? HintViewController {
                    var hintPieces : [UIImageView] = []
                    for i in 0..<hintPiecesShown {
                        let newPieceImage = UIImageView(image: UIImage(imageLiteral: boardModel.pieceFilenameAtIndex(i)))
                        hintPieces.append(newPieceImage)
                    }
                    hintViewController.configureWithBoard(boardImages[boardNumber], atIndex: boardNumber, withPieces: hintPieces, usingBoardModel: boardModel)
                    hintViewController.dismissCompletionBlock = {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
                
            default: assert (false, "Unhandled Segue")
            }
        }
    }
    
    // MARK: - Piece Interactions
    //
    func pieceSingleTapped(recognizer: UITapGestureRecognizer) {
        
        if let pieceView = recognizer.view {
            if pieceView.superview == self.boardImage {
                hintPiecesShown = 0
                hintButton.enabled = true
                UIView.animateWithDuration(1, animations: {
                    for piece in self.pieces {
                        if piece.getImageView() == pieceView {
                            if piece.isFlipped() {
                                pieceView.transform = CGAffineTransformRotate(pieceView.transform, CGFloat(M_PI/(-2.0)))
                            } else {
                                pieceView.transform = CGAffineTransformRotate(pieceView.transform, CGFloat(M_PI/2.0))
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
    
    func pieceDoubleTapped(recognizer: UITapGestureRecognizer) {

        
        if let pieceView = recognizer.view {
            if pieceView.superview == self.boardImage {
                hintPiecesShown = 0
                hintButton.enabled = true
                UIView.animateWithDuration(1, animations: {
                    for piece in self.pieces {
                        if piece.getImageView() == pieceView {
                            if piece.rotations() % 2 == 0 {
                                pieceView.transform = CGAffineTransformScale(pieceView.transform,1.0,-1.0)
                            } else {
                                pieceView.transform = CGAffineTransformScale(pieceView.transform,-1.0,1.0)
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
    
    func piecePanned(recognizer: UIPanGestureRecognizer) {
        
        let magnificationFactor : CGFloat = 2
        
        let animationSeconds : NSTimeInterval = 1
        
        switch recognizer.state {
        case .Began:
            if let pieceView = recognizer.view {
                let pointInSuperview = recognizer.locationInView(self.view)
                pieceView.frame = CGRect(origin: pointInSuperview, size: pieceView.frame.size)
                self.view.addSubview(pieceView)
                pieceView.transform = CGAffineTransformScale(pieceView.transform, magnificationFactor, magnificationFactor)
                pieceView.center = pointInSuperview
            }
        case .Changed:
            let translation = recognizer.translationInView(self.view)
            
            if let pieceView = recognizer.view {
                let newCenter = CGPoint(x: pieceView.center.x + translation.x, y: pieceView.center.y + translation.y)
                pieceView.center = newCenter
                recognizer.setTranslation(CGPointZero, inView: self.view)
            }
        case .Ended:
            if let pieceView = recognizer.view {
                
                pieceView.transform = CGAffineTransformScale(pieceView.transform, 0.5, 0.5)
                
                let locationInBoardView = self.view.convertPoint(pieceView.center, toView: self.boardImage)
                
                if (locationInBoardView.x >= self.boardImage.bounds.minX &&
                    locationInBoardView.x <= self.boardImage.bounds.maxX &&
                    locationInBoardView.y >= self.boardImage.bounds.minY &&
                    locationInBoardView.y <= self.boardImage.bounds.maxY) &&
                    boardNumber != 0 {
                    
                    hintPiecesShown = 0
                    hintButton.enabled = true
                    resetButton.enabled = true
                    
                    pieceView.frame.origin = self.boardImage.convertPoint(pieceView.frame.origin, fromView: pieceView.superview)
                    
                    self.boardImage.addSubview(pieceView)
                    
                    snapPieceToBoardView(pieceView)

                } else {
                    
                    resetButton.enabled = false
                    
                    for piece in pieces {
                        if piece.getImageView() == pieceView {
                           UIView.animateWithDuration(animationSeconds, animations: {
                            pieceView.transform = CGAffineTransformIdentity
                            pieceView.center = self.view.convertPoint(piece.originalPoint, fromView: self.piecesView)
                            }, completion: { (true) in
                                pieceView.frame = CGRect(origin: self.piecesView.convertPoint(pieceView.frame.origin, fromView: pieceView.superview), size: pieceView.frame.size)
                                self.piecesView.addSubview(pieceView)
                           })
                        }
                        if piece.getImageView().superview == self.boardImage {
                            resetButton.enabled = true
                        }
                    }
                }
            }
        case .Cancelled:
            
            if let pieceView = recognizer.view {
                pieceView.transform = CGAffineTransformIdentity
                
                for piece in pieces {
                    if piece.getImageView() == pieceView {
                        UIView.animateWithDuration(animationSeconds, animations: {
                            pieceView.center = self.view.convertPoint(piece.originalPoint, fromView: self.piecesView)
                            }, completion: { (true) in
                                pieceView.frame = CGRect(origin: self.piecesView.convertPoint(pieceView.frame.origin, fromView: pieceView.superview), size: pieceView.frame.size)
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
    func snapPieceToBoardView(pieceView : UIView) {
        
        let animationSeconds : NSTimeInterval = 0.5
        
        UIView.animateWithDuration(animationSeconds, animations: {
            var cellNumberX = 0
            var cellNumberY = 0
            
            let origin = self.boardImage.convertPoint(pieceView.frame.origin, fromView: pieceView.superview)
            if Double(origin.x) % Double(self.boardCellSize) > Double(self.boardCellSize)/2.0 {
                cellNumberX = (Int(origin.x)/self.boardCellSize) + 1
            } else {
                cellNumberX = (Int(origin.x)/self.boardCellSize)
            }
            if Double(origin.y) % Double(self.boardCellSize) > Double(self.boardCellSize)/2.0 {
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
        
        if currentOrientation != UIDevice.currentDevice().orientation || piecesNeedPlaced {
            piecesNeedPlaced = false
            
            let isPortraitOrientation = UIDevice.currentDevice().orientation.isPortrait.boolValue
            
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
        
            for (i, piece) in self.pieces.enumerate() {
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
            currentOrientation = UIDevice.currentDevice().orientation
        }
    }
    
    func setBoardButtonsEnabled(enabled: Bool) {
        for button in boardButtons {
            button.enabled = enabled
        }
    }
    
    // MARK: - Button Iteractions
    //
    @IBAction func boardButtonPressed(sender: UIButton) {
        
        if isSolved {
            self.resetButtonPressed(resetButton)
        }

        boardNumber = sender.tag
        
        if boardNumber == 0 {
            solveButton.enabled = false
            resetButton.enabled = false
            hintButton.enabled = false
            hintPiecesShown = 0
        } else {
            solveButton.enabled = true
            hintButton.enabled = true
            hintPiecesShown = 0
        }
        
        boardImage.image = UIImage(named: boardModel.boardFilenameAtIndex(boardNumber))

    }
    
    @IBAction func solveButtonPressed(sender: UIButton) {
        
        hintPiecesShown = 0
        
        let delaySeconds = 0.2
        
        let animationSeconds: NSTimeInterval = 1
        
        solveButton.enabled = false
        resetButton.enabled = false
        hintButton.enabled = false
        setBoardButtonsEnabled(false)
        
        piecesPlacedCounter = 0
        
        for (i, piece) in pieces.enumerate() {
            
            let currentPointInSuperview = self.view.convertPoint(piece.getImageView().frame.origin , fromView: piece.getImageView().superview)
            piece.getImageView().frame.origin = currentPointInSuperview
            self.view.addSubview(piece.getImageView())
            
            UIView.animateWithDuration(animationSeconds, delay: NSTimeInterval(Double(i)*delaySeconds), options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                if let solution = self.boardModel.solutionForBoardIndex(self.boardNumber, forPieceIndex: i),
                    let newX = solution.x,
                    let newY = solution.y,
                    let rotations = solution.rotations,
                    let flips = solution.flips {
                    
                    piece.getImageView().transform = CGAffineTransformIdentity
                    
                    piece.getImageView().transform = CGAffineTransformRotate(piece.getImageView().transform,CGFloat(Double(rotations)*M_PI/2.0))
                    if (flips == 1) {
                        piece.getImageView().transform = CGAffineTransformScale(piece.getImageView().transform,-1.0,1.0)
                    }
                    
                    let boardPointInSuperview = self.boardImage.convertPoint(CGPoint(x: self.boardCellSize * newX, y: self.boardCellSize * newY),toView: self.view)
                    
                    piece.getImageView().frame.origin = boardPointInSuperview
                    
                    if rotations%2 != 0 {
                        piece.swapWidthAndHeight()
                    }
                }
            }, completion: {(value: Bool) in
                
                let pointInBoardImage = self.boardImage.convertPoint(piece.getImageView().frame.origin, fromView: self.view)
                
                piece.getImageView().frame.origin = pointInBoardImage
                
                self.boardImage.addSubview(piece.getImageView())
                
                self.piecesPlacedCounter += 1
                
                if self.piecesPlacedCounter == self.pieces.count {
                    
                    self.resetButton.enabled = true
                    self.setBoardButtonsEnabled(true)
                    self.isSolved = true
                }
            })
        }
    }

    @IBAction func resetButtonPressed(sender: UIButton) {
        
        hintPiecesShown = 0
    
        solveButton.enabled = false
        resetButton.enabled = false
        hintButton.enabled = false
        
        setBoardButtonsEnabled(false)
        
        let animationSeconds : NSTimeInterval = 1
        
        for piece in pieces {
            
            let pointInSuperview = self.view.convertPoint(piece.getImageView().frame.origin, fromView: piece.getImageView().superview)
            
            piece.getImageView().frame.origin = pointInSuperview
            
            self.view.addSubview(piece.getImageView())
            
        }
        
        for piece in pieces {
            
            UIView.animateWithDuration(animationSeconds, animations: {

                piece.getImageView().transform = CGAffineTransformIdentity
                
                piece.resetManualTransformations()

                piece.getImageView().center = self.view.convertPoint(piece.originalPoint, fromView: self.piecesView)
                
                }, completion: {(value: Bool) in
                
                    let pointInPiecesView = self.piecesView.convertPoint(piece.getImageView().frame.origin, fromView: self.view)
                    
                    piece.getImageView().frame.origin = pointInPiecesView
                    
                    self.piecesView.addSubview(piece.getImageView())
                    
                    if self.boardNumber != 0 {
                        self.solveButton.enabled = true
                        self.hintButton.enabled = true
                    }
                    self.setBoardButtonsEnabled(true)
                    self.isSolved = false
            })
        }
    }
}