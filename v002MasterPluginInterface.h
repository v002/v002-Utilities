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

#define kv002DescriptionAddOnText @"\n\rv002 Plugins : http://v002.info\n\nCopyright:\nvade - Anton Marini.\nbangnoise - Tom Butterworth\n\n2008-2012 - Creative Commons Non Commercial Share Alike Attribution 3.0" 

@interface v002_PLUGIN_CLASS_NAME_REPLACE_ME : QCPlugIn
{	
		v002Shader* pluginShader;
		NSString* pluginShaderName;
		v002FBO* pluginFBO;
}

@property (readwrite, retain) NSString* pluginShaderName;

//- (v002FBO*) pluginFBO;
//- (v002Shader*) pluginShader;

@end

@interface v002_PLUGIN_CLASS_NAME_REPLACE_ME (Execution)

//- (void) initializeRenderToFBO:(NSRect)bounds;
//- (GLuint) finalizeRenderToFBO;
@end


@compatibility_alias v002MasterPluginInterface v002_PLUGIN_CLASS_NAME_REPLACE_ME;
