import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/pet.dart';

void main() {
  group('PetModel', () {
    late PetModel pet;

    setUp(() {
      pet = PetModel(
        id: 'test-pet',
        name: '小財',
        createdAt: DateTime(2026, 1, 1),
        exp: 0,
        streak: 0,
        mood: PetMood.neutral,
        totalEntries: 0,
        level: 1,
      );
    });

    // ── 進化階段測試 ──────────────────────────

    group('stage (進化階段)', () {
      test('exp=0 應為 egg', () {
        expect(pet.stage, PetStage.egg);
      });

      test('exp=49 應仍為 egg', () {
        final p = pet.copyWith(exp: 49);
        expect(p.stage, PetStage.egg);
      });

      test('exp=50 應進化為 baby', () {
        final p = pet.copyWith(exp: 50);
        expect(p.stage, PetStage.baby);
      });

      test('exp=199 應仍為 baby', () {
        final p = pet.copyWith(exp: 199);
        expect(p.stage, PetStage.baby);
      });

      test('exp=200 應進化為 teen', () {
        final p = pet.copyWith(exp: 200);
        expect(p.stage, PetStage.teen);
      });

      test('exp=500 應進化為 adult', () {
        final p = pet.copyWith(exp: 500);
        expect(p.stage, PetStage.adult);
      });

      test('exp=999 應仍為 adult', () {
        final p = pet.copyWith(exp: 999);
        expect(p.stage, PetStage.adult);
      });

      test('exp=1000 應進化為 master', () {
        final p = pet.copyWith(exp: 1000);
        expect(p.stage, PetStage.master);
      });

      test('exp=9999 應仍為 master', () {
        final p = pet.copyWith(exp: 9999);
        expect(p.stage, PetStage.master);
      });
    });

    // ── expToNextStage 測試 ──────────────────────

    group('expToNextStage', () {
      test('egg 階段需要 50 exp 進化', () {
        expect(pet.expToNextStage, 50);
      });

      test('exp=30 的 egg 還需 20', () {
        final p = pet.copyWith(exp: 30);
        expect(p.expToNextStage, 20);
      });

      test('baby 階段需要 200-exp', () {
        final p = pet.copyWith(exp: 100);
        expect(p.expToNextStage, 100);
      });

      test('teen 階段需要 500-exp', () {
        final p = pet.copyWith(exp: 300);
        expect(p.expToNextStage, 200);
      });

      test('adult 階段需要 1000-exp', () {
        final p = pet.copyWith(exp: 700);
        expect(p.expToNextStage, 300);
      });

      test('master 階段回傳 0', () {
        final p = pet.copyWith(exp: 1500);
        expect(p.expToNextStage, 0);
      });
    });

    // ── stageProgress 測試 ──────────────────────

    group('stageProgress', () {
      test('egg exp=0 進度為 0.0', () {
        expect(pet.stageProgress, 0.0);
      });

      test('egg exp=25 進度為 0.5', () {
        final p = pet.copyWith(exp: 25);
        expect(p.stageProgress, 0.5);
      });

      test('baby exp=125 進度為 0.5', () {
        final p = pet.copyWith(exp: 125);
        expect(p.stageProgress, 0.5);
      });

      test('teen exp=350 進度為 0.5', () {
        final p = pet.copyWith(exp: 350);
        expect(p.stageProgress, 0.5);
      });

      test('adult exp=750 進度為 0.5', () {
        final p = pet.copyWith(exp: 750);
        expect(p.stageProgress, 0.5);
      });

      test('master 進度為 1.0', () {
        final p = pet.copyWith(exp: 2000);
        expect(p.stageProgress, 1.0);
      });
    });

    // ── 階段顯示測試 ──────────────────────

    group('stageName / stageEmoji', () {
      test('egg 名稱為神秘蛋', () {
        expect(pet.stageName, '神秘蛋');
      });

      test('baby 名稱為幼貓', () {
        final p = pet.copyWith(exp: 50);
        expect(p.stageName, '幼貓');
      });

      test('teen 名稱為少年貓', () {
        final p = pet.copyWith(exp: 200);
        expect(p.stageName, '少年貓');
      });

      test('adult 名稱為招財貓', () {
        final p = pet.copyWith(exp: 500);
        expect(p.stageName, '招財貓');
      });

      test('master 名稱為金財神貓', () {
        final p = pet.copyWith(exp: 1000);
        expect(p.stageName, '金財神貓');
      });

      test('每個階段都有 emoji', () {
        for (final stage in PetStage.values) {
          final exp = switch (stage) {
            PetStage.egg => 0,
            PetStage.baby => 50,
            PetStage.teen => 200,
            PetStage.adult => 500,
            PetStage.master => 1000,
          };
          final p = pet.copyWith(exp: exp);
          expect(
            p.stageEmoji.isNotEmpty,
            true,
            reason: '${stage.name} 應有 emoji',
          );
        }
      });
    });

    // ── imagePath 測試 ──────────────────────

    group('imagePath', () {
      test('egg 階段固定為 egg.png', () {
        expect(pet.imagePath, 'assets/images/pet/egg.png');
      });

      test('baby + happy 路徑正確', () {
        final p = pet.copyWith(exp: 50, mood: PetMood.happy);
        expect(p.imagePath, 'assets/images/pet/baby_happy.png');
      });

      test('adult + sleepy 路徑正確', () {
        final p = pet.copyWith(exp: 500, mood: PetMood.sleepy);
        expect(p.imagePath, 'assets/images/pet/adult_sleepy.png');
      });

      test('master + hungry 路徑正確', () {
        final p = pet.copyWith(exp: 1000, mood: PetMood.hungry);
        expect(p.imagePath, 'assets/images/pet/master_hungry.png');
      });
    });

    // ── moodEmoji 測試 ──────────────────────

    group('moodEmoji', () {
      test('每種心情都有 emoji', () {
        for (final mood in PetMood.values) {
          final p = pet.copyWith(mood: mood);
          expect(p.moodEmoji.isNotEmpty, true, reason: '${mood.name} 應有 emoji');
        }
      });
    });

    // ── dialogue 測試 ──────────────────────

    group('dialogue (對話)', () {
      test('happy 心情有對話', () {
        final p = pet.copyWith(mood: PetMood.happy);
        expect(p.dialogue.isNotEmpty, true);
      });

      test('neutral 心情有對話', () {
        final p = pet.copyWith(mood: PetMood.neutral);
        expect(p.dialogue.isNotEmpty, true);
      });

      test('hungry 心情有對話', () {
        final p = pet.copyWith(mood: PetMood.hungry);
        expect(p.dialogue.isNotEmpty, true);
      });

      test('sleepy 心情有對話', () {
        final p = pet.copyWith(mood: PetMood.sleepy);
        expect(p.dialogue.isNotEmpty, true);
      });

      test('不同 totalEntries 產生不同對話（happy）', () {
        final dialogues = <String>{};
        for (var i = 0; i < 10; i++) {
          final p = pet.copyWith(mood: PetMood.happy, totalEntries: i);
          dialogues.add(p.dialogue);
        }
        // 至少 2 種不同對話
        expect(dialogues.length, greaterThan(1));
      });
    });

    // ── feedbackOnEntry 測試 ──────────────────────

    group('feedbackOnEntry', () {
      test('大額花費 (>1000) 給讚美長日記', () {
        final feedback = pet.feedbackOnEntry(1500);
        expect(feedback, '哇！寫了好長的日記，辛苦了～');
      });

      test('中等花費 (>500) 給鼓勵', () {
        final feedback = pet.feedbackOnEntry(800);
        expect(feedback, '不錯喔，持續記錄是好習慣 👍');
      });

      test('小額花費 (>0) 給讚美', () {
        final feedback = pet.feedbackOnEntry(50);
        expect(feedback, '很棒！每天記錄讓生活更有意義！');
      });

      test('無內容時 (<=0) 給期待回應', () {
        final feedback = pet.feedbackOnEntry(0);
        expect(feedback, '新的一天，期待你的分享！💕');
      });
    });

    // ── copyWith 測試 ──────────────────────

    group('copyWith', () {
      test('不傳參數回傳相同值', () {
        final copy = pet.copyWith();
        expect(copy.id, pet.id);
        expect(copy.name, pet.name);
        expect(copy.exp, pet.exp);
        expect(copy.streak, pet.streak);
        expect(copy.mood, pet.mood);
        expect(copy.totalEntries, pet.totalEntries);
      });

      test('覆寫 exp 不影響其他欄位', () {
        final copy = pet.copyWith(exp: 999);
        expect(copy.exp, 999);
        expect(copy.name, pet.name);
        expect(copy.streak, pet.streak);
      });

      test('覆寫多個欄位', () {
        final copy = pet.copyWith(
          name: '大財',
          exp: 500,
          streak: 7,
          mood: PetMood.happy,
        );
        expect(copy.name, '大財');
        expect(copy.exp, 500);
        expect(copy.streak, 7);
        expect(copy.mood, PetMood.happy);
      });
    });

    // ── JSON 序列化測試 ──────────────────────

    group('JSON serialization', () {
      test('toJson 應包含所有欄位', () {
        final json = pet.toJson();
        expect(json['id'], 'test-pet');
        expect(json['name'], '小財');
        expect(json['species'], 'moneycat');
        expect(json['exp'], 0);
        expect(json['streak'], 0);
        expect(json['mood'], 'neutral');
        expect(json['createdAt'], isNotNull);
        expect(json['totalEntries'], 0);
        expect(json['level'], 1);
      });

      test('fromJson 應正確還原', () {
        final json = pet.toJson();
        final restored = PetModel.fromJson(json);
        expect(restored.id, pet.id);
        expect(restored.name, pet.name);
        expect(restored.species, pet.species);
        expect(restored.exp, pet.exp);
        expect(restored.streak, pet.streak);
        expect(restored.mood, pet.mood);
        expect(restored.totalEntries, pet.totalEntries);
        expect(restored.level, pet.level);
      });

      test('toJson → fromJson 往返一致', () {
        final original = pet.copyWith(
          exp: 350,
          streak: 5,
          mood: PetMood.happy,
          totalEntries: 42,
          level: 4,
          lastFedAt: DateTime(2026, 3, 18, 10, 30),
        );
        final json = original.toJson();
        final restored = PetModel.fromJson(json);

        expect(restored.exp, 350);
        expect(restored.streak, 5);
        expect(restored.mood, PetMood.happy);
        expect(restored.totalEntries, 42);
        expect(restored.level, 4);
        expect(restored.lastFedAt, isNotNull);
      });

      test('fromJson 處理缺失欄位（使用預設值）', () {
        final json = <String, dynamic>{
          'id': 'minimal',
          'name': 'test',
          'createdAt': '2026-01-01T00:00:00.000',
        };
        final p = PetModel.fromJson(json);
        expect(p.exp, 0);
        expect(p.streak, 0);
        expect(p.mood, PetMood.neutral);
        expect(p.species, PetSpecies.moneycat);
        expect(p.totalEntries, 0);
        expect(p.level, 1);
      });

      test('fromJson 處理無效 mood 字串', () {
        final json = pet.toJson();
        json['mood'] = 'invalid_mood';
        final p = PetModel.fromJson(json);
        expect(p.mood, PetMood.neutral); // fallback
      });

      test('fromJson 處理無效 species 字串', () {
        final json = pet.toJson();
        json['species'] = 'unicorn';
        final p = PetModel.fromJson(json);
        expect(p.species, PetSpecies.moneycat); // fallback
      });

      test('lastFedAt 為 null 時 JSON 處理正確', () {
        final json = pet.toJson();
        expect(json['lastFedAt'], isNull);
        final restored = PetModel.fromJson(json);
        expect(restored.lastFedAt, isNull);
      });
    });

    // ── factory create 測試 ──────────────────────

    group('PetModel.create', () {
      test('建立預設寵物', () {
        final p = PetModel.create();
        expect(p.name, '小財');
        expect(p.exp, 0);
        expect(p.streak, 0);
        expect(p.mood, PetMood.neutral);
        expect(p.species, PetSpecies.moneycat);
        expect(p.id.isNotEmpty, true);
      });

      test('建立自訂名稱寵物', () {
        final p = PetModel.create(name: '大財');
        expect(p.name, '大財');
      });
    });
  });
}
