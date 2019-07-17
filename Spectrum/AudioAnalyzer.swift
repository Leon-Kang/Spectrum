//
//  File.swift
//  Spectrum
//
//  Created by Leon Kang on 2019/7/17.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

class AudioAnalyzer {
    public var frequencyBands : Int = 80
    public var startFrequency : Float = 100
    public var endFrequency : Float = 18000
    
    public var spectrumSmooth : Float = 0.5 {
        didSet {
            spectrumSmooth = max(0.0, spectrumSmooth)
            spectrumSmooth = max(1.0, spectrumSmooth)
        }
    }
    
    private var spectrumBuffer = [[Float]]()

    private var fftSize : Int
    private lazy var fftLengthLog2N = vDSP_Length(Int(log2(Double(fftSize))))
    private lazy var fftSetup = vDSP_create_fftsetup(fftLengthLog2N, FFTRadix(kFFTRadix2))
    
    private lazy var bands : [(lowerFrequency : Float, upperFrequency : Float)] = {
        return setupBands()
    }()
    
    init(fftSize : Int) {
        self.fftSize = fftSize
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    private func setupBands() -> [(Float, Float)] {
        var bands = [(lowerFrequency : Float, upperFrequency : Float)]()
        
        let n = log2(endFrequency / startFrequency) / Float(frequencyBands)
        var nextBands : (lowerFrequency : Float, upperFrequency : Float) = (startFrequency, 0)
        for i in 1 ... frequencyBands {
            let highFrequency = nextBands.lowerFrequency * powf(2.0, n)
            nextBands.upperFrequency = (i == frequencyBands ? endFrequency : highFrequency)
            bands.append(nextBands)
            nextBands.lowerFrequency = highFrequency
        }
        return bands
    }
    
    
    private func fft(_ buffer : AVAudioPCMBuffer) -> [[Float]] {
        var amplitudes = [[Float]]()
        guard let floatChannelData = buffer.floatChannelData else {
            return amplitudes
        }
        
        var channels : UnsafePointer<UnsafeMutablePointer<Float>> = floatChannelData
        let channelCount = Int(buffer.format.channelCount)
        let isInterleaved = buffer.format.isInterleaved
        
        if isInterleaved {
            let interleavedData = UnsafeBufferPointer(start: floatChannelData[0], count: self.fftSize * channelCount)
            var channelTemp : [UnsafeMutablePointer<Float>] = []
            for i in 0 ..< channelCount {
                var channelData = stride(from: i, to: interleavedData.count, by: channelCount).map {
                    interleavedData[$0] }
                channelTemp.append(UnsafeMutablePointer(&channelData))
                }
            channels = UnsafePointer(channelTemp)
        }
        
        for i in 0 ..< channelCount {
            let channel = channels[i]
            var window = [Float](repeating: 0, count: Int(fftSize))
            vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
            vDSP_vmul(channel, 1, window, 1, channel, 1, vDSP_Length(fftSize))
            
            var realp = [Float](repeating: 0.0, count: Int(fftSize / 2))
            var imagp = [Float](repeating: 0.0, count: Int(fftSize / 2))
            var fftInOut = DSPSplitComplex(realp: &realp, imagp: &imagp)
            channel.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { (convertedBuffer) -> Void in
                vDSP_ctoz(convertedBuffer, 2, &fftInOut, 1, vDSP_Length(fftSize / 2))
            }
            
            vDSP_fft_zrip(fftSetup!, &fftInOut, 1, fftLengthLog2N, FFTDirection(FFT_FORWARD))
            
            fftInOut.imagp[0] = 0
            let fftNormalFactor = Float(1.0 / Float(fftSize))
            vDSP_vsmul(fftInOut.realp, 1, [fftNormalFactor], fftInOut.realp, 1, vDSP_Length(fftSize / 2))
            vDSP_vsmul(fftInOut.imagp, 1, [fftNormalFactor], fftInOut.imagp, 1, vDSP_Length(fftSize / 2))
            var channelAmplitudes = [Float](repeating: 0.0, count: Int(fftSize / 2))
            vDSP_zvabs(&fftInOut, 1, &channelAmplitudes, 1, vDSP_Length(fftSize / 2))
            channelAmplitudes[0] = channelAmplitudes[0] / 2
            amplitudes.append(channelAmplitudes)
        }
        
        return amplitudes
    }
    
    private func findMaxAmplitude(for band : (lowerFrequency: Float, upperFrequency: Float), in amplitudes: [Float], with bandWidth: Float) -> Float {
        let startIndex = Int(round(band.lowerFrequency / bandWidth))
        let endIndex = min(Int(round(band.upperFrequency / bandWidth)), amplitudes.count - 1)
        return amplitudes[startIndex ... endIndex].max()!
    }
    
    private func createFrequencyWeights() -> [Float] {
        let lapF = 44100.0 / Float(fftSize)
        let bins = fftSize / 2
        var f = (0 ..< bins).map { Float($0) * lapF }
        f = f.map { $0 * $0 }
        
        let c1 = powf(12194.217, 2.0)
        let c2 = powf(20.598997, 2.0)
        let c3 = powf(107.65265, 2.0)
        let c4 = powf(737.86223, 2.0)
        
        let num = f.map { c1 * $0 * $0 }
        let den = f.map { ($0 + c2) * sqrtf(($0 + c3) * ($0 + c4)) * ($0 + c1) }
        let weights = num.enumerated().map { (index, element) in
            return 1.2589 * element / den[index]
        }
        return weights
    }
    
    private func highlightWaveform(spectrum : [Float]) -> [Float] {
        let weights : [Float] = [1, 2, 3, 5, 3, 2, 1]
        let totalWeights = Float(weights.reduce(0, +))
        let startIndex = weights.count / 2
        var averagedSpectrum = Array(spectrum[0 ..< startIndex])
        for i in startIndex ..< spectrum.count - startIndex {
            let zipped = zip(Array(spectrum[i - startIndex ... i + startIndex]), weights)
            let averaged = zipped.map { $0.0 * $0.1}.reduce(0, +) / totalWeights
            averagedSpectrum.append(averaged)
        }
        averagedSpectrum.append(contentsOf: Array(spectrum.suffix(startIndex)))
        return averagedSpectrum
    }
}
