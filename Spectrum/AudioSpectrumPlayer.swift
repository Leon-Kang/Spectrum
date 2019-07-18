//
//  AudioSpectrumPlayer.swift
//  Spectrum
//
//  Created by Leon Kang on 2019/7/18.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioSpectrumPlayerDelegate : AnyObject {
    func player(_ player : AudioSpectrumPlayer, didGenerateSpectrum spectra : [[Float]])
}

class AudioSpectrumPlayer {
    
    public weak var delegate : AudioSpectrumPlayerDelegate?
    public var analyzer : AudioAnalyzer!
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    public var bufferSize : Int? {
        didSet {
            if let bufferSize = bufferSize {
                analyzer = AudioAnalyzer(fftSize: bufferSize)
                engine.mainMixerNode.removeTap(onBus: 0)
                engine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: nil) { [weak self] (buffer, time) in
                    guard let strongSelf = self else {
                        return
                    }
                    if !strongSelf.player.isPlaying {
                        return
                    }
                    buffer.frameLength = AVAudioFrameCount(bufferSize)
                    let spectra = strongSelf.analyzer.analyse(with: buffer)
                    if strongSelf.delegate != nil {
                        strongSelf.delegate?.player(strongSelf, didGenerateSpectrum: spectra)
                    }
                }
            }
        }
    }
    
    init(bufferSize : Int = 2048) {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.prepare()
        try! engine.start()
        
        defer {
            self.bufferSize = bufferSize
        }
    }
    
    func play(withFileName fileName : String) {
        guard let audioFileURL = Bundle.main.url(forResource: fileName, withExtension: nil),
        let audioFile = try? AVAudioFile(forReading: audioFileURL) else {
            return
        }
        player.stop()
        player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        player.stop()
    }
}
