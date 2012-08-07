//
//  v002IOSurfaceImageProvider.h
//  v002 MoviePlayer
//
//  Created by Tom on 06/01/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <IOSurface/IOSurface.h>
#import "v002UniqueClassNames.h"

/*
 #define V002_IOSURFACE_IMAGE_PROVIDER_SUPPORT_RGBX outside this file (eg in your project's .pch) to have the provider set the alpha
 channel to be opaque in buffer operations when internalFormat is GL_RGB8. Requires Accelerate.framework.
 */

@interface V002_UNIQUE_CLASS_NAME(v002IOSurfaceImageProvider) : NSObject <QCPlugInOutputImageProvider> {
	unsigned int _width;
	unsigned int _height;
	IOSurfaceRef _surface;
	NSString *_format;
	CGColorSpaceRef _cspace;
	BOOL _cmatch;
    BOOL _flipped;
    mach_port_t _port;
    GLenum glInternalFormat;
    GLenum glFormat;
    GLenum glType;
}
- (id)initWithSurface:(IOSurfaceRef)surface isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch;
- (id)initWithSurfaceID:(IOSurfaceID)surfaceID isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch;

// ownership of the port is assumed by the v002IOSurfaceImageProvider, and it will deallocate it once it is finished with it
- (id)initWithMachPort:(mach_port_t)port isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch;
@property (readwrite, assign, nonatomic) GLenum internalFormat; // default is GL_RGBA8
@property (readwrite, assign, nonatomic) GLenum format; // default is GL_BGRA
@property (readwrite, assign, nonatomic) GLenum type; // default is GL_UNSIGNED_INT_8_8_8_8_REV
@end

#if defined(V002_USE_CLASS_ALIAS)
@compatibility_alias v002IOSurfaceImageProvider V002_UNIQUE_CLASS_NAME(v002IOSurfaceImageProvider);
#endif
