//
//  DSRecordManager.h
//  DSCapacityEvaluation
//
//  Created by DDS on 2023/12/4.
//  Copyright © 2023 DDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AVAudioRecorder;
/// 错误信息
typedef NS_ENUM(NSInteger, DSAudioRecordErrorType) {
    DSAudioRecordSuccessType,     // 成功
    DSAudioRecordErrorNoRecordType,   // 未录音,无法停止
    DSAudioRecordErrorCancelType,     // 取消录音
    DSAudioRecordErrorSystemType,     // 系统错误
    DSAudioRecordErrorConventType,    // 转换MP3失败
    DSAudioRecordErrorRecordFailType,    // 无法录音
};

/// 音频格式
typedef NS_ENUM(NSInteger, DSAudioRecordFileType) {
    DSAudioRecordFileMP3Type,     // 生成MP3
    DSAudioRecordFileCAFType,     // 生成caf格式
};
@protocol DSAudioRecordManagerDelegate <NSObject>
@optional

/// 录音完成,成功/失败/取消都会走这个方法
/// - Parameter path: 音频地址,失败返回@""或nil
/// - Parameter error: 错误信息
- (void)onRecordOverPath:(NSString *_Nullable)path 
            andErrorType:(DSAudioRecordErrorType)errorType;

@end
NS_ASSUME_NONNULL_BEGIN

@interface DSAudioRecordManager : NSObject
/// 音频录音机
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

@property (nonatomic, weak) id<DSAudioRecordManagerDelegate> delegate;

/// 是否正在录音
@property (nonatomic, assign) BOOL isRecording;

/// 设置单例
+ (instancetype)sharedManager;

/// 设置audio
/// - Parameters:
///   - path: 存储路径,不设置默认为Document
///   - fileType: 文件类型默认为CAF格式
///   - audioSetting: 原始音频参数(原始音频格式默认为CAF),不设置使用默认设置
- (void)settingAudioRecordFilePath:(NSString *_Nullable)path
                       andFileType:(DSAudioRecordFileType)fileType
                   andAudioSetting:(NSDictionary *_Nullable)audioSetting;

/// 开始录音
/// - Parameter fileName: 生成的文件名称,不设置默认为当前时间戳
- (void)startRecordFileName:(NSString *)fileName;

/// 停止录音
- (void)stopRecord;

/// 取消录音
- (void)cancelRecord;
@end

NS_ASSUME_NONNULL_END
