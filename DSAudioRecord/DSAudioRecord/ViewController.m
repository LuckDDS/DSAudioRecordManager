//
//  ViewController.m
//  DSAudioRecord
//
//  Created by DDS on 2023/12/4.
//

#import "ViewController.h"
#import "DSAudioRecordManager.h"
@interface ViewController ()<DSAudioRecordManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[DSAudioRecordManager sharedManager] settingAudioRecordFilePath:nil andFileType:(DSAudioRecordFileMP3Type) andAudioSetting:nil];
    [DSAudioRecordManager sharedManager].delegate = self;
    UIButton *start = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, 100, 100)];
    start.backgroundColor = [UIColor redColor];
    [start addTarget:self action:@selector(startRecord) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:start];
    
    UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 250, 100, 100)];
    cancel.backgroundColor = [UIColor redColor];
    [cancel addTarget:self action:@selector(cancelRecord) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:cancel];
    
    UIButton *stop = [[UIButton alloc] initWithFrame:CGRectMake(0, 400, 100, 100)];
    stop.backgroundColor = [UIColor redColor];
    [stop addTarget:self action:@selector(stopRecord) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:stop];
    // Do any additional setup after loading the view.
}
- (void)startRecord {
    [[DSAudioRecordManager sharedManager] startRecordFileName:@"1111"];
}
- (void)cancelRecord {
    [[DSAudioRecordManager sharedManager] cancelRecord];

}
- (void)stopRecord {
    [[DSAudioRecordManager sharedManager] stopRecord];

}

- (void)onRecordOverPath:(NSString *)path andErrorType:(DSAudioRecordErrorType)errorType{
    
}
@end
