#!/bin/bash
# Build the Intel VoodooTSCSync.kext with just the Command Line Tools (no Xcode project),
# against an old macOS SDK. Used for an i7-3770 (4C/8T) Hackintosh on OS X 10.9, where
# CpuTscSync's wake sync runs before the other threads are back up and the box hangs on wake.
#
#   SDK=/path/to/MacOSX10.9.sdk ./build.sh            -> build/VoodooTSCSync.kext
#   SDK=... LAST_CPU=3 MINOS=10.8 ./build.sh          other CPU / deployment target
#
# LAST_CPU is the IOCPUNumber of the last logical CPU (threads - 1): the kext matches that
# AppleACPICPU and resyncs every thread's TSC from its setPowerState, i.e. after all threads
# are running again on wake. The 10.9 SDK ships with Xcode 6.1.1 (developer.apple.com).
set -euo pipefail
SDK=${SDK:?set SDK to a MacOSX10.x.sdk path, e.g. one from Xcode 6.1.1}
MINOS=${MINOS:-10.9}
LAST_CPU=${LAST_CPU:-7}
BID=org.voodoo.driver.VoodooTSCSync
VER=1.1

cd "$(dirname "$0")"
KH=$SDK/System/Library/Frameworks/Kernel.framework/Headers
A="-arch x86_64 -mmacosx-version-min=$MINOS -isysroot $SDK"
F="$A -mkernel -fapple-kext -nostdinc -fno-builtin -fno-common -isystem $KH -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT -std=gnu++11 -fno-exceptions -fno-rtti -O2 -Wall"
O=build/obj
K=build/VoodooTSCSync.kext
mkdir -p $O

xcrun clang++ $F -c Intel/VoodooTSCSync.cpp -o $O/VoodooTSCSync.o
# Xcode normally generates kmod_info, which the kernel reads to start the kext.
printf '%s\n' '#include <mach/mach_types.h>' \
  'extern kern_return_t _start(kmod_info_t *, void *);' \
  'extern kern_return_t _stop(kmod_info_t *, void *);' \
  "__attribute__((visibility(\"default\"))) KMOD_EXPLICIT_DECL($BID, \"$VER\", _start, _stop)" \
  '__private_extern__ kmod_start_func_t *_realmain = 0;' \
  '__private_extern__ kmod_stop_func_t *_antimain = 0;' \
  '__private_extern__ int _kext_apple_cc = __APPLE_CC__;' > $O/kmod_info.c
xcrun clang $A -mkernel -nostdinc -fno-builtin -fno-common -isystem $KH -DKERNEL -O2 -c $O/kmod_info.c -o $O/kmod_info.o

rm -rf $K
mkdir -p $K/Contents/MacOS
xcrun clang++ $A -nostdlib -Xlinker -kext -lkmodc++ -lkmod -lcc_kext $O/VoodooTSCSync.o $O/kmod_info.o \
  -o $K/Contents/MacOS/VoodooTSCSync
sed -e 's/${EXECUTABLE_NAME}/VoodooTSCSync/g' -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BID/g" \
    -e 's/${PRODUCT_NAME:rfc1034Identifier}/VoodooTSCSync/g' -e 's/${PRODUCT_NAME}/VoodooTSCSync/g' \
    Intel/Info.plist > $K/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Set :IOKitPersonalities:VoodooTSCSync:IOPropertyMatch:IOCPUNumber $LAST_CPU" \
  $K/Contents/Info.plist
plutil -lint $K/Contents/Info.plist
echo "built $K (IOCPUNumber $LAST_CPU, macOS $MINOS+)"
