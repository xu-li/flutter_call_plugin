#import "FlutterCallPlugin.h"
#import <flutter_call_plugin/flutter_call_plugin-Swift.h>

@implementation FlutterCallPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (@available(iOS 10.0, *)) {
        [SwiftFlutterCallPlugin registerWithRegistrar:registrar];
    } else {
        // Fallback on earlier versions
    }
}
@end
