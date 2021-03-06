//
//  Camera.swift
//  Alib
//
//  Created by renan jegouzo on 28/02/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//
import Foundation
import AVFoundation
import Metal
import MetalKit

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Camera : NodeUI {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public let onNewFrame = Event<Void>()
    public private(set) var preview:Texture2D? {
        didSet {
            if let o = oldValue {
                o.detach()
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var textureCache: CVMetalTextureCache?
    var session: AVCaptureSession?
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public init(parent:NodeUI) {
        super.init(parent:parent)
        let result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, viewport!.gpu.device!, nil, &textureCache)
        if result != kCVReturnSuccess {
            Debug.error("CVMetalTextureCacheCreate() error: \(result)")
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override public func detach() {
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func metal(buffer:CVPixelBuffer) -> MTLTexture? {
        if let textureCache = self.textureCache {
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            var imageTexture: CVMetalTexture?
            let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, buffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &imageTexture)
            if result == kCVReturnSuccess, let t = imageTexture {
                return CVMetalTextureGetTexture(t)
            }
        }
        return nil
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func start() {
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.high
        let vdev = AVCaptureDevice.default(for:AVMediaType.video)
        if let vdev = vdev {
            do {
                let vinput = try AVCaptureDeviceInput(device: vdev)
                session!.addInput(vinput)
                let voutput = AVCaptureVideoDataOutput()
                voutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String:kCVPixelFormatType_32BGRA]
                voutput.alwaysDiscardsLateVideoFrames = true
                let vdel = VideoDelegate()
                vdel.onFrame.alive(self) { sampleBuffer in
                    if let imgbuf = CMSampleBufferGetImageBuffer(sampleBuffer), let mt = self.metal(buffer: imgbuf) {
                        let w = CVPixelBufferGetWidth(imgbuf)
                        let h = CVPixelBufferGetHeight(imgbuf)
                        self.preview = Texture2D(parent:self,size:Size(w,h),texture:mt)
                        self.onNewFrame.dispatch(())
                    }
                }
                voutput.setSampleBufferDelegate(vdel,queue:DispatchQueue.main)
                session!.addOutput(voutput)
                session!.startRunning()
            } catch {
                Debug.error("Camera.start(), error!")
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public func stop() {
        if let session = self.session {
            session.stopRunning()
            // TODO:
            self.session = nil
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class VideoDelegate : NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
        let onFrame = Event<CMSampleBuffer>()
        public func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            onFrame.dispatch(sampleBuffer)
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
