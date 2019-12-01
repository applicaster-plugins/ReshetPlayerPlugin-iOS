//
// ReshetPluggablePlayer.swift
//
//  Created by Avi Levin on 05/07/2018.
//
import ApplicasterSDK
import ZappPlugins
import UIKit

public class ReshetPluggablePlayer: APPlugablePlayerDefault {
    
    open override class func pluggablePlayerInit(playableItems items: [ZPPlayable]?, configurationJSON: NSDictionary? = nil) -> ZPPlayerProtocol?{
        let instance = ReshetPluggablePlayer()
        instance.currentPlayableItems = items
        instance.configurationJSON = configurationJSON
        
        if let configurationJSON = configurationJSON as? [AnyHashable : Any] {
            instance.playerViewController = ReshetPlayerViewController(playableItems: items,
                                                                     withArtiMediaParams: configurationJSON)
        } else {
            instance.playerViewController = ReshetPlayerViewController(playableItems: items)
        }
        
        if let configurationJSON = configurationJSON as? [AnyHashable : Any],
            let useCustomVideoLoadin = configurationJSON["use_custom_video_loading"] as? String,
            useCustomVideoLoadin.boolValue() == true,
            let playerViewController = instance.playerViewController,
            let playerController = playerViewController.playerController {
            // set the video loading view
            playerController.loadingView = instance.videoLoadingView()
        }
        
        return instance;
    }
 
    public func videoLoadingView() -> (UIView & APLoadingView)? {
        var loadingView: (UIView & APLoadingView)?
        
        if let videoLoadingView = (Bundle(for: ReshetPluggablePlayer.self).loadNibNamed("ReshetPlayerVideoLoadingView", owner: self, options: nil)?.first) {
            loadingView = videoLoadingView as? UIView & APLoadingView
        }
        return loadingView
    }
    
}



