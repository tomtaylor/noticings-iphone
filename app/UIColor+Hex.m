//
//  UIColor+Hex
//
//  Created by Tom Adriaenssen on 13/01/11.
//

#import "UIColor+Hex.h"

@implementation NSString (LeftPadding)

// taken from http://stackoverflow.com/questions/964322/padding-string-to-left-with-objective-c

- (NSString *) stringByPaddingTheLeftToLength:(NSUInteger) newLength withString:(NSString *) padString startingAtIndex:(NSUInteger) padIndex
{
    if ([self length] <= newLength)
        return [[@"" stringByPaddingToLength:newLength - [self length] withString:padString startingAtIndex:padIndex] stringByAppendingString:self];
    else
        return [[self copy] autorelease];
}

@end

@implementation UIColor (Hex)

+ (UIColor*) colorWithCSS: (NSString*)css {
	if (css == nil || [css length] == 0)
		return [UIColor blackColor];
	
	if ([css characterAtIndex:0] == '#')
		css = [css substringFromIndex:1];
	
	NSString *a, *r, *g, *b;

	int len = [css length];
	if (len == 6) {
	six:
		a = @"FF";
		r = [css substringWithRange:NSMakeRange(0, 2)];
		g = [css substringWithRange:NSMakeRange(2, 2)];
		b = [css substringWithRange:NSMakeRange(4, 2)];
	}
	else if (len == 8) {
	eight:
		a = [css substringWithRange:NSMakeRange(0, 2)];
		r = [css substringWithRange:NSMakeRange(2, 2)];
		g = [css substringWithRange:NSMakeRange(4, 2)];
		b = [css substringWithRange:NSMakeRange(6, 2)];
	}
	else if (len == 3) {
	three: 
		a = @"FF";
		r = [css substringWithRange:NSMakeRange(0, 1)];
		r = [r stringByAppendingString:a];
		g = [css substringWithRange:NSMakeRange(1, 1)];
		g = [g stringByAppendingString:a];
		b = [css substringWithRange:NSMakeRange(2, 1)];
		b = [b stringByAppendingString:a];
	}
	else if (len == 4) {
		a = [css substringWithRange:NSMakeRange(0, 1)];
		a = [a stringByAppendingString:a];
		r = [css substringWithRange:NSMakeRange(1, 1)];
		r = [r stringByAppendingString:a];
		g = [css substringWithRange:NSMakeRange(2, 1)];
		g = [g stringByAppendingString:a];
		b = [css substringWithRange:NSMakeRange(3, 1)];
		b = [b stringByAppendingString:a];
	}
	else if (len == 5 || len == 7) {
		css = [@"0" stringByAppendingString:css];	
		if (len == 5) goto six;
		goto eight;
	}
	else if (len < 3) {
		css = [css stringByPaddingTheLeftToLength:3 withString:@"0" startingAtIndex:0];	
		goto three;
	}
	else if (len > 8) {
		css = [css substringFromIndex:len-8];
		goto eight;
	}
	else {
		a = @"FF";
		r = @"00";
		g = @"00";
		b = @"00";
	}
	
	// parse each component separetely. This gives more accurate results than 
	// throwing it all together in one string and use scanf on the global string.
	a = [@"0x" stringByAppendingString:a];
	r = [@"0x" stringByAppendingString:r];
	g = [@"0x" stringByAppendingString:g];
	b = [@"0x" stringByAppendingString:b];
	
	uint av, rv, gv, bv;
	sscanf([a cStringUsingEncoding:NSASCIIStringEncoding], "%x", &av);
	sscanf([r cStringUsingEncoding:NSASCIIStringEncoding], "%x", &rv);
	sscanf([g cStringUsingEncoding:NSASCIIStringEncoding], "%x", &gv);
	sscanf([b cStringUsingEncoding:NSASCIIStringEncoding], "%x", &bv);
	
	return [UIColor colorWithRed: rv / ((CGFloat)0xFF) 
						   green: gv / ((CGFloat)0xFF) 
							blue: bv / ((CGFloat)0xFF)
						   alpha: av / ((CGFloat)0xFF)];
}

+ (UIColor*) colorWithHex: (uint)hex {
	CGFloat red, green, blue, alpha;
	
	red = ((CGFloat)((hex >> 16) & 0xFF)) / ((CGFloat)0xFF);
	green = ((CGFloat)((hex >> 8) & 0xFF)) / ((CGFloat)0xFF);
	blue = ((CGFloat)((hex >> 0) & 0xFF)) / ((CGFloat)0xFF);
	alpha = hex > 0xFFFFFF ? ((CGFloat)((hex >> 24) & 0xFF)) / ((CGFloat)0xFF) : 1;
	
	return [UIColor colorWithRed: red green:green blue:blue alpha:alpha];
}



@end
