//
//  ApiManager.swift
//  ReshetPlayerPlugin
//
//  Created by MSApps on 23/12/2019.
//

import Foundation


@objc class ReshetPlayerApi: NSObject {
    
    var baseApi:String?
    var oviduisUserId:String?
    var oviduisCdnName:String?
    var oviduisCh:String?
    var liveDVRSupport = false
    
    
    required init(configurationJSON: NSDictionary?) {
        baseApi = configurationJSON?["OVIDIUS_base_url"] as? String ?? "https://13tv-api.oplayer.io/"
        oviduisUserId = configurationJSON?["OVIDIUS_user_id"] as? String ?? "45E4A9FB-FCE8-88BF-93CC-3650C39DDF28"
        oviduisCdnName = configurationJSON?["OVIDIUS_cdn_name"] as? String ?? "casttime"
        oviduisCh = configurationJSON?["OVIDIUS_ch"] as? String ?? "1"
        if let dvrSupportSting = configurationJSON?["support_live_dvr"] as? String{
            liveDVRSupport = (dvrSupportSting == "1")
        }else if let dvrSupportBool = configurationJSON?["support_live_dvr"] as? Bool{
            liveDVRSupport = dvrSupportBool
        }
    }
    
    let getVideoByName = "api/getlink/getVideoByFileName"
    let getVideoByLink = "api/getlink"
    
    func getVideoSrcByVideoName(videoName: String , completion: @escaping ((_ success: Bool , _ src: String?) -> Void)){
        let apiName = "\(baseApi!)\(getVideoByName)?userId=\(oviduisUserId!)&videoName=\(videoName)&serverType=appios"
        let url = URL(string: apiName)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        makeRequest(request: request) { (responseJson, response, error) in
            if(response?.statusCode == 200){
                if let json = responseJson as? [[String:Any]]{
                    if let mediaFile = json[0]["MediaFile"] as? String , let bitrates = json[0]["appIosBitrates"] as? String ,
                        let protocolType = json[0]["ProtocolType"] as? String, let serverAddress =  json[0]["ServerAddress"] as? String ,
                        let mediaRoot =  json[0]["MediaRoot"] as? String , let StreamingType =  json[0]["StreamingType"] as? String,
                        let appIosToken =  json[0]["appIosToken"] as? String
                        {
                        let mediaFileSrc = "\(mediaFile.dropLast(4))\(bitrates)\(mediaFile.dropFirst(mediaFile.count - 4))"
                        let src = "\(protocolType)\(serverAddress)\(mediaRoot)\(mediaFileSrc)\(StreamingType)\(appIosToken)"
                        completion(true , src)
                    }else{
                        completion(false , nil)
                    }
                }else{
                   completion(false , nil)
                }
            }else{
                completion(false , nil)
            }
        }
    }
    
    func getVideoSrcByLink(completion: @escaping ((_ success: Bool , _ src: String?) -> Void)){
        let apiName = "\(baseApi!)\(getVideoByLink)?userId=\(oviduisUserId!)&cdnName=\(oviduisCdnName!)&ch=\(oviduisCh!)&serverType=appios"
        let url = URL(string: apiName)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        makeRequest(request: request) { (responseJson, response, error) in
            if(response?.statusCode == 200){
                if let json = responseJson as? [[String:Any]]{
                    if let link  = json[0]["Link"] as? String{
                        if(self.liveDVRSupport){
                            var src = ""
                            if(link.contains("?")){
                                src = "\(link)&DVR=true"
                            }else{
                                src = "\(link)?DVR=true"
                            }
                             completion(true, src)
                        }else{
                            completion(true, link)
                        }
                    }else{
                        completion(false , nil)
                    }
                 }else{
                     completion(false , nil)
                }
            }else{
                 completion(false , nil)
            }
        }
    }
    
    private func makeRequest(request: NSMutableURLRequest, completion: @escaping ((_ result: Any?, _ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void)) {
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data , let json = (try? JSONSerialization.jsonObject(with: data, options: [])) else {
                completion(nil, (response as? HTTPURLResponse), error)
                return
            }
            
            print("Response: \(json)")
            if let json = json as? [[String:Any]]  {
                DispatchQueue.onMain {
                    completion(json, (response as? HTTPURLResponse), error)
                }
            }
            else {
                DispatchQueue.onMain {
                    completion(json, (response as? HTTPURLResponse), error)
                }
            }
        }
        task.resume()
    }
}


internal extension DispatchQueue {
    static func onMain(_ block: @escaping (() -> Void)) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
