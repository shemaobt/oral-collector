import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';

Map<String, dynamic> _json({
  Object sex = 'male',
  Object createdAt = '2026-01-02T03:04:05Z',
  bool includeUpdatedAt = false,
  Object? updatedAt,
}) {
  return <String, dynamic>{
    'id': 'stl_1',
    'project_id': 'proj_1',
    'name': 'João Silva',
    'sex': sex,
    'external_acceptance_confirmed': true,
    'created_at': createdAt,
    if (includeUpdatedAt) 'updated_at': updatedAt,
  };
}

void main() {
  group('StorytellerSex.fromWire', () {
    test('valores conhecidos mapeiam para o enum correto', () {
      expect(StorytellerSex.fromWire('male'), StorytellerSex.male);
      expect(StorytellerSex.fromWire('female'), StorytellerSex.female);
    });

    test('valor de wire desconhecido vira unknown sem lançar', () {
      expect(StorytellerSex.fromWire('intersex'), StorytellerSex.unknown);
      expect(StorytellerSex.fromWire(''), StorytellerSex.unknown);
    });
  });

  group('StorytellerSex.toWire', () {
    test('é byte-idêntico para os valores conhecidos', () {
      expect(StorytellerSex.male.toWire(), 'male');
      expect(StorytellerSex.female.toWire(), 'female');
    });
  });

  group('Storyteller.fromJson', () {
    test('sex desconhecido não lança e resulta em unknown', () {
      final s = Storyteller.fromJson(_json(sex: 'alien'));
      expect(s.sex, StorytellerSex.unknown);
    });

    test('sex válido preserva o wire no toJson (byte-idêntico)', () {
      final s = Storyteller.fromJson(_json(sex: 'female'));
      expect(s.sex, StorytellerSex.female);
      expect(s.toJson()['sex'], 'female');
    });

    test('sex não-string lança ParseException (tipo é contrato)', () {
      expect(
        () => Storyteller.fromJson(_json(sex: 42)),
        throwsA(isA<ParseException>().having((e) => e.field, 'field', 'sex')),
      );
    });

    test('created_at malformado lança ParseException', () {
      expect(
        () => Storyteller.fromJson(_json(createdAt: 'not-a-date')),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'created_at'),
        ),
      );
    });

    test('updated_at ausente é null; presente e válido é parseado', () {
      expect(Storyteller.fromJson(_json()).updatedAt, isNull);
      final s = Storyteller.fromJson(
        _json(includeUpdatedAt: true, updatedAt: '2026-02-03T04:05:06Z'),
      );
      expect(s.updatedAt, DateTime.utc(2026, 2, 3, 4, 5, 6));
    });
  });
}
