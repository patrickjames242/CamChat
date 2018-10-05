//
//  Memory_Convenience.swift
//  CamChat
//
//  Created by Patrick Hanna on 10/4/18.
//  Copyright © 2018 Patrick Hanna. All rights reserved.
//

import Photos
import HelpKit
import CoreData


class MemoryActivityItemProvider: UIActivityItemProvider{
    private let memory: Memory
    init(memory: Memory){
        self.memory = memory
        super.init(placeholderItem: FileManager.default.documentsDirectoryUrl)
        
        
        
    }
    override var item: Any{
        return memory.info.url
    }
    
    override var activityType: UIActivity.ActivityType?{
        return UIActivity.ActivityType.saveToCameraRoll
    }
    
    
}




extension Memory{
    
    static func getActivityVCFor(memories: [Memory]) -> UIActivityViewController{
        let activitiyItems = memories.map{MemoryActivityItemProvider(memory: $0)}
        return UIActivityViewController(activityItems: activitiyItems, applicationActivities: nil)
    }
    
    static func delete(memories: [Memory]){
        if memories.isEmpty{ return }
        let context = memories.first!.context!
        context.perform {
            for memory in memories {
                handleErrorWithPrintStatement {
                    try FileManager.default.removeItem(at: memory.info.url)
                }
                context.delete(memory)
                
            }
            context.saveChanges()
        }
        
    }
    
    
    static func saveToCameraRoll(memories: [Memory], completion: @escaping (_ success: Bool) -> Void){
        
        switch PHPhotoLibrary.authorizationStatus(){
        case .authorized: performCameraRollSaveChanges(for: memories, completion: completion)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized{self.performCameraRollSaveChanges(for: memories, completion: completion)}
                else {completion(false)}
            }
        default: completion(false)
        }
        
    }

    private static func performCameraRollSaveChanges(for memories: [Memory], completion: @escaping (_ success: Bool) -> Void){
        PHPhotoLibrary.shared().performChanges({
            
            for memory in memories{
                switch memory.info {
                case .photo(let url):
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                case .video(let url):
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
            }
        }, completionHandler: {(wasSuccessful, error) in
            DispatchQueue.main.async {
                completion(wasSuccessful)
            }
        })
    }
    
    static func getImageForVideoAt(url: URL) -> UIImage{
        
        let clip = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: clip)
        if let cgImage = try? generator.copyCGImage(at: CMTime(value: 0, timescale: 1), actualTime: nil){
            return UIImage(cgImage: cgImage)
        } else { return UIImage() }
        
    }
    
}




