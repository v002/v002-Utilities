//-------------------------------------------------------------------------
//
// Required Includes
//
//-------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import "v002UniqueClassNames.h"

//-------------------------------------------------------------------------
//
// GLSL Shader
//
//-------------------------------------------------------------------------

@interface V002_UNIQUE_CLASS_NAME(v002Shader) : NSObject
{
	@private
		GLhandleARB		    programObject;				// the program object
	
		CGLContextObj cgl_ctx;					// context to bind shaders to.
} // Shader

- (id)initWithShadersInAppBundle:(NSString *)theShadersName forContext:(CGLContextObj)context;
- (id)initWithShadersInAppBundle:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error;
- (id)initWithShadersInBundle:(NSBundle *)bundle withName:(NSString *)theShadersName forContext:(CGLContextObj)context;
- (id)initWithShadersInBundle:(NSBundle *)bundle withName:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error;
// Designated initializer:
- (id)initWithShadersInDirectory:(NSString *)directory withName:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error;
- (GLhandleARB) programObject;
- (GLint) getUniformLocation:(const GLcharARB *)theUniformName;

@end

//-------------------------------------------------------------------------

#if defined(V002_USE_CLASS_ALIAS)
@compatibility_alias v002Shader V002_UNIQUE_CLASS_NAME(v002Shader);
#endif
