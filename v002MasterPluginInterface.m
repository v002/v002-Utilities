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
	// work around lack of GLMacro.h for now
	CGLContextObj cgl_ctx = [context CGLContextObj];
//	CGLSetCurrentContext(cgl_ctx);

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


- (void) enableExecution:(id<QCPlugInContext>)context
{
//	CGLContextObj cgl_ctx = [context CGLContextObj];
//	CGLLockContext(cgl_ctx);
//	
//	// cache our previously bound fbo before every execution
//	//[pluginFBO cachePreviousFBO];
//	CGLUnlockContext(cgl_ctx);
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	[pluginShader release];
	pluginShader = nil;
	[pluginFBO release];
	pluginFBO = nil;
}

@end
