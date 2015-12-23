//
//  MXNImageFilter.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import Foundation
import MetalKit

class MXNImageFilter: MXNTextureProvider, MXNTextureConsumer, MXNDrawablePresentable {
    var context: MXNContext!
    var uniformBuffer: MTLBuffer?
    var pipeline: MTLComputePipelineState!
    var isDirty: Bool = true
    var provider: MXNTextureProvider?
    var kernalFunction: MTLFunction!
    var texture: MTLTexture! {
        get {
            if isDirty {
                applyFilter()
            }
            return internalTexture
        }
    }
    var internalTexture: MTLTexture?
    var shouldWaitUntilCompleted: Bool = true
    
    required init?(functionName: String, context: MXNContext) {
        guard context.device != nil && context.commandQueue != nil && context.library != nil else { return nil }
        
        self.context = context
        self.kernalFunction = context.library!.newFunctionWithName(functionName)
        if self.kernalFunction == nil { return nil }
        do {
            try self.pipeline = context.device!.newComputePipelineStateWithFunction(self.kernalFunction)
        } catch {
            return nil
        }
    }
    
    func configureArgumentTableWithCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {}
    
    func applyFilter() {
        guard let inputTexture = self.provider?.texture else { return } // one should always have provider
        if internalTexture == nil || internalTexture?.width != inputTexture.width || internalTexture?.height != inputTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat,
                width: inputTexture.width, height: inputTexture.height, mipmapped: false)
            internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
        
        guard let commandBuffer = context.commandQueue?.commandBuffer() else { return }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setTexture(inputTexture, atIndex: 0) // read texture
        commandEncoder.setTexture(internalTexture, atIndex: 1) // write texture
        configureArgumentTableWithCommandEncoder(commandEncoder) // do shader specific stuff
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        if shouldWaitUntilCompleted { commandBuffer.waitUntilCompleted() }
    }
    
    func putBufferUniforms(var uniform: Any, into commandEncoder: MTLComputeCommandEncoder, size: Int, offset: Int, atIndex index: Int) {
        if uniformBuffer == nil {
            uniformBuffer = context.device?.newBufferWithLength(size, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        }
        withUnsafePointer(&uniform) { pointer in
            memcpy(uniformBuffer!.contents(), pointer, size)
            commandEncoder.setBuffer(uniformBuffer, offset: offset, atIndex: index)
        }
    }
    
    func presentToDrawable(drawable: CAMetalDrawable) {
        guard let inputTexture = self.provider?.texture else { return } // one should always have provider
        if internalTexture == nil || internalTexture?.width != inputTexture.width || internalTexture?.height != inputTexture.height {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(inputTexture.pixelFormat,
                width: inputTexture.width, height: inputTexture.height, mipmapped: false)
            internalTexture = context.device?.newTextureWithDescriptor(textureDescriptor)
        }
        
        let threadgroupCounts = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(inputTexture.width / threadgroupCounts.width, inputTexture.height / threadgroupCounts.height, 1)
        
        guard let commandBuffer = context.commandQueue?.commandBuffer() else { return }
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setTexture(inputTexture, atIndex: 0) // read texture
        commandEncoder.setTexture(drawable.texture, atIndex: 1) // write texture
        configureArgumentTableWithCommandEncoder(commandEncoder) // do shader specific stuff
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        commandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
}