/*
 Disclaimer: IMPORTANT:  This About Objects software is supplied to you by
 About Objects, Inc. ("AOI") in consideration of your agreement to the 
 following terms, and your use, installation, modification or redistribution
 of this AOI software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this AOI software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, AOI grants you a personal, non-exclusive
 license, under AOI's copyrights in this original AOI software (the
 "AOI Software"), to use, reproduce, modify and redistribute the AOI
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the AOI Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the AOI Software.
 Neither the name, trademarks, service marks or logos of About Objects, Inc.
 may be used to endorse or promote products derived from the AOI Software
 without specific prior written permission from AOI.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by AOI herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the AOI Software may be incorporated.
 
 The AOI Software is provided by AOI on an "AS IS" basis.  AOI
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE AOI SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL AOI BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE AOI SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF AOI HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) About Objects, Inc. 2009. All rights reserved.
 */
#import "EditableTextFieldCell.h"

@implementation EditableTextFieldCell

@synthesize textField = _textField;

#pragma mark -

- (void)dealloc
{
    //  We're performing a delayed release here to give delegate notification 
    //  messages time to propagate. Specifically, MyDetailController implements
    //  the -textFieldDidEndEditing: delegate method, which is sent by an
    //  instance of NSNotificationCenter during the next event cycle. Without
    //  the delay, the textField would get released before the message is sent.
    //  But the textField is an argument to that method, so the method would 
    //  be passed an invalid reference, which would be likely to crash the app.
    //
    [_textField performSelector:@selector(release)
                     withObject:nil
                     afterDelay:1.0];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:style reuseIdentifier:identifier];
    
    if (self == nil)
    { 
        return nil;
    }
    
    CGRect bounds = [[self contentView] bounds];
    CGRect rect = CGRectInset(bounds, 20.0, 10.0);
    UITextField *textField = [[UITextField alloc] initWithFrame:rect];
    
    //  Set the keyboard's return key label to 'Next'.
    //
    [textField setReturnKeyType:UIReturnKeyNext];
    
    //  Make the clear button appear automatically.
    [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [textField setBackgroundColor:[UIColor clearColor]];
    [textField setOpaque:NO];
    
    [[self contentView] addSubview:textField];
    [self setTextField:textField];
    
    [textField release];
    
    return self;
}

//  Disable highlighting of currently selected cell.
//
- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated 
{
    [super setSelected:selected animated:NO];
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

@end
