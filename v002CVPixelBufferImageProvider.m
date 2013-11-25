//
//  v002CVPixelBufferImageProvider.m
//  DataMosh
//
//  Created by Tom Butterworth on 22/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "v002CVPixelBufferImageProvider.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <Accelerate/Accelerate.h>


@implementation v002CVPixelBufferImageProvider

- (id)initWithPixelBuffer:(CVPixelBufferRef)buffer isFlipped:(BOOL)flipped shouldColorMatch:(BOOL)shouldMatch
{
    return [self initWithPixelBuffer:buffer textureCache:NULL isFlipped:flipped shouldColorMatch:shouldMatch];
}

- (id)initWithPixelBuffer:(CVPixelBufferRef)buffer textureCache:(CVOpenGLTextureCacheRef)cache isFlipped:(BOOL)flipped shouldColorMatch:(BOOL)shouldMatch
{
    self = [super init];
	if (self)
	{
        if (!buffer)
		{
			[self release];
			return nil;
		}
		_buffer = CVPixelBufferRetain(buffer);
        _cache = CVOpenGLTextureCacheRetain(cache);
		_cmatch = shouldMatch;
        _flipped = flipped;
		_width = CVPixelBufferGetWidth(_buffer);
		_height = CVPixelBufferGetHeight(_buffer);
        _fmt = CVPixelBufferGetPixelFormatType(_buffer);
        CVPixelBufferLockBaseAddress(_buffer, kCVPixelBufferLock_ReadOnly);
	}
	return self;
}

- (void)finalize
{
    CVOpenGLTextureCacheRelease(_cache);
    CVPixelBufferUnlockBaseAddress(_buffer, kCVPixelBufferLock_ReadOnly);
	CVPixelBufferRelease(_buffer);
	[super finalize];
}

- (void)dealloc
{
    CVOpenGLTextureCacheRelease(_cache);
    CVPixelBufferUnlockBaseAddress(_buffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferRelease(_buffer);
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
    CGColorSpaceRef cspace = CVImageBufferGetColorSpace(_buffer);
	return cspace;
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
    if (_fmt == kCVPixelFormatType_32BGRA)
    {
        return [NSArray arrayWithObject:QCPlugInPixelFormatBGRA8];
    }
    else if (_fmt == kCVPixelFormatType_32ARGB)
    {
        return [NSArray arrayWithObject:QCPlugInPixelFormatARGB8];
    }
    else
    {
        return nil;
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
        
        size_t surfaceBytesPerRow = CVPixelBufferGetBytesPerRow(_buffer);
        void *surfaceByteOffset = CVPixelBufferGetBaseAddress(_buffer) + ((size_t)floor(validRegion.origin.y) * surfaceBytesPerRow) + ((size_t)floor(validRegion.origin.x) * 4);
        
        if (bounds.origin.y < 0)
        {
            baseAddress += rowBytes * (size_t)floor(-bounds.origin.y);
        }
        if (bounds.origin.x < 0)
        {
            baseAddress += 4 * (size_t)floor(-bounds.origin.x);
        }
        
        // copy line-by-line to allow for differences in rowBytes
        size_t copyBytes = MIN(surfaceBytesPerRow, rowBytes);
        copyBytes = MIN(copyBytes, validRegion.size.width * 4);
        for (int i = 0; i < validRegion.size.height; i++) {
            memcpy(baseAddress, surfaceByteOffset, copyBytes);
            baseAddress += rowBytes;
            surfaceByteOffset += surfaceBytesPerRow;
        }
        return YES;
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
    CVOpenGLTextureRef cvTexture = NULL;
    
    if (_cache)
    {
        CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _cache, _buffer, NULL, &cvTexture);
    }
    
    GLuint texture;
    GLenum target;
    GLfloat texCoords[8];
    
    // Save state
	glPushAttrib(GL_TEXTURE_BIT | GL_ENABLE_BIT);
	glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);
	
    if (cvTexture)
    {
        texture = CVOpenGLTextureGetName(cvTexture);
        target = CVOpenGLTextureGetTarget(cvTexture);
    }
    else
    {
        glGenTextures(1, &texture);
        target = GL_TEXTURE_2D;
    }
    
	glEnable(target);
    
    glBindTexture(target, texture);
    
    if (cvTexture)
    {
        CVOpenGLTextureGetCleanTexCoords(cvTexture,
                                         (_flipped ? &texCoords[6] : &texCoords[0]), // lower left
                                         (_flipped ? &texCoords[4] : &texCoords[2]), // lower right
                                         (_flipped ? &texCoords[2] : &texCoords[4]), // upper right
                                         (_flipped ? &texCoords[0] : &texCoords[6])  // upper left
                                         );
        
        GLfloat width = texCoords[2] - texCoords[0];
        GLfloat height = texCoords[7] - texCoords[1];
        
        GLfloat xRatio = width / _width;
        GLfloat yRatio = height / _height;
        GLfloat xoffset = bounds.origin.x * xRatio;
        GLfloat yoffset = bounds.origin.y * yRatio;
        GLfloat xinset = ((GLfloat)_width - (bounds.origin.x + bounds.size.width)) * xRatio;
        GLfloat yinset = ((GLfloat)_height - (bounds.origin.y + bounds.size.height)) * yRatio;
        
        texCoords[0] += xoffset;
        texCoords[1] += yoffset;
        texCoords[2] -= xinset;
        texCoords[3] += yoffset;
        texCoords[4] -= xinset;
        texCoords[5] -= yinset;
        texCoords[6] += xoffset;
        texCoords[7] -= yinset;
    }
    else
    {
        GLenum internalFormat, format, type;
        GLuint bitsPerBlock, blockWidth, blockHeight;
        GLuint rowLength;
        // We have details for common formats baked in
        switch (_fmt) {
            case kCVPixelFormatType_422YpCbCr8:
                internalFormat = GL_RGB;
                format = GL_YCBCR_422_APPLE;
#if __BIG_ENDIAN__
                type = GL_UNSIGNED_SHORT_8_8_REV_APPLE;
#else
                type = GL_UNSIGNED_SHORT_8_8_APPLE;
#endif
                bitsPerBlock = 32;
                blockWidth = 2;
                blockHeight = 1;
                
                break;
            case kCVPixelFormatType_32BGRA:
                internalFormat = GL_RGBA;
                format = GL_BGRA;
                type = GL_UNSIGNED_INT_8_8_8_8_REV;
                bitsPerBlock = 32;
                blockWidth = blockHeight = 1;
                break;
            case kCVPixelFormatType_32ARGB:
                internalFormat = GL_RGBA8;
                format = GL_BGRA;
                type = GL_UNSIGNED_INT_8_8_8_8;
                bitsPerBlock = 32;
                blockWidth = blockHeight = 1;
                break;
            case kCVPixelFormatType_422YpCbCr8_yuvs: // Not sure of the heritage of this?
                internalFormat = GL_RGBA;
                format = GL_YCBCR_422_APPLE;
                type = GL_UNSIGNED_SHORT_8_8_REV_APPLE;
                bitsPerBlock = 32;
                blockWidth = 2;
                blockHeight = 1;
                break;
            default:
                // We don't know about this format, so query CoreVideo
            {
                /*
                 NSString *typeStr = [[NSString alloc] initWithBytes:&_fmt length:4 encoding:NSASCIIStringEncoding];
                 NSLog(@"v002CVPixelBufferImageProvider: Unexpected buffer type %@", typeStr);
                 [typeStr release];
                 */
                CFDictionaryRef pfDescription = CVPixelFormatDescriptionCreateWithPixelFormatType(kCFAllocatorDefault, _fmt);
                internalFormat = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatOpenGLInternalFormat] unsignedIntValue];
                format = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatOpenGLFormat] unsignedIntValue];
                type = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatOpenGLType] unsignedIntValue];
                
                bitsPerBlock = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatBitsPerBlock] unsignedIntValue];
                blockWidth = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatBlockWidth] unsignedIntValue];
                blockHeight = [[(NSDictionary *)pfDescription objectForKey:(NSString *)kCVPixelFormatBlockHeight] unsignedIntValue];
                if (blockWidth == 0) blockWidth = 1; // It's perfectly valid for this to be missing, in which case assume 1
                if (blockHeight == 0) blockHeight = 1;
                
                CFRelease(pfDescription);
                
                if (bitsPerBlock == 0 || blockWidth == 0 || blockHeight == 0 || internalFormat == 0 || format == 0 || internalFormat == 0 || type == 0)
                {
                    return NO;
                }
            }
                break;
        }
        
        GLuint bytesPerRow = (GLuint)CVPixelBufferGetBytesPerRow(_buffer);
        GLvoid *baseAddress = CVPixelBufferGetBaseAddress(_buffer);
        
        size_t rowBitsPerBlock = bitsPerBlock / blockHeight;
        rowLength = bytesPerRow * 8 / rowBitsPerBlock * blockWidth;
        
        // TODO: don't ignore extraLeft, extraBottom
        size_t extraLeft = 0;
        size_t extraRight = 0;
        size_t extraTop = 0;
        size_t extraBottom = 0;
        
        CVPixelBufferGetExtendedPixels(_buffer, &extraLeft, &extraRight, &extraTop, &extraBottom);
        
        // Set up the environment for unpacking
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, rowLength);
        glPixelStorei(GL_UNPACK_IMAGE_HEIGHT, 0);
        glPixelStorei(GL_UNPACK_LSB_FIRST, GL_FALSE);
        glPixelStorei(GL_UNPACK_SKIP_IMAGES, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
        glPixelStorei(GL_UNPACK_SWAP_BYTES, GL_FALSE);
        
        // GL_UNPACK_CLIENT_STORAGE_APPLE tells GL to use our buffer in memory if possible, to avoid a copy to the GPU.
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
        
        // Set storage hint GL_STORAGE_SHARED_APPLE to tell GL to share storage with main memory.
        glTexParameteri(target, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE);
        glTextureRangeAPPLE(target, CVPixelBufferGetDataSize(_buffer), baseAddress);
        
        // Upload to the nearest whole block so we don't garble edge pixels
        GLint texExtraRight = 0;
        GLint texExtraTop = 0;
        texExtraRight = (GLint)(((_width + (blockWidth - 1)) & ~(blockWidth - 1)) - _width);
        texExtraTop = (GLint)(((_height + (blockHeight - 1)) & ~(blockHeight - 1)) - _height);
        if (texExtraRight > extraRight) texExtraRight = (GLint)extraRight;
        if (texExtraTop > extraTop) texExtraTop = (GLint)extraTop;
        
        glTexImage2D(target, 0, internalFormat, _width + texExtraRight, _height, 0, format, type, baseAddress);
        
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        // clamp to border so we draw clear if bounds take us beyond our image
        glTexParameterf(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameterf(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        
        GLfloat xoffset = bounds.origin.x;
        GLfloat yoffset = bounds.origin.y;
        GLfloat xinset = (GLfloat)_width - (bounds.origin.x + bounds.size.width);
        GLfloat yinset = (GLfloat)_height - (bounds.origin.y + bounds.size.height);
        
        texCoords[0] = texCoords[6] = 0.0 + xoffset;
        texCoords[1] = texCoords[3] = (_flipped ? yoffset : _height - yoffset);
        texCoords[2] = texCoords[4] = _width - xinset;
        texCoords[5] = texCoords[7] = (_flipped ? _height - yinset : yinset);
        
        if (target == GL_TEXTURE_2D)
        {
            texCoords[0] /= (GLfloat)(_width + extraRight);
            texCoords[1] /= (GLfloat)(_height + extraTop);
            texCoords[2] /= (GLfloat)(_width + extraRight);
            texCoords[3] /= (GLfloat)(_height + extraTop);
            texCoords[4] /= (GLfloat)(_width + extraRight);
            texCoords[5] /= (GLfloat)(_height + extraTop);
            texCoords[6] /= (GLfloat)(_width + extraRight);
            texCoords[7] /= (GLfloat)(_height + extraTop);
        }

    }
        
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    GLfloat vertexCoords[8] =
    {
        -1.0,	-1.0,
         1.0,	-1.0,
         1.0,	 1.0,
        -1.0,	 1.0
    };
    
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertexCoords );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    
    if (cvTexture)
    {
        CVOpenGLTextureRelease(cvTexture);
    }
    else
    {
        glDeleteTextures(1, &texture);
    }
    
	glPopClientAttrib();
	glPopAttrib();
	return YES;
}

@end
