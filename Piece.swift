//
//  Piece.swift
//  Pentominoes
//
//  Created by Shane Byers on 9/13/16.
//  Copyright © 2016 Shane Byers. All rights reserved.
//

import Foundation
import UIKit

class Piece {
    var originalPoint : CGPoint
    
    fileprivate var imageView : UIImageView
    fileprivate var imageSize : CGSize
    fileprivate var rotationCount : Int = 0
    fileprivate var flipped : Bool = false
    fileprivate let maxRotations = 4
    
    init(imageFilename: String) {
        let image = UIImage(named: imageFilename)!
        imageSize = image.size
        imageView = UIImageView(image: image)
        imageView.frame = CGRect(origin: CGPoint.zero, size: image.size)
        originalPoint = CGPoint.zero
    }
    
    func setCenter(_ x: Double, y: Double) {
        imageView.center = CGPoint(x: x, y: y)
    }
    
    func getImageView() -> UIImageView {
        return imageView
    }
    
    func swapWidthAndHeight() {
        let newWidth = self.imageView.image!.size.height
        let newHeight = self.imageView.image!.size.width
        
        self.imageView.frame = CGRect(x: self.imageView.frame.origin.x, y: self.imageView.frame.origin.y, width: newWidth, height: newHeight)
    }
    
    func addRotation() {
        rotationCount += 1
        rotationCount = rotationCount % maxRotations
    }
    
    func flip() {
        flipped = !flipped
    }
    
    func rotations() -> Int {
        return rotationCount
    }
    
    func isFlipped() -> Bool {
        return flipped
    }
    
    func resetManualTransformations() {
        rotationCount = 0
        flipped = false
    }
    
}
