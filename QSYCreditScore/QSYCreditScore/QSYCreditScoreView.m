//
//  QSYCreditScoreView.m
//  QSYCreditScore
//
//  Created by SL on 2016/12/8.
//  Copyright © 2016年 QSY. All rights reserved.
//

#import "QSYCreditScoreView.h"

//计时器间隔
#define kSCORE_TIMEINTERVAL 0.01

//动画时间
#define kSCORE_ANIMATIONTIME 2.5

//大刻度段数
#define kSCORE_BIGLINENUM 5

//大刻度段数中的小刻度段数
#define kSCORE_SMALLLINENUM 6

//圆弧起止度数
#define kSCORE_STARTANGLE -200.0
#define kSCORE_ENDANGLE 20.0

//内外圆度数差,半径差
#define kSCORE_ANGLESPACE 2.0
#define kSCORE_RADIUSSPACE 10.0

#define kColorRGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@interface QSYCreditScoreView ()

/**
 信用分数段
 */
@property (nonatomic,strong) NSArray <NSNumber *> *creditScoreArray;

/**
 信用评级
 */
@property (nonatomic,strong) NSArray <NSString *> *creditScoreRankArray;

/**
 信用说明
 */
@property (nonatomic,copy) NSString *creditRank;


/**
 记录当前显示值
 */
@property (nonatomic,assign) CGFloat markNum;

/**
 每次增加的值,和计时器有关
 */
@property (nonatomic,assign) CGFloat addNum;

/**
 评估时间: 2016-12-08
 */
@property (nonatomic,copy) NSString *creditScoreDate;

/**
 计时器
 */
@property (nonatomic,strong) NSTimer *creditScoreTimer;

/**
 外侧背景虚线
 */
@property (nonatomic,strong) CAShapeLayer *outerBackgroundLayer;

/**
 外侧背景虚线动画
 */
@property (nonatomic,strong) CABasicAnimation *outerBackgroundLayerAnimation;

/**
 外侧分数实线
 */
@property (nonatomic,strong) CAShapeLayer *outerScoreLayer;

/**
 外侧分数实线动画
 */
@property (nonatomic,strong) CABasicAnimation *outerScoreLayerAnimation;

/**
 内侧背景实线
 */
@property (nonatomic,strong) CAShapeLayer *insideBackgrroundLayer;

/**
 内侧小刻度线
 */
@property (nonatomic,strong) NSArray <CAShapeLayer *> *insideSmallLayers;

/**
 内侧大刻度线
 */
@property (nonatomic,strong) NSArray <CAShapeLayer *> *insideBigLayers;

/**
 小光点
 */
@property (nonatomic,strong) CALayer *imageLayer;


/**
 圆心
 */
@property (nonatomic,assign) CGPoint arcCenter;

/**
 外圆弧半径
 */
@property (nonatomic,assign) CGFloat outerRadius;


/**
 小光点移动动画
 */
@property (nonatomic,strong) CAKeyframeAnimation *imageAnimation;


/**
 信用数字显示label
 */
@property (nonatomic,strong) UILabel *creditScoreLabel;


/**
 信用分占总分的比例:控制动画
 */
@property (nonatomic,assign) CGFloat csScale;

@end

@implementation QSYCreditScoreView

#pragma mark
#pragma mark --- 懒加载 ---

static CGFloat oldValue;

- (void)setCsScale:(CGFloat)csScale
{
    if (csScale < 0)
    {
        _csScale = 0;
    }
    else if (csScale > 1)
    {
        _csScale = 1;
    }
    else
    {
        _csScale = csScale;
    }

    if (_csScale != oldValue)
    {
        [self setNeedsDisplay];
        [self clearTimer];
        
        if (_csScale <= 0)
        {
            [self drawCreditScoreNumLabelWith:0];
        }
        else
        {
            self.addNum = self.creditScoreNumber / (kSCORE_ANIMATIONTIME / kSCORE_TIMEINTERVAL);
            NSLog(@"self.addNum = %lf",self.addNum);
            self.creditScoreTimer = [NSTimer scheduledTimerWithTimeInterval:kSCORE_TIMEINTERVAL target:self selector:@selector(drawCreditScoreNumLayerByTimer) userInfo:nil repeats:YES];
            
            [[NSRunLoop mainRunLoop] addTimer:self.creditScoreTimer forMode:NSRunLoopCommonModes];
        }
        
        oldValue = _csScale;
            
    }
}

- (UILabel *)creditScoreLabel
{
    if (!_creditScoreLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        label.font = [UIFont systemFontOfSize:40];
        label.textColor = [UIColor whiteColor];
        label.text = @"0";
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        _creditScoreLabel = label;
    }
    return _creditScoreLabel;
}

- (CAKeyframeAnimation *)imageAnimation
{
    if (!_imageAnimation) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        animation.duration = kSCORE_ANIMATIONTIME;
        animation.repeatCount = 1;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation.fillMode = kCAFillModeForwards;
        animation.calculationMode = kCAAnimationPaced;
        animation.autoreverses = NO;
        animation.removedOnCompletion = NO;
        
        _imageAnimation = animation;
    }
    return _imageAnimation;
}

- (CALayer *)imageLayer
{
    if (!_imageLayer) {
        CALayer *layer = [CALayer layer];
        layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"im_shine_ball"].CGImage);
        layer.bounds = CGRectMake(0, 0, 13, 13);
        layer.position = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:self.outerRadius startAngle:[self angleToRadianWith:kSCORE_STARTANGLE] endAngle:[self angleToRadianWith:kSCORE_ENDANGLE] clockwise:YES].currentPoint;
        [self.layer addSublayer:layer];
        
        _imageLayer = layer;
    }
    return _imageLayer;
}

- (CAShapeLayer *)insideBackgrroundLayer
{
    if (!_insideBackgrroundLayer) {
        _insideBackgrroundLayer = [self creatShapeLayerWithLineWidth:4.0];
        _insideBackgrroundLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:_insideBackgrroundLayer];
    }
    
    return _insideBackgrroundLayer;
}

- (NSArray<CAShapeLayer *> *)insideBigLayers
{
    if (!_insideBigLayers) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < 6; i++) {
            CAShapeLayer *layer = [self creatShapeLayerWithLineWidth:4.5f];
            [self.layer addSublayer:layer];
            
            [array addObject:layer];
        }
        _insideBigLayers = array;
    }
    return _insideBigLayers;
}

- (NSArray<CAShapeLayer *> *)insideSmallLayers
{
    if (!_insideSmallLayers) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < 30; i++) {
            CAShapeLayer *layer = [self creatShapeLayerWithLineWidth:4.0f];
            [self.layer addSublayer:layer];
            
            [array addObject:layer];
        }
        _insideSmallLayers = (NSArray*)array;
    }
    return _insideSmallLayers;
}

- (CABasicAnimation *)outerScoreLayerAnimation
{
    if (!_outerScoreLayerAnimation) {
        _outerScoreLayerAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        _outerScoreLayerAnimation.duration = kSCORE_ANIMATIONTIME;
        _outerScoreLayerAnimation.repeatCount = 1;
        _outerScoreLayerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        _outerScoreLayerAnimation.fromValue = @0;
        _outerScoreLayerAnimation.fillMode = kCAFillModeForwards;
        _outerScoreLayerAnimation.removedOnCompletion = NO;
    }
    return _outerScoreLayerAnimation;
}

- (CAShapeLayer *)outerScoreLayer
{
    if (!_outerScoreLayer) {
        _outerScoreLayer = [self creatShapeLayerWithLineWidth:1.5f];
        _outerScoreLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:_outerScoreLayer];
    }
    return _outerScoreLayer;
}

- (CABasicAnimation *)outerBackgroundLayerAnimation
{
    if (!_outerBackgroundLayerAnimation) {
        _outerBackgroundLayerAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        _outerBackgroundLayerAnimation.duration = kSCORE_ANIMATIONTIME;
        _outerBackgroundLayerAnimation.repeatCount = 1;
        _outerBackgroundLayerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        _outerBackgroundLayerAnimation.fromValue = @1;
        _outerBackgroundLayerAnimation.fillMode = kCAFillModeForwards;
        _outerBackgroundLayerAnimation.removedOnCompletion = NO;
    }
    return _outerBackgroundLayerAnimation;
}

- (CAShapeLayer *)outerBackgroundLayer
{
    if (!_outerBackgroundLayer) {
        _outerBackgroundLayer = [self creatShapeLayerWithLineWidth:1.5f];
        _outerBackgroundLayer.lineDashPattern = @[@1.5, @3.5];
        [self.layer addSublayer:_outerBackgroundLayer];
    }
    
    return _outerBackgroundLayer;
}

- (NSString *)creditRank
{
    if (!_creditRank) {
        _creditRank = @"暂无数据";
    }
    
    return _creditRank;
}

- (NSArray *)creditScoreArray
{
    if (!_creditScoreArray) {
        _creditScoreArray = @[@350,@550,@600,@650,@700,@950];
    }
    
    return _creditScoreArray;
}

- (NSArray<NSString *> *)creditScoreRankArray
{
    if (!_creditScoreRankArray) {
        _creditScoreRankArray = @[@"较差",@"中等",@"良好",@"优秀",@"极好"];
    }
    
    return _creditScoreRankArray;
}

- (NSString *)creditScoreDate
{
    if (!_creditScoreDate) {
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        _creditScoreDate = [formatter stringFromDate:currentDate];
    }

    return _creditScoreDate;
}

#pragma mark
#pragma mark --- 更新信用分数 ---
- (void)updateCreditScore
{
    CGFloat score = self.creditScoreNumber;

    for (NSInteger i = 0 ; i < self.creditScoreArray.count; i++) {
        NSInteger minScore = [self getScoreFromCreditScores:i - 1];
        NSInteger maxScore = [self getScoreFromCreditScores:i];
        
        if (score >= minScore && score <= maxScore) {
            CGFloat space = 1.0 / kSCORE_BIGLINENUM;
            
            self.csScale = (score - minScore) / (maxScore - minScore) * space + space * (i - 1);
            
            self.creditRank = [self getScoreRankAtCreditScoreRanks:i - 1];
            
            return;
        }
    }
}

- (NSInteger)getScoreFromCreditScores:(NSInteger)index
{
    NSInteger score = 0;
    
    if (index >= 0 && index < self.creditScoreArray.count) {
        
        NSNumber *scoreNum = self.creditScoreArray[index];
        score = [scoreNum integerValue];
        return score;
    }
    
    return score;
}

- (NSString *)getScoreRankAtCreditScoreRanks:(NSInteger)index
{
    NSString *rank;
    
    if (index >= 0 && index < self.creditScoreRankArray.count) {
        
        rank = [@"信用" stringByAppendingString:self.creditScoreRankArray[index]];
        return rank;
    }
    
    rank = @"暂无数据";
    
    return rank;
}

#pragma mark
#pragma mark --- 构造方法 ---
- (CAShapeLayer *)creatShapeLayerWithLineWidth:(CGFloat)lineWdith
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.6f].CGColor;
    layer.lineWidth = lineWdith;

    return layer;
}

- (CGFloat)angleToRadianWith:(CGFloat)angle
{
    return angle * (M_PI / 180);
}

#pragma mark
#pragma mark --- drawRect ---
- (void)drawRect:(CGRect)rect {
    
    // 圆心
    self.arcCenter = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    // 外侧圆弧半径
    self.outerRadius = MIN(self.frame.size.width, self.frame.size.height) / 2 - 10;
    
    // 虚线
    UIBezierPath *outerBackPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:self.outerRadius startAngle:[self angleToRadianWith:kSCORE_ENDANGLE] endAngle:[self angleToRadianWith:kSCORE_STARTANGLE] clockwise:NO];
    self.outerBackgroundLayer.path = outerBackPath.CGPath;

    // 外侧实圆弧
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:self.outerRadius startAngle:[self angleToRadianWith:kSCORE_STARTANGLE] endAngle:[self angleToRadianWith:kSCORE_ENDANGLE] clockwise:YES];
    self.outerScoreLayer.path = outerPath.CGPath;
    
    [self drawOuterScoreLayerByAnimation];
    
    // 内侧圆弧
    [self drawSmallAndBigLayer];
    
    [self drawCridetScoreRankLabel];
    
    [self drawCreditScoreTitleLayer];
    
    CGPoint csCenter = CGPointMake(self.arcCenter.x, self.arcCenter.y - self.outerRadius * 0.1);
    self.creditScoreLabel.center = csCenter;
}

/**
 动画效果绘制外侧分数实线
 */
- (void)drawOuterScoreLayerByAnimation
{
    self.outerScoreLayer.strokeEnd = self.csScale;
    self.outerScoreLayerAnimation.toValue = [NSNumber numberWithFloat:self.csScale];
    [self.outerScoreLayer addAnimation:self.outerScoreLayerAnimation forKey:@"outerScoreLayerAnimation"];
    
    self.outerBackgroundLayer.strokeEnd = 1.0 - self.csScale;
    self.outerBackgroundLayerAnimation.toValue = [NSNumber numberWithFloat:(1.0 - self.csScale)];
    [self.outerBackgroundLayer addAnimation:self.outerBackgroundLayerAnimation forKey:@"outerBackgroundLayerAnimation"];
    
    //小光点动画
    CGFloat imageAngle = kSCORE_STARTANGLE + fabs(kSCORE_ENDANGLE - kSCORE_STARTANGLE) * self.csScale;
    UIBezierPath *imagePath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:self.outerRadius startAngle:[self angleToRadianWith:kSCORE_STARTANGLE] endAngle:[self angleToRadianWith:imageAngle] clockwise:YES];
    self.imageLayer.position = imagePath.currentPoint;
    self.imageAnimation.path = imagePath.CGPath;
    [self.imageLayer addAnimation:self.imageAnimation forKey:@"imageAnimation"];
}

/**
 绘制title
 */
- (void)drawCreditScoreTitleLayer
{
    NSStringDrawingOptions options = NSStringDrawingUsesFontLeading |NSStringDrawingUsesFontLeading;
    CGSize creditRanSzie = [self.creditRank boundingRectWithSize:CGSizeMake(100, 100) options:options attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size;
    CGPoint creditRankCenter = CGPointMake(self.arcCenter.x - creditRanSzie.width / 2, self.arcCenter.y - creditRanSzie.height / 2 - self.outerRadius * 0.4);
    [self.creditRank drawAtPoint:creditRankCenter withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    NSMutableString *dateString = [NSMutableString stringWithString:@"评估时间:"];
    [dateString appendString:self.creditScoreDate];
    
    UIFont *dateFont = [UIFont systemFontOfSize:10];
    CGSize dateSize = [dateString boundingRectWithSize:CGSizeMake(200, 15) options:options attributes:@{NSFontAttributeName:dateFont} context:nil].size;
    CGPoint dateCenter = CGPointMake(self.arcCenter.x - dateSize.width / 2, self.arcCenter.y - dateSize.height / 2 + self.outerRadius * 0.25);
    [dateString drawAtPoint:dateCenter withAttributes:@{NSFontAttributeName:dateFont, NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

/**
 结束定时器
 */
- (void)clearTimer
{
    [_creditScoreTimer invalidate];
    _creditScoreTimer = nil;
    _markNum = 0.0;
}

/**
 计时器绘制数字
 */
- (void)drawCreditScoreNumLayerByTimer
{
    self.markNum = self.markNum + self.addNum;
    
    self.markNum = (self.markNum >= self.creditScoreNumber) ? self.creditScoreNumber : self.markNum;

    [self drawCreditScoreNumLabelWith:self.markNum];
    
    if (self.markNum >= self.creditScoreNumber) {

        [self clearTimer];
    }
}

/**
 绘制信用分label
 */
- (void)drawCreditScoreNumLabelWith:(NSInteger)creditScore
{
    NSString *creditScoreStr = [NSString stringWithFormat:@"%zd",creditScore];
    NSStringDrawingOptions options = NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine;
    CGSize csLabelSzie = [creditScoreStr boundingRectWithSize:CGSizeMake(100, 100) options:options attributes:@{NSFontAttributeName:self.creditScoreLabel.font} context:nil].size;
    self.creditScoreLabel.bounds = (CGRect){CGPointZero,csLabelSzie};
    self.creditScoreLabel.text = creditScoreStr;
}

/**
 绘制大小刻度线
 */
- (void)drawSmallAndBigLayer
{
    // 内侧半径
    CGFloat insideR = self.outerRadius - kSCORE_RADIUSSPACE;
    
    // 内侧背景路径
    UIBezierPath *insidePath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:insideR startAngle:[self angleToRadianWith:kSCORE_STARTANGLE - kSCORE_ANGLESPACE] endAngle:[self angleToRadianWith:kSCORE_ENDANGLE + kSCORE_ANGLESPACE] clockwise:YES];
    self.insideBackgrroundLayer.path = insidePath.CGPath;
    
    // 内侧小刻度
    for (NSInteger i = 0; i < self.insideSmallLayers.count; i++) {
        CAShapeLayer *layer = self.insideSmallLayers[i];
        CGFloat space = (kSCORE_ENDANGLE - kSCORE_STARTANGLE) / kSCORE_BIGLINENUM / kSCORE_SMALLLINENUM;
        CGFloat insideDottedStartAngle = kSCORE_STARTANGLE + space * i;
        UIBezierPath *insideDottedPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:insideR startAngle:[self angleToRadianWith:insideDottedStartAngle] endAngle:[self angleToRadianWith:insideDottedStartAngle + 0.5] clockwise:YES];
        layer.path = insideDottedPath.CGPath;
        
    }
    
    // 内侧大刻度
    for (NSInteger i = 0; i < self.insideBigLayers.count; i++) {
        CAShapeLayer *layer = self.insideBigLayers[i];
        CGFloat space = (kSCORE_ENDANGLE - kSCORE_STARTANGLE) / kSCORE_BIGLINENUM;
        CGFloat insideDottedStartAngle = kSCORE_STARTANGLE + space * i;
        UIBezierPath *insideDottedPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:insideR - 1.0 startAngle:[self angleToRadianWith:insideDottedStartAngle] endAngle:[self angleToRadianWith:insideDottedStartAngle + 0.5] clockwise:YES];
        layer.path = insideDottedPath.CGPath;
        
        // 绘制数字标签
        UIBezierPath *insideStrPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:insideR - 8 startAngle:[self angleToRadianWith:insideDottedStartAngle] endAngle:[self angleToRadianWith:insideDottedStartAngle + 0.5] clockwise:YES];
        [self drawNumberLabelWith:i currentPoint:insideStrPath.currentPoint];
    }
    
}

/**
 绘制数字标签:[350 ~ 950]

 @param index 当前数组index
 @param point 当前点
 */
- (void)drawNumberLabelWith:(NSInteger)index currentPoint:(CGPoint)point
{
    NSString *currentNumStr = (index < self.creditScoreArray.count) ? [NSString stringWithFormat:@"%@",self.creditScoreArray[index]] : @"";
    
    CGPoint strPoint = CGPointZero;
    
    UIFont *strFont = [UIFont systemFontOfSize:9];
    
    CGSize strSzie = [currentNumStr boundingRectWithSize:CGSizeMake(100, 100) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:strFont} context:nil].size;
    
    if (index == 2) {
        strPoint = CGPointMake(point.x - strSzie.width / 2, point.y);
    }
    else if (index == 3) {
        strPoint = CGPointMake(point.x - strSzie.width / 2, point.y);
    }
    else if (index < 2) {
        strPoint = CGPointMake(point.x, point.y - strSzie.height / 2);
    }
    if (index > 3) {
        strPoint = CGPointMake(point.x  - strSzie.width, point.y - strSzie.height / 2);
    }
    
    [currentNumStr drawAtPoint:strPoint withAttributes:@{NSFontAttributeName:strFont, NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

/**
 绘制信用评价label
 */
- (void)drawCridetScoreRankLabel
{
    CGFloat radius = self.outerRadius - 10 -5;
    
    CGFloat space = (kSCORE_ENDANGLE - kSCORE_STARTANGLE) / 10.0;
    
    for (NSInteger i = 0; i < self.creditScoreRankArray.count; i++) {
        NSString *rankStr = self.creditScoreRankArray[i];
        CGFloat rankStartAngle = space + kSCORE_STARTANGLE + space * 2 *i;
        // 绘制数字标签
        UIBezierPath *insideStrPath = [UIBezierPath bezierPathWithArcCenter:self.arcCenter radius:radius startAngle:[self angleToRadianWith:rankStartAngle] endAngle:[self angleToRadianWith:rankStartAngle] clockwise:YES];
        
        CGPoint strPoint = CGPointZero;
        UIFont *strFont = [UIFont systemFontOfSize:7];
        CGSize strSize = [rankStr boundingRectWithSize:CGSizeMake(100, 100) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:strFont} context:nil].size;
        CGPoint currentPoint = insideStrPath.currentPoint;
        
        if (currentPoint.x == (self.frame.size.width / 2)) {
            strPoint = CGPointMake(currentPoint.x - strSize.width / 2, currentPoint.y);
        }else if (currentPoint.x < (self.frame.size.width / 2)){
            strPoint = CGPointMake(currentPoint.x , currentPoint.y - strSize.height / 2);
        }else{
            strPoint = CGPointMake(currentPoint.x - strSize.width, currentPoint.y - strSize.height / 2);
        }
        
        [rankStr drawAtPoint:strPoint withAttributes:@{NSFontAttributeName:strFont, NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
}

@end









