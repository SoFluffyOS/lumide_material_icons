import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> themeJson;

  setUpAll(() {
    final file = File('icons/icon-theme.json');
    expect(file.existsSync(), isTrue, reason: 'icon-theme.json must exist');
    themeJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('icon-theme.json structure', () {
    test('has required top-level keys', () {
      expect(themeJson['name'], isA<String>());
      expect(themeJson['fileExtensions'], isA<Map>());
      expect(themeJson['fileNames'], isA<Map>());
      expect(themeJson['folderNames'], isA<Map>());
      expect(themeJson['folderNamesExpanded'], isA<Map>());
      expect(themeJson['defaultFileIcon'], isNotNull);
      expect(themeJson['defaultFolderIcon'], isNotNull);
      expect(themeJson['defaultFolderExpandedIcon'], isNotNull);
    });

    test('has iconDefinitions', () {
      final defs = themeJson['iconDefinitions'] as Map;
      expect(defs, isNotEmpty);
      // Each definition should have iconPath
      for (final entry in defs.entries) {
        final value = entry.value as Map;
        expect(value['iconPath'], isA<String>(),
            reason: '${entry.key} should have iconPath');
      }
    });

    test('has languageIds', () {
      final langIds = themeJson['languageIds'] as Map;
      expect(langIds, isNotEmpty);
      expect(langIds['dart'], isNotNull);
      expect(langIds['javascript'], isNotNull);
      expect(langIds['python'], isNotNull);
    });

    test('has filePatterns', () {
      final patterns = themeJson['filePatterns'] as Map;
      expect(patterns, isNotEmpty);
      // Verify regex patterns are valid
      for (final pattern in patterns.keys) {
        expect(() => RegExp(pattern as String), returnsNormally,
            reason: 'Pattern "$pattern" should be a valid regex');
      }
    });
  });

  group('file extension mappings', () {
    late Map exts;

    setUp(() {
      exts = themeJson['fileExtensions'] as Map;
    });

    test('covers Dart / Flutter', () {
      expect(exts['dart'], isNotNull);
      expect(exts['arb'], isNotNull);
    });

    test('covers config formats', () {
      expect(exts['yaml'], isNotNull);
      expect(exts['yml'], isNotNull);
      expect(exts['json'], isNotNull);
      expect(exts['toml'], isNotNull);
      expect(exts['xml'], isNotNull);
    });

    test('covers web languages', () {
      expect(exts['html'], isNotNull);
      expect(exts['css'], isNotNull);
      expect(exts['js'], isNotNull);
      expect(exts['ts'], isNotNull);
      expect(exts['tsx'], isNotNull);
      expect(exts['jsx'], isNotNull);
    });

    test('covers systems languages', () {
      expect(exts['rs'], isNotNull);
      expect(exts['go'], isNotNull);
      expect(exts['java'], isNotNull);
      expect(exts['kt'], isNotNull);
      expect(exts['swift'], isNotNull);
      expect(exts['c'], isNotNull);
      expect(exts['cpp'], isNotNull);
      expect(exts['py'], isNotNull);
    });

    test('covers media types', () {
      expect(exts['png'], isNotNull);
      expect(exts['jpg'], isNotNull);
      expect(exts['svg'], isNotNull);
      expect(exts['mp3'], isNotNull);
      expect(exts['mp4'], isNotNull);
    });
  });

  group('file name mappings', () {
    late Map names;

    setUp(() {
      names = themeJson['fileNames'] as Map;
    });

    test('covers Dart-specific files', () {
      expect(names['pubspec.yaml'], isNotNull);
      expect(names['pubspec.lock'], isNotNull);
      expect(names['analysis_options.yaml'], isNotNull);
    });

    test('covers common config files', () {
      expect(names['.gitignore'], isNotNull);
      expect(names['Dockerfile'], isNotNull);
      expect(names['Makefile'], isNotNull);
      expect(names['LICENSE'], isNotNull);
      expect(names['README.md'], isNotNull);
    });
  });

  group('folder mappings', () {
    test('covers key folders', () {
      final folders = themeJson['folderNames'] as Map;
      expect(folders['lib'], isNotNull);
      expect(folders['test'], isNotNull);
      expect(folders['src'], isNotNull);
      expect(folders['assets'], isNotNull);
      expect(folders['.git'], isNotNull);
      expect(folders['.github'], isNotNull);
    });

    test('has expanded variants for all mapped folders', () {
      final collapsed = themeJson['folderNames'] as Map;
      final expanded = themeJson['folderNamesExpanded'] as Map;
      for (final key in collapsed.keys) {
        if (key == '.idea') continue; // .idea reuses config icon, no expanded
        expect(expanded.containsKey(key), isTrue,
            reason: 'Folder "$key" should have an expanded variant');
      }
    });
  });

  group('icon files exist', () {
    test('all referenced icon files exist on disk', () {
      final defs = themeJson['iconDefinitions'] as Map;
      final allRefs = <String>{};

      // Collect all direct path references
      void collectRefs(Map? map) {
        if (map == null) return;
        for (final value in map.values) {
          if (value is String && !value.startsWith('_')) {
            allRefs.add(value);
          }
        }
      }

      collectRefs(themeJson['fileExtensions'] as Map?);
      collectRefs(themeJson['fileNames'] as Map?);
      collectRefs(themeJson['folderNames'] as Map?);
      collectRefs(themeJson['folderNamesExpanded'] as Map?);

      // Also collect from iconDefinitions
      for (final def in defs.values) {
        final iconPath = (def as Map)['iconPath'] as String?;
        if (iconPath != null) allRefs.add(iconPath);
      }

      // Also check defaults if they're direct paths
      for (final key in [
        'defaultFileIcon',
        'defaultFolderIcon',
        'defaultFolderExpandedIcon',
      ]) {
        final val = themeJson[key] as String?;
        if (val != null && !val.startsWith('_')) {
          allRefs.add(val);
        }
      }

      final missing = <String>[];
      for (final ref in allRefs) {
        final file = File('icons/$ref');
        if (!file.existsSync()) {
          missing.add(ref);
        }
      }

      expect(missing, isEmpty,
          reason: 'Missing icon files: ${missing.join(', ')}');
    });
  });

  group('regex patterns', () {
    test('.env files match env pattern', () {
      final patterns = themeJson['filePatterns'] as Map;
      final envPattern = patterns.keys.firstWhere(
        (k) => (k as String).contains('env'),
      ) as String;
      final regex = RegExp(envPattern);
      expect(regex.hasMatch('.env'), isTrue);
      expect(regex.hasMatch('.env.local'), isTrue);
      expect(regex.hasMatch('.env.production'), isTrue);
      expect(regex.hasMatch('something.env.bak'), isTrue);
    });

    test('rc files match config pattern', () {
      final patterns = themeJson['filePatterns'] as Map;
      final rcPattern = patterns.keys.firstWhere(
        (k) => (k as String).contains('rc'),
      ) as String;
      final regex = RegExp(rcPattern);
      expect(regex.hasMatch('.bashrc'), isTrue);
      expect(regex.hasMatch('.eslintrc'), isTrue);
      expect(regex.hasMatch('.prettierrc'), isTrue);
    });

    test('test files match test pattern', () {
      final patterns = themeJson['filePatterns'] as Map;
      final testPatterns = patterns.keys
          .where((k) => '$k'.contains('test') || '$k'.contains('spec'))
          .map((k) => k as String)
          .toList();

      expect(testPatterns, isNotEmpty);

      // Check dart test files
      final dartTestPattern = patterns.keys.firstWhere(
        (k) => (k as String).contains('_test'),
      ) as String;
      expect(RegExp(dartTestPattern).hasMatch('widget_test.dart'), isTrue);
    });
  });
}
