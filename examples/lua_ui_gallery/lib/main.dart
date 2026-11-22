// A gallery of Lua screens: core, Material and Cupertino widgets, routes
// between Lua instances, and remote bundles. Run it with
//
//   fvm flutter run -d macos
//
// The screens are the scripts under assets/lua/.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'gallery.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GalleryApp(scripts: await loadScripts(rootBundle)));
}
