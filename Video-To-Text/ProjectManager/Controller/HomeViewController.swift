//
//  HomeViewController.swift
//  Video-To-Text
//
//  Created by Milan Goti on 12/01/22.
//

import UIKit
import Photos
import AVFoundation


class HomeViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var viewVideo: UIView!
    @IBOutlet weak var buttonRecord: UIButton!
    
    //MARK: Declarations
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput = AVCaptureMovieFileOutput()
    var videoCaptureDevice : AVCaptureDevice?
    
    //MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buttonRecord.layer.cornerRadius = self.buttonRecord.frame.height / 2
        
        self.AVCaptureVideoSetUp()
        self.buttonRecord.addTarget(self, action: #selector(self.recordVideoAction), for: .touchUpInside)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds: CGRect = self.viewVideo.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.bounds = bounds
        previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    //MARK: Button Action
    @objc func recordVideoAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.setTitle(sender.isSelected ? "Stop" : "Start", for: .normal)
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
    }
    
    //MARK: Other Methods
    func AVCaptureVideoSetUp(){
        if let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] {
            for device in devices {
                if device.hasMediaType(AVMediaType.video) {
                    if device .position == AVCaptureDevice.Position.front{
                        videoCaptureDevice = device
                    }
                }
            }
            if videoCaptureDevice != nil {
                do {
                    // Add Video Input
                    try self.captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice!))
                    // Get Audio Device
                    guard let audioInput = AVCaptureDevice.default(for: .audio) else { return  }
                    
                    try self.captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    self.viewVideo.layer.addSublayer(self.previewLayer)
                    
                    self.captureSession.addOutput(self.movieOutput)
                    captureSession.startRunning()
                }catch {
                    print(error)
                }
            }
        }
    }
    
}

extension HomeViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        do {
            let videoData = try Data(contentsOf: outputFileURL)
            print("Video Data: \(videoData)")
        } catch {
            print("Could not convert into data")
        }
        let url = "\(outputFileURL)"
        self.splitAudio(sourceUrl: outputFileURL)
        UISaveVideoAtPathToSavedPhotosAlbum(url, nil, nil,nil)
    }
    
    private func getFileName() -> String{
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = "dd_MM_yyyy_HH_mm_ss"
        return dataFormatter.string(from: Date())
    }
    
    
    private func splitAudio(sourceUrl: URL){
        
        var asset: AVURLAsset?
        
        let composition = AVMutableComposition()
        do {
            asset = AVURLAsset(url: sourceUrl)
            guard let audioAssetTrack = asset?.tracks(withMediaType: AVMediaType.audio).first else { return }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }
        // Get url for output
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "\(getFileName()).m4a")
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try? FileManager.default.removeItem(atPath: outputUrl.path)
        }
        
        // Create an export session
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputUrl
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.metadata = asset?.metadata
        
        try? FileManager.default.removeItem(at: exportSession.outputURL!)
        
        // Export file
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
                
            case .unknown:
                print("unknown")
            case .waiting:
                print("waiting")
            case .exporting:
                print("exporting")
            case .failed:
                print("failed")
            case .cancelled:
                print("cancelled")
            case .completed:
                print("completed")
                DispatchQueue.main.async {
                    guard let outputURL = exportSession.outputURL else { return }
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.TextViewController.rawValue) as! TextViewController
                    controller.audioURL = outputURL
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            @unknown default:
                break
            }
        })
    }
    
}
