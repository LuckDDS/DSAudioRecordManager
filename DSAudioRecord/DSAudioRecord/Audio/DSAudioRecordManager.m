//
//  DSAudioRecordManager.m
//  DSCapacityEvaluation
//
//  Created by DDS on 2023/12/4.
//  Copyright © 2023 DDS. All rights reserved.
//

#import "DSAudioRecordManager.h"
#import "DSCommonTool.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"
@interface DSAudioRecordManager()<AVAudioRecorderDelegate>
/// 音频文件地址
@property (nonatomic, copy) NSString *recordPathDetails;

/// 音频文件所在文件夹
@property (nonatomic, copy) NSString *recordPath;

/// Audio参数
@property (nonatomic, strong) NSDictionary *settingParams;

/// 生成的音频格式
@property (nonatomic, assign) DSAudioRecordFileType recordFileType;

/// 音频文件
@property (nonatomic, strong) NSData *recordData;

/// 文件名称
@property (nonatomic, copy) NSString *fileName;

@end

@implementation DSAudioRecordManager
{
    NSInteger _startTime;
    BOOL _cancel;
}

+ (instancetype)sharedManager {
    static DSAudioRecordManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recordPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _settingParams = [self getAudioSetting];
        _recordFileType = DSAudioRecordFileCAFType;
        _cancel = NO;
    }
    return self;
}

- (void)settingAudioRecordFilePath:(NSString *_Nullable)path
                       andFileType:(DSAudioRecordFileType)fileType
                   andAudioSetting:(NSDictionary *_Nullable)audioSetting{
    /// 设置存储目录
    if (path && path.length > 0) {
        BOOL isDir = YES;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
            if (![[NSFileManager defaultManager] isWritableFileAtPath:path] || ![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
                NSLog(@"该文件夹不可读/不可写");
            } else {
                _recordPath = path;
            }
        } else {
            BOOL isSuccess = [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
            if (isSuccess) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
                    _recordPath = path;
                }
            }
        }
    }
    /// 音频格式
    _recordFileType = fileType;
    /// 设置参数
    if (audioSetting && audioSetting.allKeys.count > 0) {
        _settingParams = audioSetting;
    }

}
#pragma mark Fun
/// 开始录音
- (void)startRecordFileName:(nonnull NSString *)fileName {
    _cancel = NO;
    if (!fileName || fileName.length == 0) {
        fileName = [NSString stringWithFormat:@"%ld",[DSCommonTool getCurrentTime]];
    }
    _fileName = fileName;
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
    }

    //创建音频会话对象
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置category
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    if (![self.audioRecorder isRecording]){
        // 首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        _startTime = [DSCommonTool getCurrentTime];
        [self.audioRecorder record];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
            [self.delegate onRecordOverPath:nil andErrorType:DSAudioRecordErrorRecordFailType];
        }
    }
}
/// 结束录音
- (void)stopRecord{
    if (self.audioRecorder.recording) {
        [self.audioRecorder stop];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
            [self.delegate onRecordOverPath:nil andErrorType:DSAudioRecordErrorNoRecordType];
        }
    }
}
/// 取消录音
- (void)cancelRecord {
    _cancel = YES;
    if (self.audioRecorder.recording) {
        [self.audioRecorder stop];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
        [self.delegate onRecordOverPath:nil andErrorType:DSAudioRecordErrorCancelType];
    }
}

#pragma mark other

/**
 *  取得录音文件设置,默认格式
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    //录音格式
    [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [recordSettings setValue :[NSNumber numberWithFloat:11025.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMedium] forKey:AVEncoderAudioQualityKey];
    return recordSettings;
}

- (BOOL)isRecording{
    return self.audioRecorder.recording;
}

/// 文件转MP3
/// - Parameter tmpUrl: tmpUrl description
-(void)conventToMp3WithPath:(NSURL *)tmpUrl {
   //tmpUrl是caf文件的路径，并转换成字符串
   NSString *cafFilePath = [tmpUrl absoluteString];
    
   //存储mp3文件的路径
   NSString *mp3FilePath = [NSString stringWithFormat:@"%@/%@.mp3",_recordPath,_fileName];
   @try {
       int read, write;

       FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
       fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
       FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置

       const int PCM_SIZE = 8192;
       const int MP3_SIZE = 8192;
       short int pcm_buffer[PCM_SIZE*2];
       unsigned char mp3_buffer[MP3_SIZE];

       lame_t lame = lame_init();
       lame_set_in_samplerate(lame, 11025.0);
       lame_set_VBR(lame, vbr_default);
       lame_init_params(lame);

       do {
           read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
           if (read == 0)
               write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
           else
               write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
           fwrite(mp3_buffer, write, 1, mp3);

       } while (read != 0);

       lame_close(lame);
       fclose(mp3);
       fclose(pcm);
       if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
           [self.delegate onRecordOverPath:mp3FilePath andErrorType:(DSAudioRecordSuccessType)];
       }
   }
   @catch (NSException *exception) {
       if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
           [self.delegate onRecordOverPath:nil andErrorType:(DSAudioRecordErrorConventType)];
       }
   }
   @finally {
   }
}
#pragma mark AVAudioRecorderDelegate
/*!
    @method audioRecorderDidFinishRecording:successfully:
    @abstract This callback method is called when a recording has been finished or stopped.
    @discussion This method is NOT called if the recorder is stopped due to an interruption.
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (_cancel) {
        return;
    }
    if (flag) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
            if (self.recordFileType == DSAudioRecordFileMP3Type) {
                [self conventToMp3WithPath:[NSURL URLWithString:[_recordPath stringByAppendingPathComponent:@"myRecord.caf"]]];
            } else {
                [self.delegate onRecordOverPath:_recordPathDetails andErrorType:(DSAudioRecordSuccessType)];
            }
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
            [self.delegate onRecordOverPath:nil andErrorType:(DSAudioRecordErrorSystemType)];
        }
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
        [self.delegate onRecordOverPath:nil andErrorType:(DSAudioRecordErrorSystemType)];
    }
}
#pragma mark Lazy
/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
- (AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        self.recordPathDetails = [_recordPath stringByAppendingPathComponent:@"myRecord.caf"];
        NSURL *url = [NSURL URLWithString: self.recordPathDetails];
        //创建录音格式设置,详见下文
        NSDictionary *setting = [self getAudioSetting];
        //创建录音机
        NSError *error = nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        //设置委托代理
        _audioRecorder.delegate = self;
        //如果要监控声波则必须设置为YES
        _audioRecorder.meteringEnabled = YES;
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(onRecordOverPath:andErrorType:)]) {
                [self.delegate onRecordOverPath:nil andErrorType:(DSAudioRecordErrorSystemType)];
            }
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}


@end
