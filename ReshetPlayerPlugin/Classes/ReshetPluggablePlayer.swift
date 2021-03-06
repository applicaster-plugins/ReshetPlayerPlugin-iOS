//
// ReshetPluggablePlayer.swift
//
//  Created by Roi Kedarya on 03/12/2019.
//
import ApplicasterSDK
import ZappPlugins
import UIKit

var kantarSensor:KMA_SpringStreams?

public class ReshetPluggablePlayer: APPlugablePlayerBase, ZPAppLoadingHookProtocol {
    
    var serverTimeUrl: String?
    var playerViewController: ReshetPlayerViewController?
    var currentPlayableItem: ZPPlayable?
    
    public required override init() { }

    public required init(configurationJSON: NSDictionary?) {
        if(kantarSensor == nil){
            if let siteName = configurationJSON?["kantar_site_key"] as? String, let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                 kantarSensor = KMA_SpringStreams.getInstance(siteName, a: displayName)
            }
        }
    }
    
    public static func pluggablePlayerInit(playableItem item: ZPPlayable?) -> ZPPlayerProtocol?{
        if let item = item {
            return self.pluggablePlayerInit(playableItems: [item])
        }
        return nil
    }
    
    open class func pluggablePlayerInit(playableItems items: [ZPPlayable]?, configurationJSON: NSDictionary? = nil) -> ZPPlayerProtocol?{
        let instance = ReshetPluggablePlayer()
        instance.currentPlayableItems = items
        instance.currentPlayableItem = items?.first
        instance.configurationJSON = configurationJSON
        
        if((instance.currentPlayableItem?.isLive())!){
            ReshetPlayerApi(configurationJSON: configurationJSON).getVideoSrcByLink { (success, src) in
                if(success){
                    if let videoSrc = src{
                        instance.playerViewController?.replaceSrc(videoSrc)
                    }
                }
            }
        }else{
            if let videoName = instance.currentPlayableItem?.identifier as String?{
                ReshetPlayerApi(configurationJSON: configurationJSON).getVideoSrcByVideoName(videoName: videoName) { (success, src) in
                    if(success){
                        if let videoSrc = src{
                            instance.playerViewController?.replaceSrc(videoSrc)
                        }
                    }
                }
            }
        }
        
        if let configurationJSON = configurationJSON as? [AnyHashable : Any] {
            instance.playerViewController = ReshetPlayerViewController(playableItems: items,
                                                                     withArtiMediaParams: configurationJSON)
        } else {
            instance.playerViewController = ReshetPlayerViewController(playableItems: items)
        }
        
        if let sensor = kantarSensor {
             instance.playerViewController?.tracker = sensor
        }
      
        
        if let configurationJSON = configurationJSON as? [AnyHashable : Any],
            let useCustomVideoLoadin = configurationJSON["use_custom_video_loading"] as? String,
            useCustomVideoLoadin.boolValue() == true,
            let playerViewController = instance.playerViewController,
            let playerController = playerViewController.playerController {
            // set the video loading view
            playerController.loadingView = instance.videoLoadingView()
            if let ServerTimeString = configurationJSON["server_time_url"] as? String {
                instance.serverTimeUrl = ServerTimeString
            } else {
                instance.serverTimeUrl = "https://13tv.co.il/timestamp.php"
            }
        }
        
        return instance;
    }
    
    public override func presentPlayerFullScreen(_ rootViewController: UIViewController, configuration: ZPPlayerConfiguration?) {
        super .presentPlayerFullScreen(rootViewController, configuration: configuration)
        if let playerViewController = self.playerViewController {
            playerViewController.currentPlayerDisplayMode = APPlayerViewControllerDisplayMode.fullScreen
            playerViewController.controls = playerViewController.reshetPlayerControls()
            addObserver()
        }
    }
    
    public override func pluggablePlayerAddInline(_ rootViewController: UIViewController, container: UIView) {
        super .pluggablePlayerAddInline(rootViewController, container: container)
        if let playerViewController = self.playerViewController {
            playerViewController.currentPlayerDisplayMode = APPlayerViewControllerDisplayMode.inline
            playerViewController.controls = playerViewController.reshetInlinePlayerControls()
            playerViewController.modalPresentationStyle = .fullScreen
        }
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stop),
            name: NSNotification.Name(rawValue: "APPlayerControllerReachedEndNotification"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stop),
            name: NSNotification.Name(rawValue: "APPlayerDidStopNotification"),
            object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name(rawValue: "APPlayerControllerReachedEndNotification"), object:nil)
        
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name(rawValue: "APPlayerDidStopNotification"), object:nil)
        
    }
    
    
    @objc func stop() {
        removeObservers()
        let weakSelf = self
        self.playerViewController?.dismiss(animated: true, completion: {
            weakSelf.currentPlayableItem = nil
        })
    }
    
    public func videoLoadingView() -> (UIView & APLoadingView)? {
        var loadingView: (UIView & APLoadingView)?
        
        if let videoLoadingView = (Bundle(for: ReshetPluggablePlayer.self).loadNibNamed("ReshetPlayerVideoLoadingView", owner: self, options: nil)?.first) {
            loadingView = videoLoadingView as? UIView & APLoadingView
        }
        return loadingView
    }
    
    
    
    public func executeOnApplicationReady(displayViewController: UIViewController?, completion: (() -> Void)?) {
        self.getServerForCurrentTime()
        completion?();
    }
    
    func getServerForCurrentTime() {
//        if let serverTimeUrl = serverTimeUrl {
        let serverTimeUrl = "https://13tv.co.il/timestamp.php"
        APNetworkManager.requestDataObject(forUrlString: serverTimeUrl, method: APNetworkManager.httpMethodGET(), parameters: nil) { (success, responseObject, error, statusCode, textEncodingName) in
            if let responseObject = responseObject, success == true,
                let dateString = String(data: responseObject, encoding: .utf8) {
                self.setDeltaFromDateString(serverDateString: dateString)
            }
        }
    //        }
    }
    
    func setDeltaFromDateString(serverDateString:String) {
        if let ServerTime = self.stringToDate(dateString: serverDateString) {
            //serverTime - Now = delta
            let deltaTimeToServer = ServerTime.timeIntervalSinceNow
            if let storageDelegate = ZAAppConnector.sharedInstance().storageDelegate {
                let deltaString = String(format: "%f", deltaTimeToServer)
                let _ = storageDelegate.sessionStorageSetValue(for: "deltaTimeToServer", value: deltaString, namespace: "deltaTimeToServer")
            }
        }
    }
    
    func stringToDate(dateString:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString)
    }
    
    public override func pluggablePlayerViewController() -> UIViewController? {
        return self.playerViewController
    }
    
    public func pluggablePlayerCurrentPlayableItem() -> ZPPlayable? {
        return currentPlayableItem
    }
    
    open override func pluggablePlayerType() -> ZPPlayerType {
        return ReshetPluggablePlayer.pluggablePlayerType()
    }
    
    public static func pluggablePlayerType() -> ZPPlayerType {
        return .undefined
    }
    
}



