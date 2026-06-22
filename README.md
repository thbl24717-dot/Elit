# zsign engine integration

The Elite app signs IPAs on-device using the open-source **zsign** engine
(the same family of engine used by ESign / Feather / SideStore).

## How to add the engine

1. Clone zsign sources:
   ```bash
   git clone https://github.com/zhlynn/zsign.git
   ```
2. Drag the C/C++ sources from `zsign/common`, `zsign/openssl` headers and
   the core files (`bundle.cpp`, `macho.cpp`, `signing.cpp`, `zsign.cpp`,
   `archo.cpp`, etc.) into the **Elite** target in Xcode.
3. Add **OpenSSL** for iOS (static `libcrypto.a` / `libssl.a`) and link it.
   You can use a prebuilt OpenSSL.xcframework.
4. Create `ZSign.h` / `ZSign.mm` (Objective-C++) that wraps zsign's
   `ZAppBundle` / sign entry points and matches the interface used by
   `ZSignWrapper.swift`:

   ```objc
   // ZSign.h
   #import <Foundation/Foundation.h>
   @interface ZSign : NSObject
   + (int)signWithIPA:(NSString *)ipa
                   p12:(NSString *)p12
             provision:(NSString *)provision
              password:(NSString *)password
                output:(NSString *)output
                 error:(NSString **)error;
   @end
   ```

5. In **Build Settings** set the bridging header to
   `Elite/Signing/Elite-Bridging-Header.h`. Once `ZSign.h` is importable,
   `ZSIGN_AVAILABLE` is defined automatically and the Swift wrapper calls
   the real engine.

Until the engine is linked, `ZSignWrapper` returns a clear message instead
of crashing, so the full UI remains testable.
