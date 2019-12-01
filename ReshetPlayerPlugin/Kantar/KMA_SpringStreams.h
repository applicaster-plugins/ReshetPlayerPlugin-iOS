//
//  KMA_SpringStreams.h
//  KMA_SpringStreams
//
//  Created by Frank Kammann on 26.08.11.
//  Copyright 2017 Kantar Media. All rights reserved.
//
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ReshetPlayerViewController.h"

@class KMA_SpringStreams, KMA_Stream;


/** The notification name for the debugging purpose, register this notification into the notification center by following API or similar:
 *(void)addObserver:(id)observer selector:(SEL)aSelector name:KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION object:(nullable id)anObject;
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
@interface Reshet_MediaPlayerAdapter : NSObject<KMA_StreamAdapter> {
}
/**
 * Inits the adapter with the MPMoviePlayerController instance.
 *
 * @param player The MPMoviePlayerController
 */
- (Reshet_MediaPlayerAdapter*) adapter:(ReshetPlayerViewController *)player;
@end
#endif
