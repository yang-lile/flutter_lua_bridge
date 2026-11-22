// Runs the widget tests of test/gallery_test.dart in the macOS app:
//
//   fvm flutter test integration_test -d macos
import 'package:integration_test/integration_test.dart';

import '../test/gallery_test.dart' as gallery;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  gallery.main();
}
