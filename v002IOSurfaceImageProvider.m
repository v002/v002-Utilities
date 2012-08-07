//
//  v002IOSurfaceImageProvider.m
//  v002 MoviePlayer
//
//  Created by Tom on 06/01/2011.
//  Copyright 2011 Tom Butterworth. All rights reserved.
//

#import "v002IOSurfaceImageProvider.h"
#import <mach/mach.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <OpenGL/CGLIOSurface.h>
#import <Accelerate/Accelerate.h>

@implementation v002IOSurfaceImageProvider

@synthesize internalFormat = glInternalFormat, format = glFormat, type = glType;

- (id)initWithSurface:(IOSurfaceRef)surface isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch
{
    self = [super init];
	if (self)
	{
        if (!surface)
		{
			[self release];
			return nil;
		}
		_surface = (IOSurfaceRef)CFRetain(surface);
        
        // added because it seems to remove some corrupted frames when the movie player switches out movies, or starts/stops - vade
        IOSurfaceIncrementUseCount(surface);
        
		_cspace = CGColorSpaceRetain(cspace);
		_cmatch = shouldMatch;
        _flipped = flipped;
		_width = (unsigned int)IOSurfaceGetWidth(_surface);
		_height = (unsigned int)IOSurfaceGetHeight(_surface);
        self.internalFormat = GL_RGBA8;
        self.format = GL_BGRA;
        self.type = GL_UNSIGNED_INT_8_8_8_8_REV;
	}
	return self;
}

- (id)initWithSurfaceID:(IOSurfaceID)surfaceID isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch
{
    IOSurfaceRef surface = IOSurfaceLookup(surfaceID);
    id result;
    if (surface)
    {
        result = [self initWithSurface:surface isFlipped:flipped colorSpace:cspace shouldColorMatch:shouldMatch];
        CFRelease(surface);
    }
    else
    {
        result = nil;
    }
    return result;
}

- (id)initWithMachPort:(mach_port_t)port isFlipped:(BOOL)flipped colorSpace:(CGColorSpaceRef)cspace shouldColorMatch:(BOOL)shouldMatch
{
    IOSurfaceRef surface = IOSurfaceLookupFromMachPort(port);
    id result;
    if (surface)
    {
        result = [self initWithSurface:surface isFlipped:flipped colorSpace:cspace shouldColorMatch:shouldMatch];
        CFRelease(surface);
        if (result) _port = port;
        else mach_port_deallocate(mach_task_self(), port);
    }
    else
    {
        result = nil;
        mach_port_deallocate(mach_task_self(), port);
    }
    return result;
}

- (void)finalize
{
	if (_surface)
    {
        // added because it seems to remove some corrupted frames when the movie player switches out movies, or starts/stops - vade
        IOSurfaceDecrementUseCount(_surface);
        CFRelease(_surface);
	}
    
    if (_port != MACH_PORT_NULL) mach_port_deallocate(mach_task_self(), _port);
	CGColorSpaceRelease(_cspace);
	[super finalize];
}

- (void)dealloc
{
	if (_surface)
    {
        // added because it seems to remove some corrupted frames when the movie player switches out movies, or starts/stops - vade
        IOSurfaceDecrementUseCount(_surface);
        CFRelease(_surface);
	}
    
    CGColorSpaceRelease(_cspace);
    if (_port != MACH_PORT_NULL) mach_port_deallocate(mach_task_self(), _port);
	[super dealloc];
}

- (NSRect) imageBounds
{
	return NSMakeRect(0, 0, _width, _height);
}

/*
 Returns the colorspace of the image.
 */
- (CGColorSpaceRef) imageColorSpace
{
	return _cspace;
}

/*
 Returns NO if the image should not be color matched (e.g. it's a mask or gradient) - YES by default.
 */
- (BOOL) shouldColorMatch
{
	return _cmatch;
}

/*
 Returns the list of memory buffer pixel formats supported by -renderToBuffer (or nil if not supported) - nil by default.
 */
- (NSArray*) supportedBufferPixelFormats
{
    OSType pfmt = IOSurfaceGetPixelFormat(_surface);
    switch (pfmt) {
        case kCVPixelFormatType_32BGRA:
            return [NSArray arrayWithObject:QCPlugInPixelFormatBGRA8];
            break;
        case kCVPixelFormatType_32ARGB:
            return [NSArray arrayWithObject:QCPlugInPixelFormatARGB8];
            break;
        default:
            return nil;
            break;
    }
}

/*
 Renders a subregion of the image into a memory buffer of a given pixel format or returns NO on failure.
 The base address is guaranteed to be 16 bytes aligned and the bytes per row a multiple of 16 as well.
 */
- (BOOL) renderToBuffer:(void*)baseAddress withBytesPerRow:(NSUInteger)rowBytes pixelFormat:(NSString*)format forBounds:(NSRect)bounds
{
	if ([format isEqualToString:QCPlugInPixelFormatBGRA8] || [format isEqualToString:QCPlugInPixelFormatARGB8])
	{
        // TODO: we ignore the flippedness of our source here
        if (kIOReturnSuccess == IOSurfaceLock(_surface, kIOSurfaceLockReadOnly, NULL))
		{
            // Constrain the bounds to be within our image
            NSRect validRegion = NSIntersectionRect(bounds, (NSRect){{0.0, 0.0}, {_width, _height}});
            if (!NSEqualSizes(validRegion.size, bounds.size))
            {
                // Clear the buffer because our image isn't going to fill it
                // It would be an optimization to calculate the region(s) we won't fill and only fill those
                vImage_Buffer dst;
                dst.data = baseAddress;
                dst.height = bounds.size.height;
                dst.width = bounds.size.width;
                dst.rowBytes = rowBytes;
                
                uint8_t clear[4] = {0U, 0U, 0U, 0U};
                vImageBufferFill_ARGB8888(&dst, clear, 0);
            }
            
            size_t surfaceBytesPerRow = IOSurfaceGetBytesPerRow(_surface);
            void *surfaceByteOffset = IOSurfaceGetBaseAddress(_surface) + ((size_t)floor(validRegion.origin.y) * surfaceBytesPerRow) + ((size_t)floor(validRegion.origin.x) * 4);
            
            if (bounds.origin.y < 0)
            {
                baseAddress += rowBytes * (size_t)floor(-bounds.origin.y);
            }
            if (bounds.origin.x < 0)
            {
                baseAddress += 4 * (size_t)floor(-bounds.origin.x);
            }
            
            
#ifdef V002_IOSURFACE_IMAGE_PROVIDER_SUPPORT_RGBX
            if (self.internalFormat == GL_RGB8 && self.format == GL_BGRA)
            {
                vImage_Buffer src;
                src.data = surfaceByteOffset;
                src.height = validRegion.size.height;
                src.width = validRegion.size.width;
                src.rowBytes = surfaceBytesPerRow;
                
                vImage_Buffer dst;
                dst.data = baseAddress;
                dst.width = validRegion.size.width;
                dst.height = validRegion.size.height;
                dst.rowBytes = rowBytes;
                
                // This assumes we have BGRA8, and sets the last channel (vImage's blue, actually our alpha) if our internalFormat is RGB8
                // This is to deal with the RGBX output from v002 Camera Live (turbo-jpeg specifically)
                uint8_t copyMask = 0x1;
                
                // TODO: deal with non-8888 data if we have to, or 8888 in other pixel-orders
                // we could do this using libdispatch's for-loop magic
                vImage_Error error = vImageOverwriteChannelsWithScalar_ARGB8888(UINT8_MAX, &src, &dst, copyMask, 0);
                if (error != kvImageNoError)
                {
                    NSLog(@"vImage Error: %ld", error);
                }
            }
            else
#endif
            {
                // copy line-by-line to allow for differences in rowBytes
                size_t copyBytes = MIN(surfaceBytesPerRow, rowBytes);
                copyBytes = MIN(copyBytes, validRegion.size.width * 4);
                for (int i = 0; i < validRegion.size.height; i++) {
                    memcpy(baseAddress, surfaceByteOffset, copyBytes);
                    baseAddress += rowBytes;
                    surfaceByteOffset += surfaceBytesPerRow;
                }
            }
			IOSurfaceUnlock(_surface, kIOSurfaceLockReadOnly, NULL);
			return YES;
		}
    }
	return NO;
}

/*
 Returns the list of texture pixel formats supported by -copyRenderedTextureForCGLContext (or nil if not supported) - nil by default.
 If this methods returns nil, then -canRenderWithCGLContext / -renderWithCGLContext are called.
 */
- (NSArray*) supportedRenderedTexturePixelFormats
{
	return nil;
}

/*
 Returns the name of an OpenGL texture of type GL_TEXTURE_RECTANGLE_EXT that contains a subregion of the image in a given pixel format - 0 by default.
 The "flipped" parameter must be set to YES on output if the contents of the returned texture is vertically flipped.
 Use <OpenGL/CGLMacro.h> to send commands to the OpenGL context.
 Make sure to preserve all the OpenGL states except the ones defined by GL_CURRENT_BIT.
 */
- (GLuint) copyRenderedTextureForCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(NSString*)format bounds:(NSRect)bounds isFlipped:(BOOL*)flipped
{
	return 0;
}

/*
 Called to release the previously copied texture.
 Use <OpenGL/CGLMacro.h> to send commands to the OpenGL context.
 Make sure to preserve all the OpenGL states except the ones defined by GL_CURRENT_BIT.
 */
- (void) releaseRenderedTexture:(GLuint)name forCGLContext:(CGLContextObj)cgl_ctx
{
	
}

/*
 Performs extra checkings on the capabilities of the OpenGL context (e.g check for supported extensions) and returns YES if the image can be rendered into this context - NO by default.
 Use <OpenGL/CGLMacro.h> to send commands to the OpenGL context.
 If this methods returns NO, then -renderToBuffer is called.
 */
- (BOOL) canRenderWithCGLContext:(CGLContextObj)cgl_ctx
{
	return YES;
}

/*
 Renders a subregion of the image with the provided OpenGL context or returns NO on failure.
 Use <OpenGL/CGLMacro.h> to send commands to the OpenGL context.
 The viewport is already set to the proper dimensions and the projection and modelview matrices are identity.
 The rendering must save / restore all the OpenGL states it changes except the ones defined by GL_CURRENT_BIT.
 */
- (BOOL) renderWithCGLContext:(CGLContextObj)cgl_ctx forBounds:(NSRect)bounds
{
	BOOL result = YES;
	
	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
	glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);
	
	glEnable(GL_TEXTURE_RECTANGLE_ARB);

	GLuint captureTexture;
	glGenTextures(1, &captureTexture);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, captureTexture);
    
	CGLError err = CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, self.internalFormat, _width, _height, self.format, self.type, _surface, 0);
	if(err == kCGLNoError)
	{
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
        NSRect texRect = bounds;
        
        glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // clamp to border so we draw clear if bounds take us beyond our image
        glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        
        // This is the default so we try not setting it in the hope nothing else has fucked with it
//        GLfloat borderColor[] = {0.0, 0.0, 0.0, 0.0};
//        glTexParameterfv(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_BORDER_COLOR, borderColor);
        
		GLfloat texCoords[] = 
		{
			texRect.origin.x,                       texRect.origin.y,
			texRect.origin.x + texRect.size.width,	texRect.origin.y,
			texRect.origin.x + texRect.size.width,	texRect.origin.y + texRect.size.height,
			texRect.origin.x,                       texRect.origin.y + texRect.size.height
		};
		
        GLfloat vertexCoords[] = 
		{
			-1.0,	(_flipped ? 1.0 : -1.0),
			1.0,	(_flipped ? 1.0 : -1.0),
			1.0,	(_flipped ? -1.0 : 1.0),
			-1.0,	(_flipped ? -1.0 : 1.0)
		};

		glEnableClientState( GL_TEXTURE_COORD_ARRAY );
		glTexCoordPointer(2, GL_FLOAT, 0, texCoords );
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(2, GL_FLOAT, 0, vertexCoords );
		glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
		glDisableClientState( GL_TEXTURE_COORD_ARRAY );
		glDisableClientState(GL_VERTEX_ARRAY);
    }
	else
	{
        NSLog(@"CGLTexImageIOSurface2D failed");
		result = NO;
	}

	glDeleteTextures(1, &captureTexture);
	glPopClientAttrib();
	glPopAttrib();
	return result;
}

@end
