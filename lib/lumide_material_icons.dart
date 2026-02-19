import 'package:lumide_api/lumide_api.dart';

/// Material Icons plugin for the Lumide IDE.
///
/// Contributes a comprehensive Material Design icon theme via
/// `plugin.yaml` → `contributes.iconThemes`. No runtime work is
/// needed — the IDE loads `icons/icon-theme.json` automatically.
class MaterialIconsPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {
    // Icon theme is registered via plugin.yaml contributes.iconThemes.
    // No runtime work required.
  }
}
