#ifndef vpnconfiguration_h
#define vpnconfiguration_h

#include <CoreFoundation/CoreFoundation.h>
#include <SystemConfiguration/SCPreferencesPrivate.h>

#if __has_include(<SystemConfiguration/SCNetworkSettingsManager.h>)
#include <SystemConfiguration/SCNetworkSettingsManager.h>
#endif

bool VPNConfigurationIsVPNTypeEnabled(CFStringRef vpnType);
int VPNConfigurationSetAuthorization(AuthorizationRef authorization);
int VPNConfigurationEnableVPNType(CFStringRef vpnType);

#endif
