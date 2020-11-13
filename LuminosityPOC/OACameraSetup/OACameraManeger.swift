//
//  OACameraManeger.swift
//  OneAssist-Swift
//
//  Created by Ankur Batham on 12/09/20.
//  Copyright © 2020 OneAssist. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

open class OACameraManeger: NSObject {
    typealias OACameraManegerCompletion = (UIImage?, Error?) -> Void
    
    // MARK: - Private Variables
    /// camera UIView
    private var cameraView: UIView?
    /// preview layer for camera
    private var previewLayer: AVCaptureVideoPreviewLayer!
    /// view data output
    fileprivate var capturePhotoOutput: AVCapturePhotoOutput!
    /// camera session
    fileprivate var captureSession: AVCaptureSession!
    
    fileprivate var  captureDevice: AVCaptureDevice!
    
    // MARK: - Public Variables
    /// completion block
    var onPhotoCapture: OACameraManegerCompletion?
    
    /// camera device position
    var cameraPosition: CameraDevice = .back
    // MARK: - Open Actions
    /**
     Setup the camera preview.
     - Parameter in:   UIView which camera preview will show on that.Actions
     - Parameter withPosition: a AVCaptureDevicePosition which is camera device position which default is back
     */
    open func captureSetup(in cameraView: UIView,
                           withPosition cameraPosition: AVCaptureDevice.Position? = .back) throws {
        self.cameraView = cameraView
        self.captureSession = AVCaptureSession()
        switch cameraPosition! {
        case .back:
            try captureSetup(withDevicePosition: .back)
            self.cameraPosition = .back
        case .front:
            try captureSetup(withDevicePosition: .front)
            self.cameraPosition = .front
        default:
            try captureSetup(withDevicePosition: .back)
        }
    }
    
    /**
     Start Running the camera session.
     */
    open func startRunning() {
        if captureSession != nil && captureSession?.isRunning != true {
            self.captureSession.startRunning()
        }
    }
    
    /**
     Stop the camera session.
     */
    open func stopRunning() {
        if captureSession?.isRunning == true {
            self.captureSession.stopRunning()
        }
    }
    
    /**
     Update frame of camera preview
     */
    open func updatePreviewFrame() {
        if cameraView != nil {
            self.previewLayer?.frame = cameraView!.bounds
        }
    }
    
    /**
      Get Image of the preview camera
     */
    open func capture() {
        self.previewLayer?.connection?.isEnabled = true
        let photoSettings = AVCapturePhotoSettings()
        if ( photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
            photoSettings.previewPhotoFormat = [ kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes[0] ] // The first format in the array is the preferred format
        }
        photoSettings.isHighResolutionPhotoEnabled = true
        self.capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    // MARK: - Private Actions
    /**
     this func will setup the camera and capture session and add to cameraView
     - Parameter withDevicePosition:   AVCaptureDevicePosition which is the position of camera
     */
    fileprivate func getDevice(withPosition position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        if #available(iOS 10.0, *) {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                throw OACameraError.noDevice
            }
            return device
        } else {
            guard let device = AVCaptureDevice
                .devices(for: .video)
                .first(where: {device in
                    device.position == position
                }) else {
                    throw OACameraError.noDevice
            }
            return device
        }
    }
    
    fileprivate func captureSetup (withDevicePosition position: AVCaptureDevice.Position) throws {
        self.stopRunning()
        previewLayer?.removeFromSuperlayer()
        self.captureSession.automaticallyConfiguresApplicationAudioSession = false
        self.captureSession.sessionPreset = .photo
        //remove all inputs if available
        for input in self.captureSession.inputs {
            self.captureSession.removeInput(input)
        }
        //remove all outputs if available
        for output in self.captureSession.outputs {
            self.captureSession.removeOutput(output)
        }
        
        self.captureSession.beginConfiguration()
        
        // device
        captureDevice = try getDevice(withPosition: position)
        
        //Input
        var input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            input = nil
        }
        
        guard let deviceInput = input, self.captureSession.canAddInput(deviceInput) else {
            self.captureSession.commitConfiguration()
            throw OACameraError.noDevice
        }
        
        //Add Input
        captureSession?.addInput(deviceInput)
        
        //Output
        capturePhotoOutput = AVCapturePhotoOutput()
        
        guard self.captureSession.canAddOutput(capturePhotoOutput) else {
            self.captureSession.commitConfiguration()
            throw OACameraError.noDevice
        }
        
        //Add Output
        captureSession.addOutput(capturePhotoOutput)
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        self.captureSession.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let cameraView = cameraView {
            previewLayer?.frame = cameraView.bounds
            previewLayer.position = CGPoint(x: cameraView.bounds.midX, y: cameraView.bounds.midY)
        }
        
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView?.layer.insertSublayer(previewLayer, at: 0)
                
        self.startRunning()
        
        setupExposureMode()
    }
    
    func setupExposureMode() {
        do {
            try self.captureDevice.lockForConfiguration()
            if self.captureDevice.isExposureModeSupported(.locked) {
                self.captureDevice.exposureMode = .locked
            }
            self.captureDevice.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
}

//MARK: AVCapturePhotoCaptureDelegate

extension OACameraManeger: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // dispose system shutter sound
        if cameraPosition != .back {
            AudioServicesDisposeSystemSoundID(1108)
        }
    }
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            self.onPhotoCapture?(nil, error)
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let data = photo.fileDataRepresentation() else {
                self?.onPhotoCapture?(nil, nil)
                return
            }
            let image = UIImage(data: data)?.fixedOrientation()
            DispatchQueue.main.async {
                self?.onPhotoCapture?(image, error)
            }
        }
    }
    
    @available(iOS, introduced: 10.0, deprecated: 11.0)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil, let sampleBuffer =  photoSampleBuffer else {
            self.onPhotoCapture?(nil, error)
            return
        }
        
        guard let outputImage = getImageFromSampleBuffer(sampleBuffer: sampleBuffer) else {
            return
        }
        let image = outputImage.fixedOrientation()
        self.onPhotoCapture?(image, error)
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                            didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                            error: Error?) {
        
        guard error == nil else {
            self.onPhotoCapture?(nil, error)
            return
        }
    }
    
    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        // self.saveLogs("1 --- pixelBuffer get")
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }
}
