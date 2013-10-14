//
//  JotGLContext.h
//  JotUI
//
//  Created by Adam Wulf on 9/23/13.
//  Copyright (c) 2013 Adonit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface JotGLContext : EAGLContext

@property (assign) BOOL needsFlush;

-(void) glColor4f:(GLfloat)red and:(GLfloat)green and:(GLfloat)blue and:(GLfloat) alpha;

-(void) glEnableClientState:(GLenum)array;

-(void) glDisableClientState:(GLenum)array;

-(void) flush;

-(void) prepOpenGLBlendModeForColor:(UIColor*)color;

-(void) glBlendFunc:(GLenum)sfactor and:(GLenum)dfactor;

@end