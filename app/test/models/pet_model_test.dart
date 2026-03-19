import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/pet.dart';

void main() {
  group('PetModel Tests', () {
    group('constructor', () {
      test('should create PetModel with defaults', () {
        final pet = PetModel.create(name: '小財');

        expect(pet.name, equals('小財'));
        expect(pet.species, equals(PetSpecies.moneycat));
        expect(pet.exp, equals(0));
        expect(pet.streak, equals(0));
        expect(pet.mood, equals(PetMood.neutral));
        expect(pet.totalEntries, equals(0));
        expect(pet.level, equals(1));
      });

      test('should create PetModel with custom values', () {
        final pet = PetModel(
          id: 'pet-1',
          name: '阿財',
          species: PetSpecies.moneycat,
          exp: 250,
          streak: 5,
          mood: PetMood.happy,
          createdAt: DateTime(2026, 1, 1),
          totalEntries: 30,
          level: 3,
        );

        expect(pet.id, equals('pet-1'));
        expect(pet.name, equals('阿財'));
        expect(pet.exp, equals(250));
        expect(pet.streak, equals(5));
      });
    });

    group('stage', () {
      test('should return egg for exp 0-49', () {
        final pet = PetModel.create().copyWith(exp: 0);
        expect(pet.stage, equals(PetStage.egg));

        final pet2 = PetModel.create().copyWith(exp: 49);
        expect(pet2.stage, equals(PetStage.egg));
      });

      test('should return baby for exp 50-199', () {
        final pet = PetModel.create().copyWith(exp: 50);
        expect(pet.stage, equals(PetStage.baby));

        final pet2 = PetModel.create().copyWith(exp: 199);
        expect(pet2.stage, equals(PetStage.baby));
      });

      test('should return teen for exp 200-499', () {
        final pet = PetModel.create().copyWith(exp: 200);
        expect(pet.stage, equals(PetStage.teen));
      });

      test('should return adult for exp 500-999', () {
        final pet = PetModel.create().copyWith(exp: 500);
        expect(pet.stage, equals(PetStage.adult));
      });

      test('should return master for exp 1000+', () {
        final pet = PetModel.create().copyWith(exp: 1000);
        expect(pet.stage, equals(PetStage.master));

        final pet2 = PetModel.create().copyWith(exp: 5000);
        expect(pet2.stage, equals(PetStage.master));
      });
    });

    group('expToNextStage', () {
      test('should calculate correctly for egg', () {
        final pet = PetModel.create().copyWith(exp: 30);
        expect(pet.expToNextStage, equals(20));
      });

      test('should calculate correctly for baby', () {
        final pet = PetModel.create().copyWith(exp: 100);
        expect(pet.expToNextStage, equals(100));
      });

      test('should return 0 for master', () {
        final pet = PetModel.create().copyWith(exp: 1500);
        expect(pet.expToNextStage, equals(0));
      });
    });

    group('stageProgress', () {
      test('should return 0 for new pet', () {
        final pet = PetModel.create();
        expect(pet.stageProgress, equals(0.0));
      });

      test('should return 1.0 for master', () {
        final pet = PetModel.create().copyWith(exp: 1000);
        expect(pet.stageProgress, equals(1.0));
      });

      test('should return 0.5 for half way through baby', () {
        // baby: 50–199, range = 150, half = 75 → exp = 125
        final pet = PetModel.create().copyWith(exp: 125);
        expect(pet.stageProgress, equals(0.5));
      });
    });

    group('stageName', () {
      test('should return correct Chinese names', () {
        expect(PetModel.create().copyWith(exp: 0).stageName, equals('神秘蛋'));
        expect(PetModel.create().copyWith(exp: 50).stageName, equals('幼貓'));
        expect(PetModel.create().copyWith(exp: 200).stageName, equals('少年貓'));
        expect(PetModel.create().copyWith(exp: 500).stageName, equals('招財貓'));
        expect(PetModel.create().copyWith(exp: 1000).stageName, equals('金財神貓'));
      });
    });

    group('dialogue', () {
      test('should interpolate streak in happy dialogues', () {
        final pet = PetModel.create().copyWith(
          mood: PetMood.happy,
          streak: 7,
          totalEntries: 1,
        );
        final text = pet.dialogue;
        expect(text.contains('{streak}'), isFalse);
        expect(text.contains('7'), isTrue);
      });

      test('should return string for all mood types', () {
        for (final mood in PetMood.values) {
          final pet = PetModel.create().copyWith(mood: mood);
          expect(pet.dialogue.isNotEmpty, isTrue);
        }
      });
    });

    group('feedbackOnEntry', () {
      test('should warn on large amount', () {
        final pet = PetModel.create();
        expect(pet.feedbackOnEntry(1500), contains('不少'));
      });

      test('should encourage on small amount', () {
        final pet = PetModel.create();
        expect(pet.feedbackOnEntry(50), contains('很棒'));
      });

      test('should celebrate income', () {
        final pet = PetModel.create();
        expect(pet.feedbackOnEntry(0), contains('收入'));
      });
    });

    group('copyWith', () {
      test('should create a new instance with updated fields', () {
        final pet = PetModel.create(name: '小財');
        final updated = pet.copyWith(name: '大財', exp: 100);

        expect(updated.name, equals('大財'));
        expect(updated.exp, equals(100));
        expect(updated.id, equals(pet.id));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final pet = PetModel(
          id: 'pet-001',
          name: '小財',
          species: PetSpecies.moneycat,
          exp: 250,
          streak: 5,
          mood: PetMood.happy,
          lastFedAt: DateTime(2026, 3, 18, 12, 0),
          createdAt: DateTime(2026, 1, 1),
          totalEntries: 30,
          level: 3,
        );

        final json = pet.toJson();
        final restored = PetModel.fromJson(json);

        expect(restored.id, equals(pet.id));
        expect(restored.name, equals(pet.name));
        expect(restored.exp, equals(pet.exp));
        expect(restored.streak, equals(pet.streak));
        expect(restored.mood, equals(pet.mood));
        expect(restored.totalEntries, equals(pet.totalEntries));
        expect(restored.level, equals(pet.level));
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'pet-002',
          'name': '阿財',
          'species': 'moneycat',
          'createdAt': '2026-01-01T00:00:00.000',
        };

        final pet = PetModel.fromJson(json);
        expect(pet.exp, equals(0));
        expect(pet.streak, equals(0));
        expect(pet.mood, equals(PetMood.neutral));
        expect(pet.lastFedAt, isNull);
      });

      test('should handle unknown species/mood with defaults', () {
        final json = {
          'id': 'pet-003',
          'name': 'test',
          'species': 'unknown',
          'mood': 'unknown',
          'createdAt': '2026-01-01T00:00:00.000',
        };

        final pet = PetModel.fromJson(json);
        expect(pet.species, equals(PetSpecies.moneycat));
        expect(pet.mood, equals(PetMood.neutral));
      });
    });
  });
}
