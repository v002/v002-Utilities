//
//  v002FBO.h
//  v002Blurs
//
//  Created by vade on 4/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	<OpenGL/OpenGL.h>
#import "v002UniqueClassNames.h"

/*
 
 v002FBO HAS CHANGED
 
 Create and back textures yourself
 Always push/pop around attach/detach (if you need to). attach/detach will not do it for you
 
 */
@interface V002_UNIQUE_CLASS_NAME(v002FBO) : NSObject
{
	CGLContextObj context; // cache our context for speed
	
	GLuint fboID; // our FBO
		
	GLint previousDrawBuffer;	// GL_FRONT or GL_BACK
	GLint previousReadBuffer;
	
	GLint previousFBO;	// make sure we pop out to the right FBO
	GLint previousReadFBO;
	GLint previousDrawFBO;
}
- (id) initWithContext:(CGLContextObj)ctx;

// handles current fbo binding, read and write fbo binding state.
- (void) pushFBO:(CGLContextObj)cgl_ctx;
- (void) popFBO:(CGLContextObj)cgl_ctx;
// pushes/pops gl attributes (not client)
- (void)pushAttributes:(CGLContextObj)cgl_ctx;
- (void)popAttributes:(CGLContextObj)cgl_ctx;

//  attach our FBO, set up the RTT target based on image bounds, and set up GL state for RTT
- (void) attachFBO:(CGLContextObj)cgl_ctx withTexture:(GLuint)tex width:(GLsizei)width height:(GLsizei)height;

//  attach our FBO, set up the RTT target based on image bounds, and set up GL state for RTT - use MRT
// Node we have to manually call
// bind:
// and attach our textures
// then we call setup
// the above method (attach:withTexture:witdh:height: does this internally)
- (void) bindFBO:(CGLContextObj)cgl_ctx;
- (void) setupFBOViewport:(CGLContextObj)cgl_ctx width:(GLsizei)width height:(GLsizei)height;
- (void) attachFBO:(CGLContextObj)cgl_ctx withTexture:(GLuint)tex toAttachment:(GLuint)attachment width:(GLsizei)width height:(GLsizei)height;


- (void) detachFBO:(CGLContextObj)cgl_ctx;

@end

#if defined(V002_USE_CLASS_ALIAS)
@compatibility_alias v002FBO V002_UNIQUE_CLASS_NAME(v002FBO);
#endif

