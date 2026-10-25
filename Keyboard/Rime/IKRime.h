#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// librime 的薄封装。不是线程安全的：只能在同一个串行队列上调用。
@interface IKRime : NSObject

/// 只读的 shared_data_dir（含预编译 build/），可写的 user_data_dir。进程内只初始化一次。
- (BOOL)startWithSharedDataDir:(NSString *)sharedDataDir
                   userDataDir:(NSString *)userDataDir
                      schemaId:(NSString *)schemaId
    NS_SWIFT_NAME(start(sharedDataDir:userDataDir:schemaId:));

@property (nonatomic, readonly) BOOL started;

/// keycode 为 X11 keysym，mask 为 Rime 修饰键掩码。返回 Rime 是否处理了这个键。
- (BOOL)processKey:(int)keycode mask:(int)mask NS_SWIFT_NAME(processKey(_:mask:));

/// 取出并清空待上屏文字
- (nullable NSString *)takeCommitText NS_SWIFT_NAME(takeCommitText());

@property (nonatomic, readonly) BOOL isComposing;
/// 当前编码（带分隔的拼音）
@property (nonatomic, readonly, copy) NSString *preedit;
/// 原始输入（未经格式化的字母）
@property (nonatomic, readonly, copy) NSString *rawInput;

/// 从 index 开始最多取 limit 个候选
- (NSArray<NSString *> *)candidatesFromIndex:(NSInteger)index limit:(NSInteger)limit
    NS_SWIFT_NAME(candidates(from:limit:));

- (BOOL)selectCandidateAtIndex:(NSInteger)index NS_SWIFT_NAME(selectCandidate(at:));
- (BOOL)commitComposition;
- (void)clearComposition;

- (void)setOption:(NSString *)option value:(BOOL)value NS_SWIFT_NAME(setOption(_:value:));
- (BOOL)option:(NSString *)option NS_SWIFT_NAME(option(_:));

@end

NS_ASSUME_NONNULL_END
