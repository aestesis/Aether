//
//  ComputePass.swift
//  Alib
//
//  Created by renan jegouzo on 14/10/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

public class Filter : NodeUI {
    let kernel:MPSUnaryImageKernel
    public func process(source:Texture2D,destination:Texture2D,_ fn:@escaping ()->()) {
        let cb=viewport!.gpu.queue.makeCommandBuffer()
        kernel.encode(commandBuffer:cb!,sourceTexture:source.texture!,destinationTexture:destination.texture!)
        cb?.addCompletedHandler { cb in
            fn()
        }
        cb?.commit()
    }
    public init(viewport:Viewport,blur sigma:Double) {
        kernel = MPSImageGaussianBlur(device:viewport.gpu.device!,sigma:Float(sigma))
        kernel.edgeMode = .clamp
        super.init(parent:viewport)
    }
}
