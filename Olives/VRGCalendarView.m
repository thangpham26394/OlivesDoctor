//
//  VRGCalendarView.m
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//

#import "VRGCalendarView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+convenience.h"
#import "NSMutableArray+convenience.h"
#import "UIView+convenience.h"

@implementation VRGCalendarView
@synthesize currentMonth,delegate,labelCurrentMonth, animationView_A,animationView_B;
@synthesize markedDates,markedColors,calendarHeight,selectedDate;

#pragma mark - Select Date
-(void)selectDate:(int)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay fromDate:self.currentMonth];
    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];

    int selectedDateYear = [selectedDate year];
    int selectedDateMonth = [selectedDate month];
    int currentMonthYear = [currentMonth year];
    int currentMonthMonth = [currentMonth month];

    if (selectedDateYear < currentMonthYear) {
        [self showPreviousMonth];
    } else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
    } else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
    } else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    } else {
        [self setNeedsDisplay];
    }

    if ([delegate respondsToSelector:@selector(calendarView:dateSelected:)]) [delegate calendarView:self dateSelected:self.selectedDate];
}

#pragma mark - Mark Dates
//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates {
    self.markedDates = dates;
    NSMutableArray *colors = [[NSMutableArray alloc] init];

    for (int i = 0; i<[dates count]; i++) {
        [colors addObject:[UIColor clearColor]];
    }

    self.markedColors = [NSArray arrayWithArray:colors];

    [self setNeedsDisplay];
}

//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors {
    self.markedDates = dates;
    self.markedColors = colors;

    [self setNeedsDisplay];
}

#pragma mark - Set date to now
-(void)reset {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components =
    [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth |
                           NSCalendarUnitDay) fromDate: [NSDate date]];
    self.currentMonth = [gregorian dateFromComponents:components]; //clean month

    [self updateSize];
    [self setNeedsDisplay];
    [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
}

#pragma mark - Next & Previous
-(void)showNextMonth {
    if (isAnimating) return;
    //self.markedDates=nil;
    isAnimating=YES;
    prepAnimationNextMonth=YES;

    [self setNeedsDisplay];

    int lastBlock = [currentMonth firstWeekDayInMonth]+[currentMonth numDaysInMonth]-1;
    int numBlocks = [self numRows]*7;
    BOOL hasNextMonthDays = lastBlock<numBlocks;

    //Old month
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];

    //New month
    self.currentMonth = [currentMonth offsetMonth:1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight: animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationNextMonth=NO;
    [self setNeedsDisplay];

    UIImage *imageNextMonth = [self drawCurrentState];
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, self.kVRGCalendarViewTopBarHeight, self.kVRGCalendarViewWidth, targetSize-self.kVRGCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];

    //Animate
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imageNextMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];

    if (hasNextMonthDays) {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight - (self.kVRGCalendarViewDayHeight+3);
    } else {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight -3;
    }

    //Animation
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         //blockSafeSelf.frameHeight = 100;
                         if (hasNextMonthDays) {
                             animationView_A.frameY = -animationView_A.frameHeight + self.kVRGCalendarViewDayHeight+3;
                         } else {
                             animationView_A.frameY = -animationView_A.frameHeight + 3;
                         }
                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}

-(void)showPreviousMonth {
    if (isAnimating) return;
    isAnimating=YES;
    //self.markedDates=nil;
    //Prepare current screen
    prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    BOOL hasPreviousDays = [currentMonth firstWeekDayInMonth]>1;
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];

    //Prepare next screen
    self.currentMonth = [currentMonth offsetMonth:-1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationPreviousMonth=NO;
    [self setNeedsDisplay];
    UIImage *imagePreviousMonth = [self drawCurrentState];

    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, self.kVRGCalendarViewTopBarHeight, self.kVRGCalendarViewWidth, targetSize-self.kVRGCalendarViewTopBarHeight)];

    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];

    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imagePreviousMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];

    if (hasPreviousDays) {
        animationView_B.frameY = animationView_A.frameY - (animationView_B.frameHeight-self.kVRGCalendarViewDayHeight) + 3;
    } else {
        animationView_B.frameY = animationView_A.frameY - animationView_B.frameHeight + 3;
    }

    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];

                         if (hasPreviousDays) {
                             animationView_A.frameY = animationView_B.frameHeight-(self.kVRGCalendarViewDayHeight+3);

                         } else {
                             animationView_A.frameY = animationView_B.frameHeight-3;
                         }

                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}


#pragma mark - update size & row count
-(void)updateSize {
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

-(float)calendarHeight {
    return self.kVRGCalendarViewTopBarHeight + [self numRows]*(self.kVRGCalendarViewDayHeight+2)+1;
}

-(int)numRows {
    float lastBlock = [self.currentMonth numDaysInMonth]+([self.currentMonth firstWeekDayInMonth]-1);
    return ceilf(lastBlock/7);
}

#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    self.selectedDate=nil;

    //Touch a specific day
    if (touchPoint.y > self.kVRGCalendarViewTopBarHeight) {
        float xLocation = touchPoint.x;
        float yLocation = touchPoint.y-self.kVRGCalendarViewTopBarHeight;

        int column = floorf(xLocation/(self.kVRGCalendarViewDayWidth+2));
        int row = floorf(yLocation/(self.kVRGCalendarViewDayHeight+2));

        int blockNr = (column+1)+row*7;
        int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
        int date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    }

    //self.markedDates=nil;
    self.markedColors=nil;

    CGRect rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-50, 0, 50, 40);

    //Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)) {
        [self showPreviousMonth];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)) {
        [self showNextMonth];
    } else if (CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoint)) {
        //Detect touch in current month
        int currentMonthIndex = [self.currentMonth month];
        int todayMonth = [[NSDate date] month];
        [self reset];
        if ((todayMonth!=currentMonthIndex) && [delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
    }
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM yyyy"];
    labelCurrentMonth.text = [formatter stringFromDate:self.currentMonth];
    [labelCurrentMonth sizeToFit];
    labelCurrentMonth.frameX = roundf(self.frame.size.width/2 - labelCurrentMonth.frameWidth/2);
    labelCurrentMonth.frameY = 10;
    [currentMonth firstWeekDayInMonth];

    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,self.kVRGCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);

    //Arrows
    int arrowSize = 12;
    int xmargin = 20;
    int ymargin = 18;

    //Arrow Left
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, xmargin+arrowSize/1.5, ymargin);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5,ymargin+arrowSize);
    CGContextAddLineToPoint(context,xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5, ymargin);

    CGContextSetFillColorWithColor(context,
                                   [UIColor redColor].CGColor);
    CGContextFillPath(context);

    //Arrow right
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    CGContextAddLineToPoint(context,self.frame.size.width-xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5),ymargin+arrowSize);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);

    CGContextSetFillColorWithColor(context,
                                   [UIColor redColor].CGColor);
    CGContextFillPath(context);

    //Weekdays
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"EEE";
    //always assume gregorian with monday first
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
    [weekdays moveObjectFromIndex:0 toIndex:6];

    CGContextSetFillColorWithColor(context,
                                   [UIColor grayColor].CGColor);
    for (int i =0; i<[weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        // Set line break mode
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        // Set text alignment
        paragraphStyle.alignment = NSTextAlignmentCenter;
        //Set font
        NSDictionary *attributes = @{ NSFontAttributeName: font,
                                      NSParagraphStyleAttributeName: paragraphStyle };

        [weekdayValue drawInRect:CGRectMake(i*(self.kVRGCalendarViewDayWidth+2), 40, self.kVRGCalendarViewDayWidth+2, 20)  withAttributes:attributes];

    }

    int numRows = [self numRows];

    CGContextSetAllowsAntialiasing(context, NO);

    //Grid background
    float gridHeight = numRows*(self.kVRGCalendarViewDayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,self.kVRGCalendarViewTopBarHeight,self.frame.size.width,gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xff0000"].CGColor);
    CGContextFillPath(context);

    //Grid white lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, self.kVRGCalendarViewTopBarHeight+1);
    CGContextAddLineToPoint(context, self.kVRGCalendarViewWidth, self.kVRGCalendarViewTopBarHeight+1);
    for (int i = 1; i<7; i++) {
        CGContextMoveToPoint(context, i*(self.kVRGCalendarViewDayWidth+1)+i*1-1, self.kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(self.kVRGCalendarViewDayWidth+1)+i*1-1, self.kVRGCalendarViewTopBarHeight+gridHeight);

        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, self.kVRGCalendarViewTopBarHeight+i*(self.kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, self.kVRGCalendarViewWidth, self.kVRGCalendarViewTopBarHeight+i*(self.kVRGCalendarViewDayHeight+1)+i*1+1);
    }

    CGContextStrokePath(context);

    //Grid dark lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, self.kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context,self.kVRGCalendarViewWidth, self.kVRGCalendarViewTopBarHeight);
    for (int i = 1; i<7; i++) {
        //columns
        CGContextMoveToPoint(context, i*(self.kVRGCalendarViewDayWidth+1)+i*1, self.kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(self.kVRGCalendarViewDayWidth+1)+i*1, self.kVRGCalendarViewTopBarHeight+gridHeight);

        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, self.kVRGCalendarViewTopBarHeight+i*(self.kVRGCalendarViewDayHeight+1)+i*1);
        CGContextAddLineToPoint(context, self.kVRGCalendarViewWidth, self.kVRGCalendarViewTopBarHeight+i*(self.kVRGCalendarViewDayHeight+1)+i*1);
    }
    CGContextMoveToPoint(context, 0, gridHeight+self.kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, self.kVRGCalendarViewWidth, gridHeight+self.kVRGCalendarViewTopBarHeight);

    CGContextStrokePath(context);

    CGContextSetAllowsAntialiasing(context, YES);

    //Draw days
    CGContextSetFillColorWithColor(context,
                                   [UIColor redColor].CGColor);


    //NSLog(@"currentMonth month = %i, first weekday in month = %i",[self.currentMonth month],[self.currentMonth firstWeekDayInMonth]);

    int numBlocks = numRows*7;
    NSDate *previousMonth = [self.currentMonth offsetMonth:-1];
    int currentMonthNumDays = [currentMonth numDaysInMonth];
    int prevMonthNumDays = [previousMonth numDaysInMonth];

    int selectedDateBlock = ([selectedDate day]-1)+firstWeekDay;

    //prepAnimationPreviousMonth nog wat mee doen

    //prev next month
    BOOL isSelectedDatePreviousMonth = prepAnimationPreviousMonth;
    BOOL isSelectedDateNextMonth = prepAnimationNextMonth;

    if (self.selectedDate!=nil) {
        isSelectedDatePreviousMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]<[currentMonth month]) || [selectedDate year] < [currentMonth year];

        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]>[currentMonth month]) || [selectedDate year] > [currentMonth year];
        }
    }

    if (isSelectedDatePreviousMonth) {
        int lastPositionPreviousMonth = firstWeekDay-1;
        selectedDateBlock=lastPositionPreviousMonth-([selectedDate numDaysInMonth]-[selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [currentMonth numDaysInMonth] + (firstWeekDay-1) + [selectedDate day];
    }


    NSDate *todayDate = [NSDate date];
    int todayBlock = -1;

    //    NSLog(@"currentMonth month = %i day = %i, todaydate day = %i",[currentMonth month],[currentMonth day],[todayDate month]);

    if ([todayDate month] == [currentMonth month] && [todayDate year] == [currentMonth year]) {
        todayBlock = [todayDate day] + firstWeekDay - 1;
    }

    for (int i=0; i<numBlocks; i++) {
        int targetDate = i;
        int targetColumn = i%7;
        int targetRow = i/7;
        int targetX = (int)(targetColumn * (self.kVRGCalendarViewDayWidth+2));
        int targetY = (int)(self.kVRGCalendarViewTopBarHeight + targetRow * (self.kVRGCalendarViewDayHeight+2));

        // BOOL isCurrentMonth = NO;
        if (i<firstWeekDay) { //previous month
            targetDate = (prevMonthNumDays-firstWeekDay)+(i+1);
            NSString *hex = (isSelectedDatePreviousMonth) ? @"0x383838" : @"aaaaaa";

            CGContextSetFillColorWithColor(context,
                                           [UIColor colorWithHexString:hex].CGColor);
        } else if (i>=(firstWeekDay+currentMonthNumDays)) { //next month
            targetDate = (i+1) - (firstWeekDay+currentMonthNumDays);
            NSString *hex = (isSelectedDateNextMonth) ? @"0x383838" : @"aaaaaa";
            CGContextSetFillColorWithColor(context,
                                           [UIColor colorWithHexString:hex].CGColor);
        } else { //current month
            // isCurrentMonth = YES;
            targetDate = (i-firstWeekDay)+1;
            NSString *hex = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? @"0xaaaaaa" : @"0x383838";
            CGContextSetFillColorWithColor(context,
                                           [UIColor colorWithHexString:hex].CGColor);
        }

        NSString *date = [NSString stringWithFormat:@"%i",targetDate];

        //draw selected date
        if (selectedDate && i==selectedDateBlock) {
            CGRect rectangleGrid = CGRectMake(targetX,targetY,self.kVRGCalendarViewDayWidth+2,self.kVRGCalendarViewDayHeight+2);

            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0/255.0 green:150/255.0 blue:150/255.0 alpha:0.3].CGColor);
            CGContextFillPath(context);

            CGContextSetFillColorWithColor(context,
                                           [UIColor whiteColor].CGColor);
        } else if (todayBlock==i) {
            CGRect rectangleGrid = CGRectMake(targetX,targetY,self.kVRGCalendarViewDayWidth+2,self.kVRGCalendarViewDayHeight+2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0].CGColor);
            CGContextFillPath(context);

            CGContextSetFillColorWithColor(context,
                                           [UIColor whiteColor].CGColor);
        }

        //        [date drawInRect:CGRectMake(targetX+2, targetY+10, self.kVRGCalendarViewDayWidth, self.kVRGCalendarViewDayHeight) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        // Set line break mode
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        // Set text alignment
        paragraphStyle.alignment = NSTextAlignmentCenter;
        //Set font
        NSDictionary *attributes = @{ NSFontAttributeName: font,
                                      NSParagraphStyleAttributeName: paragraphStyle };

        [date drawInRect:CGRectMake(targetX+2, targetY+10, self.kVRGCalendarViewDayWidth, self.kVRGCalendarViewDayHeight)  withAttributes:attributes];
    }

    //    CGContextClosePath(context);


    //Draw markings
    if (!self.markedDates || isSelectedDatePreviousMonth || isSelectedDateNextMonth) return;

    for (int i = 0; i<[self.markedDates count]; i++) {
        id markedDateObj = [self.markedDates objectAtIndex:i];

        int targetDate;
        if ([markedDateObj isKindOfClass:[NSNumber class]]) {
            targetDate = [(NSNumber *)markedDateObj intValue];
        } else if ([markedDateObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)markedDateObj;
            //check if current month year is equal to the marked date's year
            if ([date year] == [self.currentMonth year] && [date month] == [self.currentMonth month]) {
                targetDate = [date day];
            }else{
                continue;
            }

        } else {
            continue;
        }



        int targetBlock = firstWeekDay + (targetDate-1);
        int targetColumn = targetBlock%7;
        int targetRow = targetBlock/7;

        int targetX = (int)(targetColumn * (self.kVRGCalendarViewDayWidth+2) + 7);
        int targetY = (int)(self.kVRGCalendarViewTopBarHeight + targetRow * (self.kVRGCalendarViewDayHeight+2) + 38);

        CGRect rectangle = CGRectMake(targetX,targetY,self.kVRGCalendarViewDayWidth-12,3);
        CGContextAddRect(context, rectangle);

        UIColor *color;
        if (selectedDate && selectedDateBlock==targetBlock) {
            color = [UIColor whiteColor];
        }  else if (todayBlock==targetBlock) {
            color = [UIColor whiteColor];
        } else {
            color  = [UIColor redColor];
            //(UIColor *)[markedColors objectAtIndex:i];
        }


        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
    }
}

#pragma mark - Draw image for animation
-(UIImage *)drawCurrentState {
    float targetHeight = self.kVRGCalendarViewTopBarHeight + [self numRows]*(self.kVRGCalendarViewDayHeight+2)+1;

    UIGraphicsBeginImageContext(CGSizeMake(self.kVRGCalendarViewWidth, targetHeight-self.kVRGCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -self.kVRGCalendarViewTopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark - Init
-(id)init {
    self.kVRGCalendarViewTopBarHeight = 70;
    self.kVRGCalendarViewWidth =  [[UIScreen mainScreen] bounds].size.width- 20;
    self.kVRGCalendarViewDayWidth = (NSInteger) floor((self.kVRGCalendarViewWidth -8)/7);
    self.kVRGCalendarViewDayHeight = self.kVRGCalendarViewDayWidth;
    self = [super initWithFrame:CGRectMake(0, 0,self.kVRGCalendarViewWidth, 0)];
    if (self) {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds=YES;

        isAnimating=NO;
        self.labelCurrentMonth = [[UILabel alloc] initWithFrame:CGRectMake(34, 0,self.kVRGCalendarViewWidth-68, 40)];
        [self addSubview:labelCurrentMonth];
        labelCurrentMonth.backgroundColor=[UIColor whiteColor];
        labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
        labelCurrentMonth.textColor = [UIColor blackColor];
        labelCurrentMonth.textAlignment = NSTextAlignmentCenter;

        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; //so delegate can be set after init and still get called on init
        //        [self reset];
    }
    return self;
}

-(void)dealloc {

    self.delegate=nil;
    self.currentMonth=nil;
    self.labelCurrentMonth=nil;
    
    self.markedDates=nil;
    self.markedColors=nil;
    
}
@end
