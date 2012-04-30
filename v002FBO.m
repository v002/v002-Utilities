//
//  v002FBO.m
//  v002Blurs
//
//  Created by vade on 4/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "v002FBO.h"

// macro for speed
#import <OpenGL/CGLMacro.h>

@implementation v002FBO


- (id) initWithContext:(CGLContextObj)cgl_ctx
{
	if ((self = [super init]))
	{
	
		context = cgl_ctx;
		CGLRetainContext(context);
        
		// this pushes texture attributes
		[self pushAttributes:cgl_ctx];
		// since we are using FBOs we ought to keep track of what was previously bound
		[self pushFBO:cgl_ctx];
		
		// faux bounds for now, for testing to init our FBO		
		
		// init a temporary texture to test FBO support
		GLuint textureID;
		glGenTextures(1, &textureID);
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textureID);
		
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, 640U, 480U, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
        
		// Create FBO 
		glGenFramebuffersEXT(1, &fboID);
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, textureID, 0);
		
		GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
		glDeleteTextures(1, &textureID);
		// restore state
		[self popFBO:cgl_ctx];
		[self popAttributes:cgl_ctx];
		if(status != GL_FRAMEBUFFER_COMPLETE_EXT)
		{	
	//		NSLog(@"Cannot create FBO");
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void)cleanupGL
{
	CGLContextObj cgl_ctx = context;
	CGLLockContext(cgl_ctx);
	if (fboID) glDeleteFramebuffersEXT(1, &fboID);
	CGLUnlockContext(cgl_ctx);	
	
	CGLReleaseContext(context);
}

- (void) dealloc
{
	[self cleanupGL];
	[super dealloc];
}

- (void)finalize
{
	[self cleanupGL];
	[super finalize];
}

- (void) pushFBO:(CGLContextObj)cgl_ctx
{	
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &previousFBO);
	glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_EXT, &previousReadFBO);
	glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_EXT, &previousDrawFBO);
	
//	NSLog(@"Pushing FBO: previous FBO: %i", previousFBO);
//	NSLog(@"Pushing FBO: previous FBO Draw: %i", previousDrawFBO);
//	NSLog(@"Pushing FBO: previous FBO Read: %i", previousReadFBO);
}

- (void) popFBO:(CGLContextObj)cgl_ctx
{
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, previousFBO);	
	glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, previousReadFBO);
	glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, previousDrawFBO);
}

- (void)pushAttributes:(CGLContextObj)cgl_ctx
{
	// save our current GL state - balanced in detachFBO method
	glPushAttrib(GL_ALL_ATTRIB_BITS);
}

- (void)popAttributes:(CGLContextObj)cgl_ctx
{
	// restore states // assume this is balanced with above 
	glPopAttrib();
}

- (void) attachFBO:(CGLContextObj)cgl_ctx withTexture:(GLuint)tex width:(GLsizei)width height:(GLsizei)height
{	
	// bind our FBO
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, tex, 0);

	// Assume FBOs JUST WORK, because we checked on startExecution	

	// Setup OpenGL states 
	// this may be an issue... ?
	
	glViewport(0, 0,  width, height);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	glOrtho(0.0, width,  0.0,  height, -1, 1);		
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
			
	// client now renders to our quad...
}

- (void ) detachFBO:(CGLContextObj) cgl_ctx
{
	// Restore OpenGL states 
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
    
    // The following line should be up to callers if they need it
    // not us but I'm leaving it now because it will probably break
    // other code if I remove it... Tom
	glFlushRenderAPPLE();
}


@end
