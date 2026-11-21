/// Deliver Lua bundles to a `flutter_lua_bridge` app.
///
/// A bundle is a `bundle.json` manifest and Lua modules, served from any
/// [LuaBundleSource]. [LuaBundleLoader] verifies each module against its
/// SHA-256, caches complete versions and falls back to the last good
/// version or a built-in bundle; [RemoteLuaView] shows the bundle's
/// `flutter_lua_bridge_ui` app and marks versions good or bad as they
/// render. Build manifests with `dart run flutter_lua_bridge_remote:pack`.
library;

export 'src/loader.dart'
    show
        LoadedLuaBundle,
        LuaBundleException,
        LuaBundleLoader,
        LuaBundleOrigin,
        LuaBundleVerifier;
export 'src/manifest.dart'
    show LuaBundleManifest, LuaBundleModule, luaBundleApi, sha256Hex;
export 'src/remote_view.dart' show LuaRuntimeFactory, RemoteLuaView;
export 'src/source.dart'
    show
        AssetBundleSource,
        DirectoryBundleSource,
        HttpBundleSource,
        LuaBundleSource,
        MemoryBundleSource;
