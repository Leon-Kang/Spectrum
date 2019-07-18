//
//  SpectrumView.swift
//  Spectrum
//
//  Created by Leon Kang on 2019/7/18.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

import UIKit

class SpectrumView: UIView {
    
    public var barWidth : CGFloat = 3.0
    public var space : CGFloat = 1.0

    private let bottomSpace : CGFloat = 0.0
    private let topSpace : CGFloat = 0.0
    
    private var leftGradientLayer = CAGradientLayer()
    private var rightGradientLayer = CAGradientLayer()
    
    public var spectra : [[Float]]? {
        didSet {
            if let spectra = spectra {
                let leftPath = UIBezierPath()
                for (index, amplitude) in spectra[0].enumerated() {
                    let x = CGFloat(index) * (barWidth + space) + space
                    let y = translateAmplitudeToYPosition(amplitude: amplitude)
                    let bar = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: bounds.height))
                    leftPath.append(bar)
                }
                
                let leftMaskLayer = CAShapeLayer()
                leftMaskLayer.path = leftPath.cgPath
                leftGradientLayer.frame = CGRect(x: 0, y: topSpace, width: bounds.width, height: bounds.height - topSpace - bottomSpace)
                leftGradientLayer.mask = leftMaskLayer
                
                if spectra.count >= 2 {
                    let rightPath = UIBezierPath()
                    for (index, amplitude) in spectra[1].enumerated() {
                        let x = CGFloat(spectra[1].count - 1 - index) * (barWidth + space) + space
                        let y = translateAmplitudeToYPosition(amplitude: amplitude)
                        let bar = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: bounds.height - bottomSpace - y))
                        rightPath.append(bar)
                    }
                    let rightMaskLayer = CAShapeLayer()
                    rightMaskLayer.path = rightPath.cgPath
                    rightGradientLayer.frame = CGRect(x: 0, y: topSpace, width: bounds.width, height: bounds.height - topSpace - bottomSpace)
                    rightGradientLayer.mask = rightMaskLayer
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        rightGradientLayer.colors = [UIColor(red: 105.0 / 255.0, green: 184.0 / 255.0, blue: 220.0 / 255.0, alpha: 1).cgColor,
                                     UIColor(red: 96.0 / 255.0, green: 229.0 / 255.0, blue: 204.0 / 255.0, alpha: 1).cgColor]
        leftGradientLayer.colors = [UIColor(red: 9.0 / 255.0, green: 196.0 / 255.0, blue: 175.0 / 255.0, alpha: 1).cgColor,
                                    UIColor(red: 90.0 / 255.0, green: 104.0 / 255.0, blue: 206.0 / 255.0, alpha: 1).cgColor]
        
        rightGradientLayer.locations = [0.6, 1.0]
        leftGradientLayer.locations = [0.6, 1.0]
        
        self.layer.addSublayer(rightGradientLayer)
        self.layer.addSublayer(leftGradientLayer)
    }
    
    private func translateAmplitudeToYPosition(amplitude : Float) -> CGFloat {
        let barHeight : CGFloat = CGFloat(amplitude) * (bounds.height - bottomSpace - topSpace)
        return bounds.height - bottomSpace - barHeight
    }

}
