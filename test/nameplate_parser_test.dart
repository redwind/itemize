import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/nameplate_parser.dart';

void main() {
  NameplateInfo parse(String text) => NameplateParser.parse(text);

  group('serial numbers', () {
    test('reads the common label spellings', () {
      for (final label in [
        'S/N: 4829571003',
        'SN: 4829571003',
        'Serial No. 4829571003',
        'Serial Number: 4829571003',
        'SERIAL: 4829571003',
      ]) {
        expect(parse(label).serialNumber, '4829571003', reason: label);
      }
    });

    test('reads a value printed on the line below the label', () {
      const plate = '''
SAMSUNG
SERIAL NO.
R52M4A0KT01
''';
      expect(parse(plate).serialNumber, 'R52M4A0KT01');
    });

    test('keeps dashes and slashes inside a serial', () {
      expect(parse('S/N: AB-1234/56').serialNumber, 'AB-1234/56');
    });

    test('refuses a label followed by nothing usable', () {
      // A word with no digit is prose, not a serial.
      expect(parse('Serial: unknown').serialNumber, isNull);
      expect(parse('S/N:').serialNumber, isNull);
      expect(parse('S/N: 12').serialNumber, isNull);
    });

    test('does not match the label inside an unrelated word', () {
      expect(parse('This item was assigned by us').serialNumber, isNull);
    });
  });

  group('model numbers', () {
    test('reads the common label spellings', () {
      for (final label in [
        'Model: WH-1000XM5',
        'Model No.: WH-1000XM5',
        'MODEL WH-1000XM5',
        'M/N: WH-1000XM5',
        'Type: WH-1000XM5',
      ]) {
        expect(parse(label).model, 'WH-1000XM5', reason: label);
      }
    });

    test('accepts a model with no digits in it', () {
      expect(parse('Model: KIVIK').model, 'KIVIK');
    });

    test('refuses a sentence that happens to follow the word', () {
      expect(
        parse('Model: see the manual supplied with this appliance').model,
        isNull,
      );
    });
  });

  group('brand', () {
    test('is taken from the top of the plate', () {
      const plate = '''
Panasonic
Model: NR-BX471
S/N: 8829150021
''';
      expect(parse(plate).brand, 'Panasonic');
    });

    test('skips boilerplate that is never a manufacturer', () {
      const plate = '''
MADE IN VIETNAM
Electrolux
Model: EWF8024
''';
      expect(parse(plate).brand, 'Electrolux');
    });

    test('skips a ratings line of mostly numbers', () {
      const plate = '''
220-240V 50Hz 1800W
Philips
Model: HD9270
''';
      expect(parse(plate).brand, 'Philips');
    });

    test('does not reach past the top of the plate to find one', () {
      const plate = '''
220-240V 50Hz
1800W
input current 8A
output rating
Philips
''';
      expect(parse(plate).brand, isNull);
    });
  });

  group('whole plates', () {
    test('a realistic refrigerator plate', () {
      const plate = '''
SAMSUNG
REFRIGERATOR
MODEL NO.: RF23R6201SR/AA
SERIAL NO.: 0GP34ADT300123
RATED VOLTAGE: 115V~ 60Hz
MADE IN KOREA
''';
      final info = parse(plate);
      expect(info.brand, 'SAMSUNG');
      expect(info.model, 'RF23R6201SR/AA');
      expect(info.serialNumber, '0GP34ADT300123');
      expect(info.fieldCount, 3);
    });

    test('a laptop underside, values stacked below their labels', () {
      const plate = '''
Dell
Model
P75F001
Service Tag
7KJ2LM3
Serial No
CN0X5T9P
''';
      final info = parse(plate);
      expect(info.brand, 'Dell');
      expect(info.model, 'P75F001');
      expect(info.serialNumber, 'CN0X5T9P');
    });

    test('a Vietnamese-labelled plate', () {
      const plate = '''
Sunhouse
Model: SHD2019
So may: 20241130456
''';
      final info = parse(plate);
      expect(info.brand, 'Sunhouse');
      expect(info.model, 'SHD2019');
      expect(info.serialNumber, '20241130456');
    });

    test('unreadable text yields nothing rather than nonsense', () {
      final info = parse('~~~ \n ||| \n ???');
      expect(info.isEmpty, isTrue);
    });

    test('empty input does not throw', () {
      expect(parse('').isEmpty, isTrue);
      expect(parse('   \n  \n ').isEmpty, isTrue);
    });
  });
}
