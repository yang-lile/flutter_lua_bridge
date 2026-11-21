# flutter_lua_bridge_remote

Deliver Lua apps to a Flutter app that uses
[`flutter_lua_bridge_ui`](https://pub.dev/packages/flutter_lua_bridge_ui):
fetch a bundle of Lua modules, verify it, cache it, show it, and fall back
to the last version that worked.

```dart
RemoteLuaView(
  loader: LuaBundleLoader(
    source: HttpBundleSource(Uri.parse('https://example.com/lua/shop/')),
    cacheDirectory: Directory('${support.path}/lua/shop'), // one per bundle
    fallback: AssetBundleSource('assets/lua/shop/'),       // built-in copy
  ),
  libraries: [coreLibrary(icons: icons), materialLibrary()],
  loading: (context) => const Center(child: CircularProgressIndicator()),
  fallback: (context, error) => const Text('Unavailable'),
)
```

## Bundles

A bundle is a directory of Lua modules and a `bundle.json`:

```json
{
  "name": "shop",
  "version": "1.4.0",
  "entry": "app",
  "modules": {
    "app": {"path": "app.lua", "sha256": "…"},
    "cart": {"path": "cart.lua", "sha256": "…"}
  },
  "requires": {"libraries": ["core", "material"], "api": 1}
}
```

The entry module returns `App {...}`; the others are available to
`require`. Write the manifest with

```sh
dart run flutter_lua_bridge_remote:pack build/shop --name shop --version 1.4.0 --library material
```

and serve the directory as static files.

## Loading

`LuaBundleLoader.load` fetches `bundle.json`, downloads the modules that
are not cached yet, checks each one against its SHA-256 and commits the
version to `cacheDirectory/versions/<version>/` only once it is complete.
It uses the first of these that works:

1. the version the source offers now;
2. the newest version marked good in the cache;
3. the `fallback` source, usually a copy in the app's assets.

A version is skipped when it cannot be downloaded or verified, needs a
widget library the host did not register (`requires.libraries`) or a newer
bundle format (`requires.api`), or was marked bad.

`RemoteLuaView` runs each version in a fresh `LuaRuntime`, marks it good
after its first frame and marks it bad when loading or the first render
fails, then shows the next candidate. A broken release therefore costs one
failed render on each device, after which the device stays on the last good
version until a newer one is published. The two newest good versions stay
in the cache (`keepVersions`).

## Security

The SHA-256 sums detect damaged or partial downloads. They do not prove
who wrote the bundle: anyone who can change `bundle.json` can change the
sums. Serve bundles over HTTPS, and check a signature of `bundle.json` in
`verify` when the scripts must come from you. Lua code runs with the
standard libraries the runtime was created with; give `createRuntime` a
memory limit and only the libraries the scripts need.
