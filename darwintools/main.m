// Thanks to @absidue#9322 and Zebra Team for the Objective-C rewrite of firmware.sh

#import "Firmware.h"

#define FIRMWARE_VERSION 7

int main() {
    DEBUGLOG("Full steam ahead.");

    Firmware *firmware = [[Firmware alloc] init];
    [firmware loadInstalledPackages];

    DeviceInfo *device = [DeviceInfo sharedDevice];

    // generate device specific packages
    DEBUGLOG("Generate device specific packages.");
    [firmware generateCapabilityPackages];


    // generate always needed packages

    NSString *iosVersion = [device getOperatingSystemVersion];

#if (TARGET_OS_IPHONE)
    DEBUGLOG("Generate firmware package.");
    [firmware generatePackage:@"firmware" forVersion:iosVersion withDescription:@"almost impressive Apple frameworks" andName:@"iOS Firmware"];
#endif

    DEBUGLOG("Generate os package.");
    NSString *packageName = [@"cy+os." stringByAppendingString:[device getOperatingSystem]];
    [firmware generatePackage:packageName forVersion:iosVersion withDescription:@"virtual operating system dependency"];

    DEBUGLOG("Generate cpu package.");
    packageName = [@"cy+cpu." stringByAppendingString:device.cpuArchitecture];
    [firmware generatePackage:packageName forVersion:@"0" withDescription:@"virtual CPU dependency"];

    DEBUGLOG("Generate sub-cpu package.");
    packageName = [@"cy+cpu." stringByAppendingString:device.cpuSubArchitecture];
    [firmware generatePackage:packageName forVersion:@"0" withDescription:@"virtual CPU dependency"];

    DEBUGLOG("Generate model package.");
    packageName = [@"cy+model." stringByAppendingString:[device getModelName]];
    [firmware generatePackage:packageName forVersion:[device getModelVersion] withDescription:@"virtual model dependency"];

    DEBUGLOG("Generate kernel package.");
    packageName = [@"cy+kernel." stringByAppendingString:[device getOperatingSystemType]];
    [firmware generatePackage:packageName forVersion:[device getOperatingSystemRelease] withDescription:@"virtual kernel dependency"];

    DEBUGLOG("Generate corefoundation package.");
    [firmware generatePackage:@"cy+lib.corefoundation" forVersion:[device getCoreFoundationVersion] withDescription:@"virtual corefoundation dependency"];

    DEBUGLOG("Write packages to the status file.");
    [firmware writePackagesToStatusFile];

#if (TARGET_OS_IPHONE)
    DEBUGLOG("Create /User symlink.");
    [firmware setupUserSymbolicLink];

    // write firmware version
    DEBUGLOG("Write firmware version.");

    NSError *error;

    NSString *firmwareFile = [NSString stringWithFormat:@"%@/info/firmware.ver", device.getDPKGAdminDirectory];
    NSString *firwareVersion = [NSString stringWithFormat:@"%d\n", FIRMWARE_VERSION];

    if (![firwareVersion writeToFile:firmwareFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [firmware exitWithError:error andMessage:[NSString stringWithFormat:@"Error writing firmware version to %@", firmwareFile]];
    }
#endif

    DEBUGLOG("My work here is done.");
    return 0;
}
