//
//  JotStroke.m
//  JotTouchExample
//
//  Created by Adam Wulf on 1/9/13.
//  Copyright (c) 2013 Adonit, LLC. All rights reserved.
//

#import "JotStroke.h"
#import "SegmentSmoother.h"
#import "AbstractBezierPathElement.h"
#import "AbstractBezierPathElement-Protected.h"
#import "JotDefaultBrushTexture.h"
#import "NSArray+JotMapReduce.h"
#import "JotBufferVBO.h"
#import "JotBufferManager.h"
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@implementation JotStroke{
    // this will interpolate between points into curved segments
    SegmentSmoother* segmentSmoother;
    // this will store all the segments in drawn order
    NSMutableArray* segments;
    // this is the texture to use when drawing the stroke
    JotBrushTexture* texture;
    __weak NSObject<JotStrokeDelegate>* delegate;
    // cache the hash, since it's expenseive to calculate
    NSUInteger hashCache;
    // total Byte size
    NSInteger totalNumberOfBytes;
}

@synthesize segments;
@synthesize segmentSmoother;
@synthesize texture;
@synthesize delegate;
@synthesize totalNumberOfBytes;


-(id) initWithTexture:(JotBrushTexture*)_texture{
    if(self = [super init]){
        segments = [NSMutableArray array];
        segmentSmoother = [[SegmentSmoother alloc] init];
        texture = _texture;
        hashCache = 1;
    }
    return self;
}


-(void) addElement:(AbstractBezierPathElement*)element{
    int numOfElementBytes = [element numberOfBytesGivenPreviousElement:[segments lastObject]];
    int numOfCacheBytes = [JotBufferVBO cacheNumberForBytes:numOfElementBytes] * kJotBufferBucketSize;
//    NSLog(@"number of element bytes: %d", numOfElementBytes);
    totalNumberOfBytes += numOfElementBytes + numOfCacheBytes;
    [segments addObject:element];
    [self updateHashWithObject:element];
}

/**
 * removes an element from this stroke,
 * but does not update the hash. this should
 * only be used to manage memory for a slow
 * dealloc situation
 */
-(void) removeElementAtIndex:(NSInteger)index{
    [segments removeObjectAtIndex:index];
}

-(void) cancel{
    [self.delegate jotStrokeWasCancelled:self];
}


-(CGRect) bounds{
    if([self.segments count]){
        CGRect bounds = [[self.segments objectAtIndex:0] bounds];
        for(AbstractBezierPathElement* ele in self.segments){
            bounds = CGRectUnion(bounds, ele.bounds);
        }
        return bounds;
    }
    return CGRectZero;
}

#pragma mark - PlistSaving

-(NSDictionary*) asDictionary{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"JotStroke", @"class",
            [self.segmentSmoother asDictionary], @"segmentSmoother",
            [self.segments jotMapWithSelector:@selector(asDictionary)], @"segments",
            [self.texture asDictionary], @"texture", nil];
}

-(id) initFromDictionary:(NSDictionary*)dictionary{
    if(self = [super init]){
        hashCache = 1;
        segmentSmoother = [[SegmentSmoother alloc] initFromDictionary:[dictionary objectForKey:@"segmentSmoother"]];
        __block AbstractBezierPathElement* previousElement = nil;
        segments = [NSMutableArray arrayWithArray:[[dictionary objectForKey:@"segments"] jotMap:^id(id obj, NSUInteger index){
            NSString* className = [obj objectForKey:@"class"];
            Class class = NSClassFromString(className);
            AbstractBezierPathElement* segment =  [[class alloc] initFromDictionary:obj];
            [self updateHashWithObject:segment];
            if([segment bind]){
                [segment unbind];
            }
            totalNumberOfBytes += [segment numberOfBytesGivenPreviousElement:previousElement];
            previousElement = segment;
            return segment;
        }]];
        texture = [[JotBrushTexture alloc] initFromDictionary:[dictionary objectForKey:@"texture"]];
    }
    return self;
}


#pragma mark - hashing and equality

-(void) updateHashWithObject:(NSObject*)obj{
    NSUInteger prime = 31;
    hashCache = prime * hashCache + [obj hash];
}

-(NSUInteger) hash{
    return hashCache;
}

-(NSString*) uuid{
    return [NSString stringWithFormat:@"%u", [self hash]];
}

-(BOOL) isEqual:(id)object{
    return self == object || [self hash] == [object hash];
}


@end
