//
//  KMA_SpringStreams.h
//  KMA_SpringStreams
//
//  Created by Frank Kammann on 26.08.11.
//  Copyright 2017 Kantar Media. All rights reserved.
//
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@class KMA_SpringStreams, KMA_Stream;


/** The notification name for the debugging purpose, register this notification into the notification center by following API or similar:
 *(void)addObserver:(id)observer seKMA_MediaPlayerAdapterMA_STREAMING_DEBUGINTERFACE_NOTIFICATION object:(nullable id)anObject;
 *Also, you would need to implement the selecotor method to consume the debug info.
 *The debug info is attached in the notification as a NSDictionary, with keys "Request" and "Statuscode". The info can be fetched by The API: [NSNotification object]
 */

extern NSString *const KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION;

/**
 * The meta object has to be delivered by a KMA_StreamAdapter and
 * contains meta information about the system.
 */
@interface KMA_Player_Meta : NSObject<NSCoding, NSCopying> {
}
/**
 * Returns the player name
 *
 * @return the string "iOS Player"
 */
@property (retain,readwrite) NSString *playername;


/**
 * Returns the player version.
 * The itselfs has no version so the system version is delivered.
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html
 *
 * @return The version my calling [UIDevice currentDevice].systemVersion
 */
@property (retain,readwrite) NSString *playerversion;

/**
 * Returns the screen width my calling the method
 * [[UIScreen mainScreen] bounds].screenRect.size.width
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
 *
 * @return the width
 */
@property (assign,readwrite) int screenwidth;

/**
 * Returns the screen width my calling the method
 * [[UIScreen mainScreen] bounds].screenRect.size.height
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
 *
 * @return the height
 */
@property (assign,readwrite) int screenheight;

@end


/**
 * Implement this protocol to measure a streaming content.
 */
@protocol KMA_StreamAdapter
@required
/**
 * Returns the information about the player.
 */
-(KMA_Player_Meta*) getMeta;
/**
 * Returns a positive position on the stream in seconds.
 */
-(int) getPosition;
/**
 * Returns the duration of the stream in seconds.
 * If a live stream is playing, in most cases it's not possible to deliver a valid stream length.
 * In this case, the value 0 must be delivered. <b>Internally the duration will be set once if it is
 * greater than 0</b>.
 */
-(int) getDuration;
/**
 * Returns the width of the video.
 * If the content is not a movie the value 0 is to be delivered.
 */
-(int) getWidth;
/**
 * Returns the height of the video.
 * If the content is not a movie the value 0 is to be delivered.
 */
-(int) getHeight;

/**
* Method to check if Chromecast sesion is enabled. 
* This defaults to no. If at all sensor is used in context of chromecast, please override adapter with new one available in package
*/
-(BOOL) isCastingEnabled;
@end

/**
 * The sensor which exists exactly one time in an application and manage
 * all streaming measurement issues.
 * When the application starts the sensor has to be instantiated one time
 * with the method `getInstance:site:app`.
 * The next calls must be transmtted by the method `getInstance`.
 *
 * @see getInstance:a
 * @see getInstance
 */
@interface KMA_SpringStreams : NSObject {
}
/** Enable or disable usage tracking. (default: true) */
@property (readwrite) BOOL tracking;
/**
 * When set to true (default:false) the library logs the internal actions.
 * Each error is logged without checking this property.
 */
@property (readwrite,nonatomic) BOOL debug;
/**
 * Internally it sends http requests to the measurement system.
 * This property sets a timeout for that purpose.
 */
@property(assign) NSTimeInterval timeout;

/** Enable or disable offline mode. It will be configured in the release process. Please refer to Main page for more Info*/
@property (readwrite) BOOL offlineMode;

#ifndef NOT_UNIVERSAL

/**
 * Returns the instance of the sensor which is initialized with
 * a site name and an application name.
 * @warning
 *   The site name and the application name will be predefined
 *   by the measurement system operator.
 *
 * This method has to be called the first time when the application is starting.
 *
 * @see getInstance
 * @throws An exception is thrown when this method is called for a second time.
 */
+ (KMA_SpringStreams*) getInstance:(NSString*)site a:(NSString*)app;

/**
 * Returns the instance of the sensor which is initialized with
 * a site name and an application name.
 * This method enables user to stop the ad tracking by using boolean parameter AIEnabled.
 
 * This method has to be called the first time when the application is starting.
 * @see getInstance: a
 * @see getInstance
 * @throws An exception is thrown when this method is called for a second time.
 */

+ (KMA_SpringStreams*) getInstance:(NSString*)site a:(NSString*)app b:(BOOL)AIEnabled;

#endif

/**
 * Returns the instance of the sensor.
 *
 * @see getInstance:a
 * @throws An exception is thrown when this method is called with
 *         a previous call of the method `getInstance:a`.
 */
+ (KMA_SpringStreams*) getInstance;

/**
 * Call this method to start a tracking of a streaming content.
 * The sensor gets access to the KMA_Stream through the given adapter.
 * The variable *name* is mandatory in the attributes object.
 *
 * @see KMA_StreamAdapter
 * @see KMA_Stream
 *
 * @param stream The KMA_StreamAdapter which handles the access to
 *        the underlying streaming content
 * @param atts A map which contains information about the streaming content.
 *
 * @throws An exception if parameter *KMA_Stream* or *atts* is null.
 * @throws An exception if the mandatory name attributes are not found.
 *
 * @return A instance of KMA_Stream which handles the tracking.
 */
- (KMA_Stream*) track:(NSObject<KMA_StreamAdapter> *)stream atts:(NSDictionary *)atts;

//For more information on this preprocessor directive please check doxyfile.barb
#ifndef DOXYGEN_SHOULD_SKIP_THIS
/**
 * @internal New Track Method for BARB which takes additional parameter handle(UID retrieved using getNextUID())
 */

-(KMA_Stream*) track:(NSObject<KMA_StreamAdapter> *)stream atts:(NSDictionary *)atts handle:(NSString*) handle;
/**
 * @internal
 * This method is called to retrieve UID ahead of measurement.
 */
-(NSString *) getNextUID;

#endif /* DOXYGEN_SHOULD_SKIP_THIS */


/**
 * When the method is called all internal tracking processes will be terminated.
 * Call this method when the application is closing.
 */
- (void) unload;

/**
 * Returns the encrypted (md5) and truncated mobile identifiers.
 * The MAC ID is stored with the key 'mid'
 * The advertising ID is stored with the key 'ai'
 * The Vendor ID is stored with the key 'ifv'
 */
- (NSMutableDictionary *) getEncrypedIdentifiers;

@end


/**
 * The KMA_Stream object which is returned from the sensor when is called
 * the `track` method.
 */
@interface KMA_Stream : NSObject<NSCopying> {
}
/**
 * Stops the tracking on this KMA_Stream.
 * It is not possible to reactivate the tracking.
 */
- (void) stop;

/**
 * Returns the UID of the stream.
 */
- (NSString*) getUid;

@end


#if TARGET_OS_IOS

/**
 * The predefined adapter for the system standard player.
 *
 * @see MediaPlayer/Mediaplayer.h.
 *
 */
@interface KMA_MediaPlayerAdapter : NSObject<KMA_StreamAdapter> {
}
/**
 * Inits the adapter with the MPMoviePlayerController instance.
 *
 * @param player The MPMoviePlayerController
 */
- (KMA_MediaPlayerAdapter*) adapter:(AVPlayerViewController *)player;
@end
#endif


/**
 * @mainpage
 
 <div align="center">
 <h2>Kantar Media Streaming Sensor iOS User Manual</h2>
 </div>

<div>
    <h3 style="color: red">AppStore Submission with iOS 11</h3>
    <p>Please be aware that if you do not include the AdSupport.framework in your app you will have to disable the use of the IDFA via API in the constructor. Otherwise your App may be rejected from the AppStore for legal reasons.</p>
    <p>For more information see the API documentation of the constructor.</p>
</div>

 <div style="background-color: grey;" >
 <div align="center">

 <h3>Migration to iOS 9 </h3>
 
 </div>
 <h2 style="color:blue;">From version 1.4.0, KMA measuerment libraries will not support iOS6 any more. Kantar Media Streaming library components are all with KMA as prefix from this version, please read more in the API documentation.</h2>
 <h3>URL Scheme</h3>
 <p>Starting on iOS 9, iOS apps will have to declare what URL schemes they would like to be able to check for and open in the configuration files (plist file) of the app as it is submitted to Apple. So if your application is combining with a specific "Panel App" (e.g. Virtualmeter App), please register the URL scheme in your application, the syntax is as following:</p>
 
 <div style="border:1px solid black;">
 <br>&lt;key&gt;LSApplicationQueriesSchemes&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&lt;array&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;string&gt;<span class="marker"><span style="color:#0000CD;">@newPanelApp</span>&lt;</span>/string&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;string&gt;<span style="color:#0000CD;"><span class="marker">@oldPanelApp</span></span>&lt;/string&gt;
 <br>&nbsp;&nbsp; &nbsp;&lt;/array&gt;</div>
 
 <p>please contact your library provider for the URL scheme</p>
 
 
 <h3>App Transport Security (ATS)</h3>
 <p>Starting from iOS 9.0, App Transport Security (ATS) enforces best practices in the secure connections between an app and its back end. Migrating from http to https has to be planed for the more secure communication. However for this moment, if you decide to keep http in KMA_Spring library, please add following into the project plist file, otherwise please activate ssl on in the library. </p>
 
 <div style="border:1px solid black;">
 &lt;key&gt;NSAppTransportSecurity&lt;/key&gt;
 <br>&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSAllowsArbitraryLoads&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;false/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSExceptionDomains&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;<span style="color:#0000CD;">@domain</span>&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSIncludesSubdomains&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;true/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSTemporaryExceptionAllowsInsecureHTTPLoads&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;true/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSExceptionRequiresForwardSecrecy&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;false/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;/dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;/dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&lt;/dict&gt;</div>
 <p><i><span class="marker"><span style="color:#0000CD;">if</span></span> ATS is not enabled in your application, as NSAllowsArbitraryLoads = true, then you don't need to modify anything.
 </i></p>
 
 <h3>Notification registration for debug purpose</h3>
 
 <p>From KMA streaming iOS version 1.4.4, a notification is inserted into the implementation, so that the customers are able to retrieve the requests sent by the library, see more info #KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION. The notification contains a NSDictionary object, with the keys, "Request" and "Statuscode". With the following implementation, it is sample to fetch the debug information.</p>
 <pre><code>
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@ selector(handleApplicationEvent:) name:KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION object:nil];
 &minus; (void) handleApplicationEvent:(NSNotification *)n {
 if(KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION == [n name]) {
    &nbsp;&nbsp;&nbsp;&nbsp; have the implementation
 }
 }
 </code></pre>
 <p><i>Please Note: Set the debug mode (KMA_SpringStreams.debug) to false in your live product, otherwise there will be a debug flag in the measurement request.
 </i></p>
 
 <h3>BitCode</h3>
 <p>Bitcode is a new feature on iOS 9, an intermediate representation of a compiled program. Now you have the new KMA_SpringStreams lib with bitcode enabled, for your application you have the chance to enable or disable the bitcode service.</p>
 </div>
 
 <h3>Integration into Swift Project</h3>
  <div>
 <p>If the project is a Swift project, a swift bridging header file is required for the integration, more tutorial can be found here:  https://kantarmedia.atlassian.net/wiki/spaces/public/pages/159726961/Tutorial+on+how+to+import+KMA+measurement+Objective-C+library+into+Swift+project</p>
 </div>
 
 <h3>Offline Mode</h3>
 <p>Kantar Media Streaming Sensor iOS has feature so called "offlineMode". This mode can be switched on and off by using public API: KMA_SpringStreams.offlineMode.
 If the lib is configured to offlineMode, KMA_SpringStreams library will hold all requests in a local buffer and send them when the device goes back online. KMA_SpringStreams lib checks the Internet connection regularly by using the iOS Timer and send the data as soon as possible.
 Please notice:
 -# Old requests will be dropped if too many requests pump into local buffer for the limitation in buffer size. The default buffer size is 500. The data will be stored in a local file, so the lib will not lose the requests even if the application terminates.
 -# KMA_SpringStreams lib tries to send the requests in a fixed rate, 10 seconds by default, and sends them if device is online.</p>

<h3>Chromecast support</h3>
<div>
  <p>
    In order to measure videos, which are casted to a Chromecast device, the KMA_MediaPlayerAdapter_Chromecast has to be used or extended instead of the default KMA_MediaPlayerAdapter. The KMA_MediaPlayerAdapter_Chromecast automatically detects, if the video is played locally on the iOS device or if it is casted to a connected Chromecast device.
  </p>
  <p>
    !Important! Current Googlecast-SDK version 4.3.2 has a bug and is not working correctly with iOS 12. In order to use Chromecast on iOS 12 devices, the Googlecast-SDK version 3.4.0 must be used until the bug has been fixed by Google.
  </p>
</div>

<h3>UDID</h3>
 * <table>
 * <tr><th> </th><th>Device ID(did)</th><th>Advertising ID(ai)</th><th>MAC ID(mid)</th><th>ID_For_Vendor(ifv)</th></tr>
 
 <tr><td>iOS 4</td><td><div align="center">---</div></td><td><div align="center">---</div></td><td>MAC ID(mid)</td><td><div align="center">---</div></td></tr>
 <tr><td>iOS 5</td><td><div align="center">---</div></td><td><div align="center">---</div></td><td>MAC ID(mid)</td><td><div align="center">---</div></td></tr>
 <tr><td>iOS 6</td><td><div align="center">---</div></td><td>Advertising ID(ai)</td><td>MAC ID(mid)</td><td>ID_For_Vendor(ifv)</td></tr>
 <tr><td>iOS 7</td><td><div align="center">---</div></td><td>Advertising ID(ai)</td><td><div align="center">---</div></td><td>ID_For_Vendor(ifv)</td></tr>
 <tr><td>iOS 8</td><td><div align="center">---</div></td><td>Advertising ID(ai)</td><td><div align="center">---</div></td><td>ID_For_Vendor(ifv)</td></tr>
 <tr><td>iOS 9</td><td><div align="center">---</div></td><td>Advertising ID(ai)</td><td><div align="center">---</div></td><td>ID_For_Vendor(ifv)</td></tr>
 * </table>
 
 <p>Considering that the Apple private policy is changing all the time, Kantar Media Sensor libs have to adapt different UDIDs for identifying the end user's devices.</p>
 <p>
 -# Since iOS 6, device ID and mac ID are not available anymore,
 -# Switch to Advertising ID and ID_For_Vendor</p>
 
 <p><i>Please attention: Apple will reject all the applications which retrieve advertising ID but with no advertising content provided. So Advertising-Framework is linked as optional in Kantar Media Sensor libs, If the Advertising ID should be used as udid, please import Advertising-Framework into your projects.</i></p>

<h3>NextUID</h3>
<div>
  <p>
  Beginning with the Kantar Media Streaming Library 1.9.0, we are providing a getter-method to retrieve the next UID that will be used when tracking is started in the streaming sensor.
Developers can call getNextUID() to retrieve the UID of the stream, which is played next.
The track() method will now accept additional parameter handle which is UID retrieved before. 
  </p>
</div>
 
 <h3>Handling Control Center</h3>
 <div>
 <p>The following scenario may occur during measurement: When opening the control center, the measurement will be started with a new uid after closing the control center.</p>
 <p>
 Our recommendation to handle this is as follows.
 When calling the track method in applicationDidBecomeActive lifecycle hook, please be aware that opening and closing the control center will trigger the action (applicationDidBecomeActive lifecycle method). To avoid this please use applicationWillResignActive lifecycle hook which is invoked when the control center is opened and store a flag to know that the app actually did not go to background but control center is opened. Do necessary changes (like pausing video if desired). On applicationDidBecomeActive please check whether the flag is stored and call the track method only if it is not. This will ensure uninterrupted measurement of streams.
 </p>
 </div>
<h3>WKWebView</h3>
<div> <p>
Recently, Apple started warning users that it is going to stop accepting submissions of apps that use UIWebView APIs. Hence, we have removed that.</p>
<p>Starting from kantarmedia Streaming 1.11.0 we are replacing UIWebview with WKWebView  for retreiving Useragent. The integrator must add Webkit framework into the application for the app to run properly.
 </p>
</div>

 <h3>NOTICE</h3>
 <p><i>Please Note: Some components in Kantar Media Sensor libs are running in background threads. Please keep the initialization and usage of Kantar Media Sensor libs in your main thread, Kantar Media Sensor libs will not block your UI display.
 </i></p>
 
 
 <div align="center">
 <h2>Package Info</h2>
 </div>
 
 <table>
 <tr><th>File</th><th>Description</th></tr>
 
 <tr><td>kantarmedia-streaming-device.a</td>
 <td>This is the version that has been compiled with ARM support and which is intended for execution on iOS devices</td></tr>
 
 <tr><td>kantarmedia-streaming-simulator.a</td>
 <td>This is the version that has been compiled with x86 support and which is intended for execution on iOS simulator</td></tr>
 
 <tr><td>kantarmedia-streaming-fat.a</td>
 <td>This is a combined version of the two libraries above, which can be executed on both, iOS devices and iOS simulator
 because it contains code for ARM and x86 execution. This file is called "fat" as it is roughly double the size (because it combines both versions)</td></tr>
 
 </table>
 <h4>Note</h4>
 <p><i>If size does not matter for the app, the "fat" version is the carefree option to be used for execution on simulator and real devices.
 </i></p>
 
 <div align="center">
 <h2>Release Notes</h2>
 </div>

 <h3>Version 1.11.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Demo Libraries</td>
 <td>Improvement</td>
 <td><p>Added new target "Demo" to libraries</p></td></tr>
 
<tr><td>WKWebview</td>
 <td>Improvement</td>
 <td><p>Replaced UIWebview with WKWebview </p></td></tr>
 
 </table>
 
 <h3>Version 1.10.2</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Scrubbing</td>
 <td>Improvement</td>
 <td><p>Improved scrubbing algorithm so that it would not add additional playstates in certain scenarios</p></td></tr>
 
 </table>
 
 <h3>Version 1.10.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>MultiMarket Support</td>
 <td>Improvement</td>
 <td><p>Sensor now provides a way to set market/domain via new constructor(limited to Universal artifact, currently supports only UK,NO & DK markets)</p></td></tr>
 
 </table>
 
<h3>Version 1.9.0</h3>
<table>
 
<tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>ITP 2.0</td>
 <td>Analysis</td>
 <td><p>Analysis: Cookie and Local Storage behavior in New Safari.</p></td></tr>

 <tr><td>iOS 12</td>
 <td>Analysis</td>
 <td><p>Test sensor on iOS 12.</p></td></tr>

 <tr><td>UID</td>
 <td>Improvement</td>
 <td><p>Sensor provides a new method, which returns the UID of the next created stream (BARB only).</p></td></tr>

 <tr><td>ChromeCast</td>
 <td>Improvement</td>
 <td><p>Add ChromeCast support to the iOS sensor.</p></td></tr>

 <tr><td>Payload elements</td>
 <td>Improvement</td>
 <td><p>Additional variables for the operating system ("os") and the app version ("av") have been added.</p></td></tr>

</table>
<h3>Version 1.8.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>32Bit iOS devices</td>
 <td>Bugfix</td>
 <td><p>Fixes a crash on 32-bit devices, when using a VirtualMeter app.</p></td></tr>

 <tr><td>Scrubbing</td>
 <td>Improvement</td>
 <td><p>Scrubbing now will not add more playstates to request.</p></td></tr> 

  <tr><td>Requests</td>
 <td>Improvement</td>
 <td><p>New payload information in requestes: OS Version & Application Name.</p></td></tr> 

  <tr><td>URL schema trigger</td>
 <td>Bugfix</td>
 <td><p>VirtualMeter app trigger mechanism has been made more reliable.</p></td></tr> 

  <tr><td>32Bit iOS devices</td>
 <td>Bugfix</td>
 <td><p>Fixes a bug, which causes the VirtualMeter app been triggered to often.</p></td></tr> 

</table>
  <h3>Version 1.7.3</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Control over IDFA Access</td>
 <td>Bugfix</td>
 <td><p>The use of the IDFA can now be disabled in constructor. See API documentation for more information.</p></td></tr>
</table>


  <h3>Version 1.7.2</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>UID</td>
 <td>Bugfix</td>
 <td><p>UID generation now working correctly also on 32-bit devices.</p></td></tr>
</table>


 <h3>Version 1.7.1</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>

  <tr><td>Useragent</td>
 <td>Improvement</td>
 <td><p>OS Version and Application Name now are added to the user agent string.</p></td></tr>

  <tr><td>Payload object</td>
 <td>Improvement</td>
 <td><p>OS Version (osv) and Application Name (an) now are added to the payload object of each request.</p></td></tr>
</table>

  <h3>Version 1.7.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Cookie Management</td>
 <td>Improvement</td>
 <td><p>Store cookies in app data in order to prevent deletion of the cookies.</p></td></tr>

  <tr><td>Expose identifiers</td>
 <td>Improvement</td>
 <td><p>The mobile identifiers can be accessed with the new public method getEncryptedIdentifiers of the class Stream.</p></td></tr>

  <tr><td>Ringbuffer</td>
 <td>Improvement</td>
 <td><p>Ringbuffer now flushes all requests when the app goes into background.</p></td></tr>

  <tr><td>SSL</td>
 <td>Improvement</td>
 <td><p>Non-SSL communication has been removed.</p></td></tr>

  <tr><td>Ringbuffer</td>
 <td>Improvement</td>
 <td><p>Requests from the ringbuffer will now be sent always, not only in offline mode.</p></td></tr>

  <tr><td>Streamname</td>
 <td>Refaktoring</td>
 <td><p>Variable stream is now mandatory.</p></td></tr>

  <tr><td>UID</td>
 <td>Improvement</td>
 <td><p>Randomness of UID has been increased and UID is now accessable with an getter.</p></td></tr>
 
</table>
 
 <h3>Version 1.6.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Ringbuffer Handling</td>
 <td>Improvement</td>
 <td><p>Requests from the ringbuffer should be sent always, not only in offline mode.</p></td></tr>
 
 <tr><td>Player position</td>
 <td>Bugfix</td>
 <td><p>Player position (PST object) not accurate in Offline mode for app streaming.</p></td></tr>
</table>
 
 <h3>Version 1.5.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>URL Scheme Trigger</td>
 <td>Improvement</td>
 <td><p>The VM Trigger frequence has been raised. Within first month after install trigger VM once a week. After the first month after install, trigger VM once a month.</p></td></tr>
 
 <tr><td>URL Scheme Trigger</td>
 <td>Improvement</td>
 <td><p>The URL scheme trigger triggers the CamelCase version first, if unsuccessful the lowercase version is called.</p></td></tr>
</table>
 
 <h3>Version 1.4.4</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>AVPlayerViewController</td>
 <td>Improvement</td>
 <td><p>The deprecated API MPMoviePlayerController now is replaced by AVPlayerViewController, in the sample KMA_MediaPlayerAdapter implementation.</p></td></tr>
 
 <tr><td>Request Debugger</td>
 <td>Improvement</td>
 <td><p>A debug Notification is integrated into the library, so that the customers are able to fetch the request sent by the library. See more #KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION.</p></td></tr>
 
 <tr><td>Debug mode</td>
 <td>Improvement</td>
 <td><p>
 Debug mode should be set to false if the application is live product. If the debug set to true, the KMA library will automatic add a flag "isDebug=1" in the http request.</p></td></tr>
 <tr><td>URL Scheme</td>
 <td>Improvement</td>
 <td><p>New beta iOS 10 release has already fixed the url-scheme bug, now capital letters are again valid in url-scheme registration.</p></td></tr>
 
 <tr><td>URL encoding</td>
 <td>bug fix</td>
 <td><p>URL encoding component is updated in the library. Symbols will be also url-encoded in measurement requests. </p></td></tr>
 </table>
 
 
 <h3>Version 1.4.0</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>URL Scheme</td>
 <td>Improvement</td>
 <td><p>In iOS 10, all the url schemes have to be lower-case string, please modify the plist to grant lower-cased url scheme.</p></td></tr>
 
 <tr><td>API modifications</td>
 <td>Improvement</td>
 <td><p>All the KMA streaming library components are now with KMA as prefix, please adapt the changes in your implementation, more details can be found in the API documentation enclosed.</p></td></tr>
 
 <tr><td>API replacement</td>
 <td>Improvement</td>
 <td><p>Some of the APIs are replaced with the latest iOS APIs, for better compability. From this version, iOS 6 will not be supported any more.</p></td></tr>
 </table>
 
 <h3>Version 1.3.6</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Https transmission</td>
 <td>Improvement</td>
 <td><p>Change the https prefix for some clients on their demand. QSIClient now is also aligned with ssl options.</p></td></tr>
 </table>
 
 <h3>Version 1.3.5</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Https transmission</td>
 <td>Improvement</td>
 <td><p>new API setSSL() is added to the library, default https ssl transmission is off, can be switched on. please don't swtich it on until Kantar media Support Team suggest so.</p></td></tr>
 </table>
 
 <h3>Version 1.3.4</h3>
 <table>
 
 <tr>
 <th>Changes</th><th>Attribute</th><th>Description</th>
 </tr>
 
 <tr><td>Bitcode</td>
 <td>Bug</td>
 <td><p>Enabled "-fembed-bitcode" in 'Other C Flags', so that bitcode service can be enabled in applications.</p></td></tr>
 
 <tr><td>Compiling warnings</td>
 <td>Improvement</td>
 <td><p>Set "Precompiling Header Prefix" to NO, to avoid precompiling warnings.</p></td></tr>
 
 </table>
 
 <h3>Version 1.3.3</h3>
 <table>
 <tr>
 <th>Changes</th><th>Attribute</th><th>Description</th>
 </tr>
 
 <tr><td>Bitcode</td>
 <td>Improvement</td>
 <td><p>Bitcode is enabled in the KMA_SpringStreams lib, clients have the chance to enable or disable the bitcode service in their applications.</p></td></tr>
 
 </table>
 
 
 <h3>Version 1.3.2</h3>
 <table>
 <tr>
 <th>Changes</th><th>Attribute</th><th>Description</th>
 </tr>
 
 <tr><td>Request Timer</td>
 <td>Fix</td>
 <td><p>dipatch the NStimer in background thread, avoid the UI block</p></td></tr>
 <tr><td>Background Thread Handler</td>
 <td>Improvement</td>
 <td><p>Modify the corresponding background thread expiration handlers, prevent from the crash caused by the auto-release of the OS(180sec, or 600sec)</p></td></tr>
 
 </table>
 
 
 <h3>Version 1.3.1</h3>
 <table>
 <tr>
 <th>Changes</th><th>Attribute</th><th>Description</th>
 </tr>
 
 <tr><td>Bundle Name</td>
 <td>Improvement</td>
 <td><p>The 'an' parameter in the http request is restored to be the CFBundleDisplayname, instead of CFBundleName.</p></td></tr>
 
 </table>
 
 
 
 * <h3>Version 1.3.0</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 
 <tr>
 <td>
 ARC</td>
 <td>
 Fix</td>
 <td>
 <p>
 The Kantar Media Sensor lib is now changing to ARC(automatic reference counting), in order to wipe out/fix the potential/existing bugs.</p>
 </td>
 </tr>
 <tr><td>Delay on Url switch</td>
 <td>Improvment</td>
 <td><p>Postpone the URL scheme call to UIApplicationDidBecomeActive, only for panelApp users</p></td></tr>
 <tr><td>CFBundleName</td>
 <td>Fix</td>
 <td><p>Replace the CFBundleDisplayName with CFBundleName in the requests</p></td></tr>
 * </table>
 
 
 
 
 
 * <h3>Version 1.2.4</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 
 <tr>
 <td>
 Debug Mode</td>
 <td>
 Modification</td>
 <td>
 <p>
 Starting from the version 1.2.4, the debug mode of Kantar Media Streaming Sensor lib is set back to false. When debug mode is switch to YES, advertising ID and ID_for_vendor will be displayed in plain text in console,
 as the reference for the further test. </p>
 </td>
 </tr>
 * </table>
 
 
 
 
 * <h3>Version 1.2.3</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 
 <tr>
 <td>
 Panel App</td>
 <td>
 Improvement</td>
 <td>
 <p>
 Starting from the version 1.2.3, Kantar Media Streaming Sensor lib is able to pair with previous customized panelApp, as well as 'Nip App'. The related component is optimized. </p>
 </td>
 </tr>
 
 
 <tr>
 <td>
 Advertising ID</td>
 <td>
 Modification</td>
 <td>
 <p>
 As Apple requested, add the check of user's 'Limit Ad tracking' option before reading the advertising ID.
 </p>
 
 </td>
 </tr>
 * </table>
 
 * <h3>Version 1.2.2</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 
 <tr>
 <td>
 Data encoding</td>
 <td>
 Fix</td>
 <td>
 <p>
 Fix a parameter encoding problem</p>
 </td>
 </tr>
 
 <tr>
 <td>
 Panel App</td>
 <td>
 Improvement</td>
 <td>
 <p>
 Speed up the switch to panel App, this improvement applies to the related clients</p>
 </td>
 </tr>
 
 
 <tr>
 <td>
 Panel App</td>
 <td>
 Modification</td>
 <td>
 <p>
 Preconditions which leads to the panel App switch has been modified. With this modification, the main App with Kantar Media Sensor lib imported can also trigger the panel App even though the panel App has been installed after the main App. New Kantar Media Sensor lib attempts on switching to the panel App every time when the main App goes foreground. This modification applies to the related clients
 </p>
 
 </td>
 </tr>
 * </table>
 
 
 * <h3>Version 1.2.0</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 
 <tr>
 <td>
 Compatibility of Kantar Media Streaming Sensor libs</td>
 <td>
 Special feature</td>
 <td>
 <p>
 Strating with KMA_SpringStreams 1.2.0, Spirng normal and streaming sensor can be imported and measure in one application</p>
 </td>
 </tr>
 
 <tr>
 <td>
 App name retrieving</td>
 <td>
 Fix</td>
 <td>
 <p>
 Spirng libs will be tolerant even if the app name is not registered correctly in application</p>
 </td>
 </tr>
 
 
 <tr>
 <td>
 User-agent String</td>
 <td>
 New Feature</td>
 <td>
 <p>
 Starting with KMA_SpringStreams 1.1.1, the default user-agent string of the device is inserted into http client parameters to be collected by the backend box. The user-agent string will be used for device type recognition.
 </p>
 
 </td>
 </tr>
 <tr>
 <td>
 Availablity of retrieving IFV</td>
 <td>
 Fix</td>
 <td>
 <p>
 Fixed the crash caused by unavailable call of retrieving IFV (idforVendor). This bug crashes the app in iOS versions below 6.0.0.</p>
 </td>
 </tr>
 <tr>
 <td>
 Reorganization of imports</td>
 <td>
 Improvement</td>
 <td>
 <p>
 Reorganized the header files, includes, imports, in order to avoid potential duplicate-symbols-error in case the -all_load flag is set in the main application. </p>
 </td>
 </tr>
 
 <tr>
 <td>
 Force to apply aid</td>
 <td>
 Special feature</td>
 <td>
 <p>
 This update is only applied to some of our clients based on their requirements. Kantar Media Sensor lib will produce a compile error to force the usage of advertising id (with the adSupportFramework imported into application)</p>
 </td>
 </tr>
 * </table>
 
 
 
 
 
 
 * <h3>Version 1.1.0</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 <tr>
 <td>
 PanelApp Switch: Url Scheme</td>
 <td>
 New Feature</td>
 <td>
 <p>
 Since KMA_SpringStreams 1.1.0, the lib will try to call a corresponding PanelApp (by URL Scheme, happens in the initialization phase, only called once if ifv is not changed since last lauch), and send ifv (identifier_for_vendor) and related parameters to the PanelApp. This mechanism is designed for identifying each single device owned by the end user. (ifv is unique for each vendor, but not globally)</p>
 <p>
 For adapting this mechanism, the clients of KMA_SpringStreams lib has to implement their own PanelApp and also import KMA_Spring/KMA_SpringStreams lib into it.</p>
 
 </td>
 </tr>
 <tr>
 <td>
 arm64 bits support</td>
 <td>
 New Feature</td>
 <td>
 <p>
 Since KMA_SpringStreams 1.1.0, the lib will support arm64 bit&nbsp;architecture, KMA_SpringStreams lib will be applicable for latest iOS devices.</p>
 </td>
 </tr>
 <tr>
 <td>
 Customized special fields</td>
 <td>
 Changes</td>
 <td>
 <p>
 More customized parameteres/special fields are inserted into measuring http request, applied to our lib accordingly based on the different domains.</p>
 </td>
 </tr>
 * </table>
 
 * <h3>Version 1.0.1</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 * <tr>
 * <td>Identifier of Device</td><td>New Feature</td><td> The identifier of the device would be advertisement id + identifier_for_vendor(https://developer.apple.com/library/ios/documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html#//apple_ref/occ/instp/UIDevice/identifierForVendor) if your application contains video advertisement, otherwise the identifier of the device would be only identifier for vendor. This change responses to the modification of Apple Developers' Policy, advertisement ids are not accepted if no video adversements are involved in the application. </td>
 * </tr>
 * </table>
 * <h3>Version 1.0.0</h3>
 * <table>
 * <tr>
 * <th>Changes</th><th>Attribute</th><th>Description</th>
 * </tr>
 * <tr>
 * <td>OfflineMode</td><td>New Feature</td><td>If the app is configured to offlineMode, Kantar Media Streaming Sensor library would hold all requests in a local buffer and send them until the device goes back online.
 * Kantar Media Streaming Sensor lib checks the internet connection regularly by using a Timer and send the data as soon as possible. Please notice:\n
 * -# Old requests would be droped if too many requests pump into local buffer for the limitation in buffer size. The default buffer size is 500. The data will be stored in a local file, so we would not lose the requests even if the applicaiton terminated.
 * -# Kantar Media Streaming Sensor lib tries to send the requests in a fixed rate, 10 seconds by default, and sends them if device is online. This is achieved by using Apple NSTimer.
 \n\n
 * This mode can be switched on and off by using public API. @see KMA_SpringStreams.offlineMode</td>
 * </tr>
 * <tr>
 * <td>memory leak</td><td>Fix</td><td>If the method Stream.stop is called in some cases a memory leak will occur</td>
 * </tr>
 * <tr>
 * <td>Problem maxstates</td><td>Fix</td><td>Problem fixed if maxstates is reached</td>
 * </tr>
 * <tr>
 * <td>KMA_StreamAdapter and Meta Object</td><td>Change</td><td>KMA_StreamAdapter is now a protocol and Meta is now a class implementation</td>
 * </tr>
 * <tr>
 * <td>Method KMA_Stream.setDuration</td><td>Remove</td><td>The duration has to be delivered by the method KMA_StreamAdapter.getDuration</td>
 * </tr>
 * </table>
 */
