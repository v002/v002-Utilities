//---------------------------------------------------------------------------------

#import "v002Shader.h"
#import <OpenGL/CGLMacro.h>

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

@implementation v002Shader

//---------------------------------------------------------------------------------

#pragma mark -- Get shaders from resource --

//---------------------------------------------------------------------------------

+ (NSString *)getShaderSourceFromResource:(NSString *)theShaderResourceName
                                extension:(NSString *)theExtension
                              inDirectory:(NSString *)theDirectory
                                    error:(NSError **)error
{	
    NSString  *path = [[theDirectory stringByAppendingPathComponent:theShaderResourceName] stringByAppendingPathExtension:theExtension];

    NSString *source = nil;
    if (path)
    {
        source = [NSString stringWithContentsOfFile:path usedEncoding:nil error:error];
    }
    if (source == nil && error)
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
    }
	return  source;
} // getShaderSourceFromResource

//---------------------------------------------------------------------------------

+ (NSString *) getFragmentShaderSourceFromResource:(NSString *)theFragmentShaderResourceName inDirectory:(NSString *)theDirectory error:(NSError **)error
{
	return [self getShaderSourceFromResource:theFragmentShaderResourceName 
                                   extension:@"frag"
                                 inDirectory:theDirectory
                                       error:error];
} // getFragmentShaderSourceFromResource

//---------------------------------------------------------------------------------

+ (NSString *) getVertexShaderSourceFromResource:(NSString *)theVertexShaderResourceName inDirectory:(NSString *)theDirectory error:(NSError **)error
{
	return [self getShaderSourceFromResource:theVertexShaderResourceName 
                                   extension:@"vert"
                                 inDirectory:theDirectory
                                       error:error];
} // getVertexShaderSourceFromResource

//---------------------------------------------------------------------------------

- (GLhandleARB) loadShader:(GLenum)theShaderType 
                    source:(NSString *)source
                     error:(NSError **)error
{	
	GLint       shaderCompiled = 0;
	GLhandleARB shaderObject = NULL;
    NSString *compileLog = nil;
    
	if(source != nil ) 
	{
        const GLcharARB *glSource = [source cStringUsingEncoding:NSASCIIStringEncoding];
		GLint infoLogLength = 0;
		
		shaderObject = glCreateShaderObjectARB(theShaderType);
		
		glShaderSourceARB(shaderObject, 1, &glSource, NULL);
		glCompileShaderARB(shaderObject);
		
		glGetObjectParameterivARB(shaderObject, 
								  GL_OBJECT_INFO_LOG_LENGTH_ARB, 
								  &infoLogLength);
		
		if( infoLogLength > 0 ) 
		{
			GLcharARB *infoLog = (GLcharARB *)malloc(infoLogLength);
			
			if( infoLog != NULL )
			{
				glGetInfoLogARB(shaderObject, 
								infoLogLength, 
								&infoLogLength, 
								infoLog);
				
				compileLog = [NSString stringWithCString:infoLog encoding:NSASCIIStringEncoding];
				
				free(infoLog);
			} // if
		} // if
		
		glGetObjectParameterivARB(shaderObject, 
								  GL_OBJECT_COMPILE_STATUS_ARB, 
								  &shaderCompiled);
		
		if(shaderCompiled == 0 )
		{
            glDeleteObjectARB(shaderObject);
			shaderObject = NULL;
            if (error != nil)
            {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"An OpenGL shader could not be compiled.", NSLocalizedDescriptionKey,
                                                 nil];
                if (compileLog != nil)
                {
                    [userInfo setObject:compileLog forKey:NSLocalizedFailureReasonErrorKey];
                }
                *error = [NSError errorWithDomain:@"info.v002.shader.error-domain" code:2 userInfo:userInfo];
            }
		} // if
	} // if
	
	return shaderObject;
} // loadShader

//---------------------------------------------------------------------------------

- (BOOL)setProgramObjectWithVertexSource:(NSString *)vertex fragmentSource:(NSString *)frag error:(NSError **)error
{
    GLint programLinked = 0;
	NSString *linkLog = nil;
    
	// Load and compile both shaders
	
	GLhandleARB vertexShader = [self loadShader:GL_VERTEX_SHADER_ARB 
                                         source:vertex
                                          error:error];
    
	GLhandleARB fragmentShader = [self loadShader:GL_FRAGMENT_SHADER_ARB 
                                           source:frag
                                            error:error];
    
	// Ensure shaders compiled
	
	if( vertexShader != NULL && fragmentShader != NULL)
	{
        // Create a program object and link both shaders
        
        programObject = glCreateProgramObjectARB();
        
        glAttachObjectARB(programObject, vertexShader);
        
        glAttachObjectARB(programObject, fragmentShader);
        
        GLint  infoLogLength = 0;
        
        glLinkProgramARB(programObject);
        
        glGetObjectParameterivARB(programObject, 
                                  GL_OBJECT_INFO_LOG_LENGTH_ARB, 
                                  &infoLogLength);
        
        if( infoLogLength >  0 ) 
        {
            GLcharARB *infoLog = (GLcharARB *)malloc(infoLogLength);
            
            if( infoLog != NULL)
            {
                glGetInfoLogARB(programObject, 
                                infoLogLength, 
                                &infoLogLength, 
                                infoLog);
                
                linkLog = [NSString stringWithCString:infoLog encoding:NSASCIIStringEncoding];
                
                free(infoLog);
            } // if
        } // if
        
        glGetObjectParameterivARB(programObject, 
                                  GL_OBJECT_LINK_STATUS_ARB, 
                                  &programLinked);
        
        if(programLinked == 0 )
        {
            glDeleteObjectARB(programObject);
            programObject = NULL;
        } // if
        
	} // if
	
    if (fragmentShader)
    {
        glDeleteObjectARB(fragmentShader); // Release
    }
    
    if (vertexShader)
    {
        glDeleteObjectARB(vertexShader);   // Release
    }
    
    if (programLinked == 0 && error != nil)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  @"An OpenGL shader could not be linked.", NSLocalizedDescriptionKey,
                                  nil];
        if (linkLog != nil)
        {
            [userInfo setObject:linkLog forKey:NSLocalizedFailureReasonErrorKey];
        }
        *error = [NSError errorWithDomain:@"info.v002.shader.error-domain" code:1 userInfo:userInfo];
    }
    return programLinked == 0 ? NO : YES;
} // setProgramObject

//---------------------------------------------------------------------------------

#pragma mark -- Designated Initializer --

//---------------------------------------------------------------------------------

- (id)initWithVertexShader:(NSString *)vert fragmentShader:(NSString *)frag forContext:(CGLContextObj)context error:(NSError **)error
{
    self = [super init];
	if(self)
	{
		cgl_ctx = CGLRetainContext(context);

		NSError *loadError = nil;
		
		// Load vertex and fragment shader
        
        if ([frag length] && [vert length])
        {
            [self setProgramObjectWithVertexSource:vert
                                    fragmentSource:frag
                                             error:&loadError];
        }
        
        if(loadError)
        {
            if (error != nil)
            {
                *error = loadError;
            }
            [self release];
            return nil;
        }
	}
	return self;
}

- (id)initWithShadersInDirectory:(NSString *)directoryPath withName:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error
{
    NSString *vertexShaderSource = [[self class] getVertexShaderSourceFromResource:theShadersName inDirectory:directoryPath error:error];
    NSString *fragmentShaderSource = [[self class] getFragmentShaderSourceFromResource:theShadersName inDirectory:directoryPath error:error];

    return [self initWithVertexShader:vertexShaderSource fragmentShader:fragmentShaderSource forContext:context error:error];
}

- (id)initWithShadersInBundle:(NSBundle *)bundle withName:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error
{
    return [self initWithShadersInDirectory:[bundle resourcePath] withName:theShadersName forContext:context error:error];
}

- (id)initWithShadersInAppBundle:(NSString *)theShadersName forContext:(CGLContextObj)context error:(NSError **)error
{
    return [self initWithShadersInBundle:[NSBundle mainBundle] withName:theShadersName forContext:context error:error];
}

- (id) initWithShadersInAppBundle:(NSString *)theShadersName forContext:(CGLContextObj)context;
{
	return [self initWithShadersInAppBundle:theShadersName forContext:context error:nil];
}

- (id) initWithShadersInBundle:(NSBundle*)bundle withName:(NSString *)theShadersName forContext:(CGLContextObj) context
{
    return [self initWithShadersInBundle:bundle withName:theShadersName forContext:context error:nil];
}

//---------------------------------------------------------------------------------

#pragma mark -- Deallocating Resources --

//---------------------------------------------------------------------------------

- (void) finalize
{
	// Delete OpenGL resources	
	if( programObject )
	{
		glDeleteObjectARB(programObject);
		programObject = NULL;
	} // if
	CGLReleaseContext(cgl_ctx);
	[super finalize];
}

- (void) dealloc
{
	// Delete OpenGL resources	
	if( programObject )
	{
		glDeleteObjectARB(programObject);
		
		programObject = NULL;
	} // if
    
    CGLReleaseContext(cgl_ctx);
	//Dealloc the superclass
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

#pragma mark -- Accessors --

//---------------------------------------------------------------------------------

- (GLhandleARB) programObject
{
	return  programObject;
} // programObject

//---------------------------------------------------------------------------------

#pragma mark -- Utilities --

//---------------------------------------------------------------------------------

- (GLint) getUniformLocation:(const GLcharARB *)theUniformName
{	
	GLint uniformLoacation = glGetUniformLocationARB(programObject, 
													 theUniformName);
		
//	if( uniformLoacation == -1 ) 
//	{
//		NSLog( @">> WARNING: No such uniform named \"%s\"\n", theUniformName );
//	} // if
	
	return uniformLoacation;
} // getUniformLocation

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

