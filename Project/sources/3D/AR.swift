//
//  AR.swift
//  Alib
//
//  Created by renan jegouzo on 23/09/2017.
//  Copyright © 2017 aestesis. All rights reserved.
//

import Foundation
import ARKit

class ARDelegate : NSObject, ARSessionDelegate {
    enum AnchorCommand {
        case add
        case update
        case remove
    }
    let frame:(ARFrame)->()
    let anchors:(AnchorCommand,[ARAnchor])->()
    public init(frame:@escaping (ARFrame)->(),anchors:@escaping (AnchorCommand,[ARAnchor])->()) {
        self.frame = frame
        self.anchors = anchors
        super.init()
    }
    @objc public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.frame(frame)
    }
    @objc public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        self.anchors(.add,anchors)
    }
    @objc public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        self.anchors(.update,anchors)
    }
    @objc public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        self.anchors(.remove,anchors)
    }
}
public class AR : NodeUI {
    let session : ARSession
    var delegate : ARSessionDelegate? = nil
    var texcache : CVMetalTextureCache? = nil
    public private(set) var running : Bool = false
    public private(set) var image : Bitmap? = nil
    public private(set) var camera : CameraInfo = CameraInfo()
    public init(parent:NodeUI) {
        self.session = ARSession()
        super.init(parent:parent)
        CVMetalTextureCacheCreate(nil, nil, self.viewport!.gpu.device!, nil, &texcache)
        self.delegate = ARDelegate(frame:{ frame in
            let w = CVPixelBufferGetWidth(frame.capturedImage)
            let h = CVPixelBufferGetHeight(frame.capturedImage)
            if let tc = self.texcache {
                var t : CVMetalTexture?
                if CVMetalTextureCacheCreateTextureFromImage(nil, tc, frame.capturedImage, nil, .bgra8Unorm, w, h, 0, &t) == kCVReturnSuccess, let tt = t, let mt = CVMetalTextureGetTexture(tt) {
                    self.ui {
                        if let o = self.image {
                            o.detach()
                        }
                        self.image = Bitmap(parent:self, texture:Texture2D(parent: self, size: Size(Double(w),Double(h)), texture: mt))
                    }
                }
                let cam = frame.camera
                switch cam.trackingState {
                case .notAvailable:
                    self.camera.state = .none
                case .limited(_):
                    self.camera.state = .limited
                case .normal:
                    self.camera.state = .normal
                }
                self.camera.euler = Euler(pitch:Double(cam.eulerAngles[1]),roll:Double(cam.eulerAngles[0]),yaw:Double(cam.eulerAngles[3]))
                self.camera.transform = Mat4(cam.transform)
                self.camera.intrinsics = Mat4(cam.intrinsics)
                self.camera.projection = Mat4(cam.projectionMatrix)
            }
        }, anchors: { command,anchors in
            switch command {
            case .add:
                break
            case .update:
                break
            case .remove:
                break
            }
        })
        self.session.delegate = self.delegate
    }
    override public func detach() {
        session.pause()
        session.delegate = nil
        self.delegate = nil
        self.texcache = nil
        super.detach()
    }
    public func run() {
        if !running {
            session.run(ARWorldTrackingConfiguration(),options:.resetTracking)
            running = true
        }
    }
    public func pause() {
        if running {
            session.pause()
            running = false
        }
    }
    public struct CameraInfo {
        public enum TrackingState {
            case none
            case limited
            case normal
        }
        public var state : TrackingState
        public var intrinsics: Mat4
        public var transform : Mat4
        public var projection : Mat4
        public var euler : Euler
        public init() {
            state = .none
            intrinsics = Mat4.identity
            transform = Mat4.identity
            projection = Mat4.identity
            euler = Euler()
        }
    }
}
public class ARView : RendererView {
    let ar : String
    var nframes : Int = 0
    override public func draw(to g: Graphics) {
        self.nframes = viewport!.nframes
        if let ar = self[self.ar] as? AR {
            ar.run()
            if let b=ar.image {
                g.draw(rect:self.bounds,image:b,from:b.bounds.crop(self.bounds.ratio))
            }
        }
        super.draw(to:g)
    }
    public init(superview: View, layout: Layout, ar:String) {
        self.ar = ar
        super.init(superview:superview,layout:layout)
        viewport!.pulse.alive(self) {
            if self.viewport!.nframes-self.nframes == 2, let ar = self[self.ar] as? AR{
                ar.pause()
            }
        }
    }
}
