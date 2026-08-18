import 'package:flutter_test/flutter_test.dart';
import 'package:studium_mobile/core/validators/field_validators.dart';

void main() {
  group('requiredValidator', () {
    test('rejects null', () {
      expect(requiredValidator(null), 'Ce champ est requis');
    });
    test('rejects empty/blank', () {
      expect(requiredValidator(''), isNotNull);
      expect(requiredValidator('   '), isNotNull);
    });
    test('accepts non-empty value', () {
      expect(requiredValidator('Aly'), isNull);
    });
    test('uses custom message', () {
      expect(requiredValidator(null, message: 'Champ requis'), 'Champ requis');
    });
  });

  group('emailValidator', () {
    test('rejects empty', () {
      expect(emailValidator(''), isNotNull);
    });
    test('rejects malformed email', () {
      expect(emailValidator('test@test'), isNotNull);
      expect(emailValidator('not-an-email'), isNotNull);
    });
    test('accepts well-formed email', () {
      expect(emailValidator('test@test.com'), isNull);
    });
  });

  group('passwordValidator', () {
    test('rejects empty', () {
      expect(passwordValidator(''), isNotNull);
    });
    test('rejects below minimum length', () {
      expect(passwordValidator('short'), isNotNull);
    });
    test('accepts 8+ characters by default', () {
      expect(passwordValidator('longenough'), isNull);
    });
    test('respects custom minLength', () {
      expect(passwordValidator('1234', minLength: 4), isNull);
      expect(passwordValidator('123', minLength: 4), isNotNull);
    });
  });

  group('confirmPasswordValidator', () {
    test('rejects empty', () {
      expect(confirmPasswordValidator('', 'secret123'), isNotNull);
    });
    test('rejects mismatch', () {
      expect(confirmPasswordValidator('other', 'secret123'), isNotNull);
    });
    test('accepts match', () {
      expect(confirmPasswordValidator('secret123', 'secret123'), isNull);
    });
  });

  group('gradeValidator', () {
    test('required by default when empty', () {
      expect(gradeValidator(''), isNotNull);
    });
    test('optional accepts empty', () {
      expect(gradeValidator('', optional: true), isNull);
      expect(gradeValidator(null, optional: true), isNull);
    });
    test('rejects non-numeric', () {
      expect(gradeValidator('abc'), isNotNull);
    });
    test('accepts comma as decimal separator', () {
      expect(gradeValidator('15,5'), isNull);
    });
    test('accepts boundary values 0 and 20', () {
      expect(gradeValidator('0'), isNull);
      expect(gradeValidator('20'), isNull);
    });
    test('rejects out-of-range values', () {
      expect(gradeValidator('-1'), isNotNull);
      expect(gradeValidator('20.1'), isNotNull);
    });
  });

  group('wordCountValidator', () {
    test('required by default when empty', () {
      expect(wordCountValidator('', min: 2, max: 5), isNotNull);
    });
    test('optional accepts empty', () {
      expect(wordCountValidator('', min: 2, max: 5, optional: true), isNull);
    });
    test('rejects below minimum', () {
      expect(wordCountValidator('one', min: 2, max: 5), isNotNull);
    });
    test('rejects above maximum', () {
      expect(wordCountValidator('one two three four five six', min: 2, max: 5), isNotNull);
    });
    test('accepts within range', () {
      expect(wordCountValidator('one two three', min: 2, max: 5), isNull);
    });
  });

  group('countWords', () {
    test('empty string has 0 words', () {
      expect(countWords(''), 0);
      expect(countWords('   '), 0);
    });
    test('counts words separated by whitespace', () {
      expect(countWords('one two three'), 3);
    });
  });
}
