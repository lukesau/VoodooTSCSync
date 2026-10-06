# VoodooTSCSync
Fork of VoodooTSCSync

A kernel extension which will synchronize the TSC on any intel cpus.

The Kext matches using IOCPUNumber in the Info.plist

so if you have a c2duo, you'd set IOCPUNumber=1 if you have an i7 you'd set IOCPUNumber=7

(the # starts @ 0)

Credit: Cosmosis Jones (origin version for Intel)<br/>
            fumoboy007 (modified version for AMD)

## Building without Xcode

`build.sh` builds the Intel kext with only the Command Line Tools, against an old SDK:

    SDK=/path/to/MacOSX10.9.sdk ./build.sh

It writes `build/VoodooTSCSync.kext`. Set `LAST_CPU` to your thread count minus one
(default 7, for a 4-core/8-thread CPU) and `MINOS` for the deployment target (default 10.9).
The 10.9 SDK comes with Xcode 6.1.1 from developer.apple.com.

Used on an i7-3770 Hackintosh running OS X 10.9, injected by OpenCore, where CpuTscSync's
wake sync runs before the other threads are back up and the machine hangs on wake.
