//
//  v002MasterPluginInterface.h
//  v002Blurs
//
//  Created by vade on 4/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "v002Shader.h"
#import "v002FBO.h"

#define kv002DescriptionAddOnText @"\n\rv002 Plugins : http://v002.info\n\nCopyright:\nvade - Anton Marini.\nbangnoise - Tom Butterworth\n\n2008-2099 - Creative Commons Non Commercial Share Alike Attribution 3.0" 

typedef void(^ShaderUniformBlock)(CGLContextObj cgl_ctx);

@interface v002_PLUGIN_CLASS_NAME_REPLACE_ME : QCPlugIn
{	
    v002Shader* pluginShader;
    NSString* pluginShaderName;
    v002FBO* pluginFBO;
    ShaderUniformBlock shaderUniformBlock;
}
@property (nonatomic, copy) ShaderUniformBlock shaderUniformBlock;

@property (readwrite, retain) NSString* pluginShaderName;

//- (v002FBO*) pluginFBO;
//- (v002Shader*) pluginShader;

@end

@interface v002_PLUGIN_CLASS_NAME_REPLACE_ME (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context NS_REQUIRES_SUPER;
- (void) stopExecution:(id<QCPlugInContext>)context NS_REQUIRES_SUPER;

#pragma mark - Helper Methods

// Is a Input Image that is currently, locked, bound, and active Floating Point?
- (BOOL) boundImageIsFloatingPoint:(id<QCPlugInInputImageSource>)image inContext:(CGLContextObj)cgl_ctx;

// Machine Endian Correct pixel format
- (NSString*) pixelFormatIfUsingFloat:(BOOL)useFloat;

// Helper method that renders a quad to the standard FBO.
// Requires our shaderUniformBlock to be set
- (GLuint) singleImageRenderWithContext:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image useFloat:(BOOL)useFloat;

@end


@compatibility_alias v002MasterPluginInterface v002_PLUGIN_CLASS_NAME_REPLACE_ME;
