//
//  ViewController.swift
//  ICGVideo
//
//  Created by CenHomes on 5/31/19.
//  Copyright © 2019 Simson. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {

    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var trimButton: UIButton!
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    
// MARK: - Properties
    var isPlaying = false
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var playerLayer: AVPlayerLayer?
    var playbackTimeCheckerTimer: Timer?
    var videoPlaybackPosition: CGFloat = 0.0
    
    var tempVideoPath = ""
    var exportSession: AVAssetExportSession?
    var asset: AVAsset?
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat = 0.0
    var restartOnPlay = false
    
// MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tempVideoPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tmpMov.mp4").absoluteString
    }

    @IBAction func selectAsset(_ sender: Any) {
        let myImagePickerController = UIImagePickerController()
        myImagePickerController.sourceType = .photoLibrary
        myImagePickerController.mediaTypes = [kUTTypeMovie] as [String]
        myImagePickerController.delegate = self
        myImagePickerController.isEditing = false
        self.present(myImagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func trimVideo(_ sender: Any) {
        self.deleteTempFile()
        guard let asset = self.asset else { return }
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            self.exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            
            let furl = URL(fileURLWithPath: self.tempVideoPath)
            self.exportSession?.outputURL = furl
            self.exportSession?.outputFileType = AVFileType.mp4
            self.exportSession?.shouldOptimizeForNetworkUse = true
            
            let start = CMTimeMakeWithSeconds(Float64(self.startTime), preferredTimescale: asset.duration.timescale)
            let duration = CMTimeMakeWithSeconds(Float64(self.stopTime - self.startTime), preferredTimescale: asset.duration.timescale)
            let range = CMTimeRangeMake(start: start, duration: duration)
            self.exportSession?.timeRange = range
            
            self.exportSession?.exportAsynchronously(completionHandler: {
                guard let status = self.exportSession?.status else {return }
                switch (status) {
                case AVAssetExportSession.Status.failed:
                    print("Export failed: \(self.exportSession?.error?.localizedDescription)")
                    break
                case AVAssetExportSession.Status.cancelled:
                    NSLog("Export canceled")
                    break
                default:
                    NSLog("DONE")
                    DispatchQueue.main.async {
                        let movieUrl = URL(fileURLWithPath: self.tempVideoPath)
                        UISaveVideoAtPathToSavedPhotosAlbum(movieUrl.relativePath, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            })
        }
    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        if error != nil {
            title = "Error"
            message = "Video failed to save"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    func deleteTempFile() {
        let url = URL(fileURLWithPath: self.tempVideoPath)
        let fm = FileManager.default
        let exist = fm.fileExists(atPath: url.path)
        if exist {
            do {
                try fm.removeItem(at: url)
                NSLog("file deleted")
            } catch let err {
                NSLog("file remove error", err.localizedDescription )
            }
        } else {
            NSLog("no file by that name")
        }
    }
}

// MARK: - ICGVideoTrimmerDelegate
extension ViewController: ICGVideoTrimmerDelegate {
    func trimmerView(_ trimmerView: ICGVideoTrimmerView, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        restartOnPlay = true
        self.player?.pause()
        self.isPlaying = false
        self.stopPlaybackTimeChecker()
        
        self.trimmerView.hideTracker(true)
        if startTime != self.startTime {
            self.seekVideoToPos(pos: startTime)
        } else {
            self.seekVideoToPos(pos: endTime)
        }
        
        self.startTime = startTime
        self.stopTime = endTime
    }
    
    func startPlaybackTimeChecker() {
        self.stopPlaybackTimeChecker()
        
        self.playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeCheckerTimer), userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        if self.playbackTimeCheckerTimer != nil {
            self.playbackTimeCheckerTimer?.invalidate()
            self.playbackTimeCheckerTimer = nil
        }
    }
    
    // MARK: - PlaybackTimeCheckerTimer
    @objc func onPlaybackTimeCheckerTimer() {
        guard let curTime = self.player?.currentTime() else {return }
        var seconds: Float64 = CMTimeGetSeconds(curTime)
        if seconds < 0 {
            seconds = 0
        }
        self.videoPlaybackPosition = CGFloat(seconds)
        self.trimmerView.seek(toTime: CGFloat(seconds))
        
        if self.videoPlaybackPosition >= self.stopTime {
            self.videoPlaybackPosition = self.startTime
            self.seekVideoToPos(pos: self.startTime)
            self.trimmerView.seek(toTime: self.startTime)
        }
    }
    
    func seekVideoToPos(pos: CGFloat) {
        self.videoPlaybackPosition = pos
        guard let player = self.player else {return }
        let time = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), preferredTimescale: player.currentTime().timescale)
        self.player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {return }
        self.asset = AVAsset(url: url)
        guard let asset = self.asset else { return }
        
        let item = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: item)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer?.contentsGravity = .resizeAspect
        self.player?.actionAtItemEnd = .none
        guard let playerLayer = self.playerLayer else { return }
        self.videoLayer.layer.addSublayer(playerLayer)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnVideoLayer))
        self.videoLayer.addGestureRecognizer(tap)
        
        self.videoPlaybackPosition = 0
        self.tapOnVideoLayer(tap: tap)
        
        // set properties for trimmer view
        self.trimmerView.themeColor = .lightGray
        self.trimmerView.asset = asset
        self.trimmerView.showsRulerView = true
        self.trimmerView.rulerLabelInterval = 10
        self.trimmerView.trackerColor = .cyan
        self.trimmerView.delegate = self
        
        // important: reset subviews
        self.trimmerView.resetSubviews()
        self.trimButton.isHidden = false
    }
    
    @objc func tapOnVideoLayer(tap: UITapGestureRecognizer) {
        if self.isPlaying {
            self.player?.pause()
            self.stopPlaybackTimeChecker()
        } else {
            if restartOnPlay {
                self.seekVideoToPos(pos: self.startTime)
                self.trimmerView.seek(toTime: self.startTime)
            }
            self.player?.play()
        }
    }
}

