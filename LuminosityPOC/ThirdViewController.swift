//
//  ThirdViewController.swift
//  LuminosityPOC
//
//  Created by Chandra Bhushan on 13/11/20.
//

import UIKit
import AVFoundation

class ThirdViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var lightValueLabel: UILabel!

    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?
    var cameraPosition: AVCaptureDevice.Position = .front
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: AVMediaType.video,
                                                                position: cameraPosition)
        if discoverySession.devices.count <= 0 { return }
        device = discoverySession.devices[0]
        
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch {
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        
        let queue = DispatchQueue(label: "cameraQueue")
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
        
        captureSession = AVCaptureSession()
        captureSession?.addInput(input)
        captureSession?.addOutput(output)
        captureSession?.sessionPreset = AVCaptureSession.Preset.photo
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: view.frame.height)
        
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        captureSession?.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let lightValue = getBrightness(sampleBuffer: sampleBuffer)
        switch lightValue {
        case -7 ... -4:
            setLabelText(text: "LOW LIGHT", lightValue: lightValue)
        default:
            setLabelText(text: "ENOUGH LIGHT", lightValue: lightValue)
        }
    }
    
    func setLabelText(text: String, lightValue: Double){
        DispatchQueue.main.async { [weak self] in
            self?.label.text = text
            self?.lightValueLabel.text = lightValue.description
        }
    }
    
    func getBrightness(sampleBuffer: CMSampleBuffer) -> Double {
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        let brightnessValue : Double = exifData?[kCGImagePropertyExifBrightnessValue as String] as! Double
        print(brightnessValue)
        return brightnessValue
    }

}

