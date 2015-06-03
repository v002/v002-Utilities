//
//  v002MasterPluginInterface.m
//  v002Blurs
//
//  Created by vade on 4/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "v002MasterPluginInterface.h"
#import <OpenGL/CGLMacro.h>

@implementation v002_PLUGIN_CLASS_NAME_REPLACE_ME

@synthesize shaderUniformBlock;
@synthesize pluginShaderName;

- (void) finalize
{
	self.pluginShaderName = nil;
	[super finalize];
}

- (void)dealloc
{
	self.pluginShaderName = nil;

    // Just in case stopExecution wasn't called:
	[pluginShader release];
	[pluginFBO release];
	[super dealloc];
}
	
- (v002FBO*) pluginFBO
{
	return pluginFBO;
}
- (v002Shader*) pluginShader
{
	return pluginShader;
}

@end

@implementation v002_PLUGIN_CLASS_NAME_REPLACE_ME (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	CGLContextObj cgl_ctx = [context CGLContextObj];

	// shader loading
	if([pluginShaderName length]) // do we have a name? if not dont bother.
	{
		NSBundle *pluginBundle =[NSBundle bundleForClass:[self class]];	
		pluginShader = [[v002Shader alloc] initWithShadersInBundle:pluginBundle withName:self.pluginShaderName forContext:cgl_ctx];
		if(pluginShader == nil)
		{
			[context logMessage:@"Cannot compile GLSL shader."];
			return NO;
		}
	}
		
	pluginFBO = [[v002FBO alloc] initWithContext:cgl_ctx];
	if(pluginFBO == nil)
	{
		[context logMessage:@"Cannot create FBO"];
		return NO;
	}
	
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	[pluginShader release];
	pluginShader = nil;
	[pluginFBO release];
	pluginFBO = nil;
}

#pragma mark - Helper Methods

- (BOOL) boundImageIsFloatingPoint:(id<QCPlugInInputImageSource>)image inContext:(CGLContextObj)cgl_ctx;
{
    // Deduce the bit depth of the input image, so we can appropriately output a lossless image
    GLint result;
    glGetTexLevelParameteriv([image textureTarget], 0, GL_TEXTURE_INTERNAL_FORMAT, &result);
    BOOL useFloat = (result == GL_RGBA32F_ARB) ? YES : NO;

    return useFloat;
}

- (NSString*) pixelFormatIfUsingFloat:(BOOL)useFloat;
{
    
#if __BIG_ENDIAN__
#define v002QCPluginPixelFormat QCPlugInPixelFormatARGB8
#else
#define v002QCPluginPixelFormat QCPlugInPixelFormatBGRA8
#endif
    return (useFloat) ? QCPlugInPixelFormatRGBAf : v002QCPluginPixelFormat;
    
}

- (GLuint) singleImageRenderWithContext:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image useFloat:(BOOL)useFloat
{    
    GLsizei width = [image imageBounds].size.width;
    GLsizei height = [image imageBounds].size.height;
    
    [pluginFBO pushAttributes:cgl_ctx];
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tex);
    
    if(useFloat)
    {
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA32F_ARB, width, height, 0, GL_RGBA, GL_FLOAT, NULL);
        glClampColorARB(GL_CLAMP_FRAGMENT_COLOR_ARB, GL_FALSE);
    }
    else
    {
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    }
    
    [pluginFBO pushFBO:cgl_ctx];
    [pluginFBO attachFBO:cgl_ctx withTexture:tex width:width height:height];
    
    
    
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    glEnable([image textureTarget]);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [image textureName]);
    glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // do not need blending if we use black border for alpha and replace env mode, saves a buffer wipe
    // we can do this since our image draws over the complete surface of the FBO, no pixel goes untouched.
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glDisable(GL_BLEND);

    // old alpha compositing code for reference
//    glClearColor(0.0, 0.0, 0.0, 0.0);
//    glClear(GL_COLOR_BUFFER_BIT);
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    // bind our shader program
    glUseProgramObjectARB([pluginShader programObject]);
    
    // setup our shaders!
    if(self.shaderUniformBlock)
    {
        self.shaderUniformBlock(cgl_ctx);
    }
    else
    {
        // some error or some shit
    }
    
    // move to VA for rendering
    GLfloat tex_coords[] =
    {
        1.0,1.0,
        0.0,1.0,
        0.0,0.0,
        1.0,0.0
    };
    
    GLfloat verts[] =
    {
        width,height,
        0.0,height,
        0.0,0.0,
        width,0.0
    };
    
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );	// TODO: GL_QUADS or GL_TRIANGLE_FAN?
    
    if(useFloat)
    {
        glClampColorARB(GL_CLAMP_FRAGMENT_COLOR_ARB, GL_TRUE);
    }

    // disable shader program
    glUseProgramObjectARB(NULL);

    [pluginFBO detachFBO:cgl_ctx];
    [pluginFBO popFBO:cgl_ctx];
    [pluginFBO popAttributes:cgl_ctx];
    
    return tex;
}

@end
