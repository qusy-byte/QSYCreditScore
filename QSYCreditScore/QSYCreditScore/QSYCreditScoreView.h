//
//  QSYCreditScoreView.h
//  QSYCreditScore
//
//  Created by SL on 2016/12/8.
//  Copyright © 2016年 QSY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QSYCreditScoreView : UIView

/**
 信用分数
 */
@property (nonatomic,assign) NSInteger creditScoreNumber;

/**
 更新信用分数
 */
- (void)updateCreditScore;

@end
