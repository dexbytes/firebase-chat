#import "FirebaseChatPlugin.h"
#if __has_include(<firebase_chat/firebase_chat-Swift.h>)
#import <firebase_chat/firebase_chat-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "firebase_chat-Swift.h"
#endif

@implementation FirebaseChatPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFirebaseChatPlugin registerWithRegistrar:registrar];
}
@end
