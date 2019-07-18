//
//  ViewController.swift
//  Spectrum
//
//  Created by Leon Kang on 2019/7/17.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var playButton: UIButton!
    
    var player : AudioSpectrumPlayer!
    
    private var currentPlayingRow : Int?
    
    private lazy var trackPaths : [String] = {
        var paths : [String] = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        paths.sort()
        return paths.map { $0.components(separatedBy: "/").last! }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        player = AudioSpectrumPlayer()
        player.delegate = self
        
        playButton.addTarget(self, action: #selector(tappedPlay), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        let barSpace = spectrumView.frame.width / CGFloat(player.analyzer.frequencyBands * 3 - 1)
        spectrumView.barWidth = barSpace * 2
        spectrumView.space = barSpace
    }

    @objc func tappedPlay() {
        player.play(withFileName: self.trackPaths[0])
    }

}


extension ViewController : AudioSpectrumPlayerDelegate {
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]]) {
        DispatchQueue.main.async {
            self.spectrumView.spectra = spectra
        }
    }
}
