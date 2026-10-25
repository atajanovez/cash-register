import 'package:cash_register/core/format/dates.dart';
import 'package:cash_register/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

const nbsp = ' ';

void main() {
  test('formats minor units Turkmen style', () {
    expect(Money.format(0), '0,00${nbsp}TMT');
    expect(Money.format(115400), '1${nbsp}154,00${nbsp}TMT');
    expect(Money.format(123456789), '1${nbsp}234${nbsp}567,89${nbsp}TMT');
    expect(Money.format(5), '0,05${nbsp}TMT');
    expect(Money.signed(2500), '+25,00${nbsp}TMT');
    expect(Money.signed(-2500), '−25,00${nbsp}TMT');
  });

  test('parses typed amounts with comma or dot', () {
    expect(Money.parse('12'), 1200);
    expect(Money.parse('12,5'), 1250);
    expect(Money.parse('12.05'), 1205);
    expect(Money.parse('1 234,56'), 123456);
    expect(Money.parse('12,'), 1200);
    expect(Money.parse(''), isNull);
    expect(Money.parse('1,234'), isNull);
    expect(Money.parse('abc'), isNull);
    expect(Money.toInput(1205), '12,05');
    expect(Money.toInput(1200), '12');
  });

  test('input formatter keeps two decimals and shows a comma', () {
    final f = AmountInputFormatter();
    TextEditingValue apply(String oldText, String newText) =>
        f.formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(text: newText),
        );
    expect(apply('12', '12.').text, '12,');
    expect(apply('12,34', '12,345').text, '12,34');
    expect(apply('12', '12a').text, '12');
    expect(apply('1,2', '1,2,').text, '1,2');
  });

  test('formats dates in Turkmen', () {
    final now = DateTime(2026, 10, 21, 12);
    expect(Dates.date(DateTime(2026, 11, 2)), '02.11.2026');
    expect(Dates.dateTime(DateTime(2026, 11, 2, 9, 5)), '02.11.2026, 09:05');
    expect(Dates.short(DateTime(2026, 11, 2), now: now), '2 noýabr');
    expect(Dates.short(DateTime(2027, 1, 5), now: now), '05.01.2027');
    String header(DateTime d) =>
        Dates.dayHeader(d, today: 'T', yesterday: 'Y', now: now);
    expect(header(DateTime(2026, 10, 21, 8)), 'T');
    expect(header(DateTime(2026, 10, 20, 23)), 'Y');
    expect(header(DateTime(2026, 10, 19)), 'Duşenbe, 19 oktýabr');
  });

  test('converts old manats at 5 000 : 1', () {
    expect(Money.fromOld(1000000), 20000); // 200,00 TMT
    expect(Money.fromOld(1000), 20); // 0,20 TMT
    expect(Money.fromOld(5000), 100); // 1,00 TMT
    expect(Money.fromOld(2500000), 50000); // 500,00 TMT
    expect(Money.fromOld(30), 1); // rounds to the nearest teňňe
    expect(Money.groupDigits(1000000), '1${nbsp}000${nbsp}000');
  });
}
