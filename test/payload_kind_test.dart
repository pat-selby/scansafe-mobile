import 'package:flutter_test/flutter_test.dart';
import 'package:scansafe/core/payload_kind.dart';

void main() {
  group('looksLikeUrl accepts things worth scoring', () {
    const urls = [
      'https://grambling.edu',
      'http://secure-login.xyz/verify?user=admin',
      'example.com',
      'example.com/login',
      'sub.example.co.uk/path?q=1',
      'PayPa1.com/Login',
      // Dangerous schemes must still reach the engine — Rule 14 exists for
      // exactly these, and a blob: QR code was a real attack.
      'blob:https://outlook.office.com/02573e0c',
      'data:text/html,<script>alert(1)</script>',
      'javascript:alert(1)',
      'vbscript:msgbox(1)',
    ];
    for (final url in urls) {
      test('"$url"', () => expect(looksLikeUrl(url), isTrue));
    }
  });

  group('looksLikeUrl rejects payloads that are not links', () {
    const others = [
      'WIFI:S:CampusWiFi;T:WPA;P:hunter2;;',
      'BEGIN:VCARD\nFN:Patrick Selby\nEND:VCARD',
      'BEGIN:VEVENT\nSUMMARY:Lab meeting\nEND:VEVENT',
      'mailto:pselby@gsumail.gram.edu',
      'tel:+15551234567',
      'smsto:+15551234567:hello',
      'geo:32.52,-92.71',
      'otpauth://totp/ScanSafe:pat?secret=ABC',
      'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      'Just some plain text',
      'Room 214, Carver Hall',
      '',
      '   ',
    ];
    for (final payload in others) {
      test('"${payload.replaceAll('\n', ' ')}"',
          () => expect(looksLikeUrl(payload), isFalse));
    }
  });

  group('describePayload names the content type', () {
    test('recognises common QR payload kinds', () {
      expect(describePayload('WIFI:S:X;;'), 'Wi-Fi network details');
      expect(describePayload('BEGIN:VCARD'), 'a contact card');
      expect(describePayload('mailto:a@b.com'), 'an email address');
      expect(describePayload('tel:+1555'), 'a phone number');
      expect(describePayload('geo:1,2'), 'a map location');
      expect(describePayload('otpauth://totp/x'), 'a two-factor setup code');
      expect(describePayload('hello world'), 'plain text');
    });
  });
}
