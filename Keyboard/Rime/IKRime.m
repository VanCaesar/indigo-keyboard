#import "IKRime.h"
#import <rime_api.h>

static RimeApi *ik_api(void) {
    static RimeApi *api = NULL;
    if (!api) api = rime_get_api();
    return api;
}

static NSString *ik_string(const char *s) {
    if (!s) return @"";
    return [NSString stringWithUTF8String:s] ?: @"";
}

@implementation IKRime {
    RimeSessionId _session;
}

- (BOOL)started {
    return _session != 0;
}

- (BOOL)startWithSharedDataDir:(NSString *)sharedDataDir
                   userDataDir:(NSString *)userDataDir
                      schemaId:(NSString *)schemaId {
    if (_session) return YES;
    RimeApi *api = ik_api();
    if (!api) return NO;

    static BOOL initialized = NO;
    if (!initialized) {
        RIME_STRUCT(RimeTraits, traits);
        traits.shared_data_dir = sharedDataDir.fileSystemRepresentation;
        traits.user_data_dir = userDataDir.fileSystemRepresentation;
        traits.distribution_name = "Indigo";
        traits.distribution_code_name = "indigo";
        traits.distribution_version = "0.1";
        traits.app_name = "rime.indigo";
        traits.min_log_level = 2;
        api->setup(&traits);
        // 不调用 start_maintenance：词库已在 CI 里预编译，键盘里不部署
        api->initialize(&traits);
        initialized = YES;
    }

    _session = api->create_session();
    if (!_session) return NO;
    api->select_schema(_session, schemaId.UTF8String);
    return YES;
}

- (BOOL)processKey:(int)keycode mask:(int)mask {
    if (!_session) return NO;
    return ik_api()->process_key(_session, keycode, mask) != 0;
}

- (NSString *)takeCommitText {
    if (!_session) return nil;
    RIME_STRUCT(RimeCommit, commit);
    if (!ik_api()->get_commit(_session, &commit)) return nil;
    NSString *text = commit.text ? ik_string(commit.text) : nil;
    ik_api()->free_commit(&commit);
    return text.length ? text : nil;
}

- (BOOL)isComposing {
    if (!_session) return NO;
    RIME_STRUCT(RimeStatus, status);
    if (!ik_api()->get_status(_session, &status)) return NO;
    BOOL composing = status.is_composing != 0;
    ik_api()->free_status(&status);
    return composing;
}

- (NSString *)preedit {
    if (!_session) return @"";
    RIME_STRUCT(RimeContext, ctx);
    if (!ik_api()->get_context(_session, &ctx)) return @"";
    NSString *s = ik_string(ctx.composition.preedit);
    ik_api()->free_context(&ctx);
    return s;
}

- (NSString *)rawInput {
    if (!_session) return @"";
    return ik_string(ik_api()->get_input(_session));
}

- (NSArray<NSString *> *)candidatesFromIndex:(NSInteger)index limit:(NSInteger)limit {
    if (!_session || limit <= 0) return @[];
    RimeApi *api = ik_api();
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:(NSUInteger)limit];
    RimeCandidateListIterator it = {0};
    Bool ok;
    NSInteger skip = 0;
    if (RIME_API_AVAILABLE(api, candidate_list_from_index)) {
        ok = api->candidate_list_from_index(_session, &it, (int)index);
    } else {
        ok = api->candidate_list_begin(_session, &it);
        skip = index;
    }
    if (!ok) return result;
    while (result.count < (NSUInteger)limit && api->candidate_list_next(&it)) {
        if (skip > 0) { skip--; continue; }
        [result addObject:ik_string(it.candidate.text)];
    }
    api->candidate_list_end(&it);
    return result;
}

- (BOOL)selectCandidateAtIndex:(NSInteger)index {
    if (!_session) return NO;
    return ik_api()->select_candidate(_session, (size_t)index) != 0;
}

- (BOOL)commitComposition {
    if (!_session) return NO;
    return ik_api()->commit_composition(_session) != 0;
}

- (void)clearComposition {
    if (!_session) return;
    ik_api()->clear_composition(_session);
}

- (void)setOption:(NSString *)option value:(BOOL)value {
    if (!_session) return;
    ik_api()->set_option(_session, option.UTF8String, value ? True : False);
}

- (BOOL)option:(NSString *)option {
    if (!_session) return NO;
    return ik_api()->get_option(_session, option.UTF8String) != 0;
}

@end
