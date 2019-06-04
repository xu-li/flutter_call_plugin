#import "FlutterCallPlugin.h"
#import <flutter_call_plugin/flutter_call_plugin-Swift.h>

@implementation FlutterCallPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterCallPlugin registerWithRegistrar:registrar];
}
@end
