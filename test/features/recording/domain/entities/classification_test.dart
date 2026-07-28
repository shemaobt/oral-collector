import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';

void main() {
  group('kUnclassifiedGenreId', () {
    test('é a sentinela "unclassified"', () {
      expect(kUnclassifiedGenreId, 'unclassified');
    });
  });

  group('recordingHasGenre', () {
    test('false quando genreId é a sentinela unclassified', () {
      expect(recordingHasGenre(kUnclassifiedGenreId), isFalse);
    });

    test('true quando genreId é um id real', () {
      expect(recordingHasGenre('gen_1'), isTrue);
    });

    test(
      'true quando genreId é vazio (só a sentinela conta como sem gênero)',
      () {
        expect(recordingHasGenre(''), isTrue);
      },
    );
  });

  group('recordingHasRegister', () {
    test('false quando null', () {
      expect(recordingHasRegister(null), isFalse);
    });

    test('false quando string vazia', () {
      expect(recordingHasRegister(''), isFalse);
    });

    test('true quando preenchido', () {
      expect(recordingHasRegister('reg_1'), isTrue);
    });
  });

  group('recordingIsUnclassified', () {
    test('true quando falta gênero', () {
      expect(
        recordingIsUnclassified(
          genreId: kUnclassifiedGenreId,
          registerId: 'reg_1',
        ),
        isTrue,
      );
    });

    test('true quando falta registro', () {
      expect(
        recordingIsUnclassified(genreId: 'gen_1', registerId: null),
        isTrue,
      );
    });

    test('false quando gênero e registro presentes', () {
      expect(
        recordingIsUnclassified(genreId: 'gen_1', registerId: 'reg_1'),
        isFalse,
      );
    });

    test('true quando faltam gênero e registro', () {
      expect(
        recordingIsUnclassified(
          genreId: kUnclassifiedGenreId,
          registerId: null,
        ),
        isTrue,
      );
    });
  });

  group('recordingIsClassified', () {
    test('true quando gênero e registro presentes', () {
      expect(
        recordingIsClassified(genreId: 'gen_1', registerId: 'reg_1'),
        isTrue,
      );
    });

    test('false quando falta gênero', () {
      expect(
        recordingIsClassified(
          genreId: kUnclassifiedGenreId,
          registerId: 'reg_1',
        ),
        isFalse,
      );
    });

    test('false quando falta registro', () {
      expect(recordingIsClassified(genreId: 'gen_1', registerId: ''), isFalse);
    });
  });

  group('recordingHasSecondaryGenre', () {
    test('false quando null', () {
      expect(recordingHasSecondaryGenre(null), isFalse);
    });

    test('false quando string vazia', () {
      expect(recordingHasSecondaryGenre(''), isFalse);
    });

    test('false quando é a sentinela unclassified', () {
      expect(recordingHasSecondaryGenre(kUnclassifiedGenreId), isFalse);
    });

    test('true quando id real', () {
      expect(recordingHasSecondaryGenre('gen_2'), isTrue);
    });
  });

  group('recordingHasSecondaryRegister', () {
    test('false quando null', () {
      expect(recordingHasSecondaryRegister(null), isFalse);
    });

    test('false quando string vazia', () {
      expect(recordingHasSecondaryRegister(''), isFalse);
    });

    test('true quando preenchido', () {
      expect(recordingHasSecondaryRegister('reg_2'), isTrue);
    });

    test(
      'true mesmo com o valor da sentinela (registro não tem sentinela)',
      () {
        expect(recordingHasSecondaryRegister(kUnclassifiedGenreId), isTrue);
      },
    );
  });

  group('recordingHasSecondary', () {
    test('false quando ambos secundários ausentes', () {
      expect(
        recordingHasSecondary(
          secondaryGenreId: null,
          secondaryRegisterId: null,
        ),
        isFalse,
      );
    });

    test('true quando há gênero secundário', () {
      expect(
        recordingHasSecondary(
          secondaryGenreId: 'gen_2',
          secondaryRegisterId: null,
        ),
        isTrue,
      );
    });

    test('true quando há registro secundário', () {
      expect(
        recordingHasSecondary(
          secondaryGenreId: null,
          secondaryRegisterId: 'reg_2',
        ),
        isTrue,
      );
    });

    test('false quando gênero secundário é a sentinela e sem registro', () {
      expect(
        recordingHasSecondary(
          secondaryGenreId: kUnclassifiedGenreId,
          secondaryRegisterId: null,
        ),
        isFalse,
      );
    });

    test('false quando ambos secundários são string vazia', () {
      expect(
        recordingHasSecondary(secondaryGenreId: '', secondaryRegisterId: ''),
        isFalse,
      );
    });
  });

  group('secondaryEqualsPrimary', () {
    test('true quando o trio inteiro é idêntico', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: 'reg_1',
          primaryGenreId: 'gen_1',
          primarySubcategoryId: 'sub_1',
          secondaryRegisterId: 'reg_1',
          secondaryGenreId: 'gen_1',
          secondarySubcategoryId: 'sub_1',
        ),
        isTrue,
      );
    });

    test('false quando só o registro difere', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: 'reg_1',
          primaryGenreId: 'gen_1',
          primarySubcategoryId: 'sub_1',
          secondaryRegisterId: 'reg_2',
          secondaryGenreId: 'gen_1',
          secondarySubcategoryId: 'sub_1',
        ),
        isFalse,
      );
    });

    test('false quando só o gênero difere', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: 'reg_1',
          primaryGenreId: 'gen_1',
          primarySubcategoryId: 'sub_1',
          secondaryRegisterId: 'reg_1',
          secondaryGenreId: 'gen_2',
          secondarySubcategoryId: 'sub_1',
        ),
        isFalse,
      );
    });

    test('false quando só a subcategoria difere (Mito vs Lenda)', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: 'reg_1',
          primaryGenreId: 'gen_1',
          primarySubcategoryId: 'sub_mito',
          secondaryRegisterId: 'reg_1',
          secondaryGenreId: 'gen_1',
          secondarySubcategoryId: 'sub_lenda',
        ),
        isFalse,
      );
    });

    test('false quando o secundário é todo nulo e o primário preenchido', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: 'reg_1',
          primaryGenreId: 'gen_1',
          primarySubcategoryId: 'sub_1',
          secondaryRegisterId: null,
          secondaryGenreId: null,
          secondarySubcategoryId: null,
        ),
        isFalse,
      );
    });

    test('true quando nulos coincidem nos campos opcionais', () {
      expect(
        secondaryEqualsPrimary(
          primaryRegisterId: null,
          primaryGenreId: 'gen_1',
          primarySubcategoryId: null,
          secondaryRegisterId: null,
          secondaryGenreId: 'gen_1',
          secondarySubcategoryId: null,
        ),
        isTrue,
      );
    });
  });
}
