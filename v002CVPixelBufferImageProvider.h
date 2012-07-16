//
//  v002CVPixelBufferImageProvider.h
//  DataMosh
//
//  Created by Tom Butterworth on 22/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "v002UniqueClassNames.h"

@interface V002_UNIQUE_CLASS_NAME(v002CVPixelBufferImageProvider) : NSObject <QCPlugInOutputImageProvider> {
@private
    CVPixelBufferRef _buffer;
    uint32_t _fmt;
    BOOL _cmatch;
    BOOL _flipped;
    NSUInteger _width;
    NSUInteger _height;
}
- (id)initWithPixelBuffer:(CVPixelBufferRef)buffer isFlipped:(BOOL)flipped shouldColorMatch:(BOOL)shouldMatch;
@end

#if defined(V002_USE_CLASS_ALIAS)
@compatibility_alias v002CVPixelBufferImageProvider V002_UNIQUE_CLASS_NAME(v002CVPixelBufferImageProvider);
#endif