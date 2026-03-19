/// 寵物養成系統 — 資料模型
///
/// 進化路線（v1 單一路線）：
///   蛋 (egg) → 幼體 (baby) → 少年 (teen) → 成體 (adult) → 大師 (master)
///
/// 進化條件由「記帳經驗值 (exp)」驅動：
///   - 每記一筆帳 +10 exp
///   - 連續記帳天數 streak bonus: streak * 2
///   - 省錢達標（日支出 < 預算）+5 exp
///
/// 未來擴充：
///   - 多寵物種族 (PetSpecies)
///   - 分支進化 (根據消費習慣走不同路線)
///   - 裝飾/配件系統
///   - 寵物技能（解鎖特殊報表功能）

enum PetStage {
  egg, // 0–49 exp
  baby, // 50–199 exp
  teen, // 200–499 exp
  adult, // 500–999 exp
  master, // 1000+ exp
}

enum PetMood {
  happy, // 今天有記帳 + 省錢
  neutral, // 今天有記帳
  hungry, // 超過 24hr 沒記帳
  sleepy, // 超過 48hr 沒記帳
}

enum PetSpecies {
  moneycat, // v1 預設：招財貓
  // 未來：dragon, owl, fox, etc.
}

class PetModel {
  final String id;
  final String name;
  final PetSpecies species;
  final int exp;
  final int streak; // 連續記帳天數
  final PetMood mood;
  final DateTime? lastFedAt; // 最後記帳時間
  final DateTime createdAt;
  final int totalEntries; // 累計記帳筆數
  final int level; // 等級 = exp / 100 + 1

  const PetModel({
    required this.id,
    required this.name,
    this.species = PetSpecies.moneycat,
    this.exp = 0,
    this.streak = 0,
    this.mood = PetMood.neutral,
    this.lastFedAt,
    required this.createdAt,
    this.totalEntries = 0,
    this.level = 1,
  });

  /// 當前進化階段
  PetStage get stage {
    if (exp >= 1000) return PetStage.master;
    if (exp >= 500) return PetStage.adult;
    if (exp >= 200) return PetStage.teen;
    if (exp >= 50) return PetStage.baby;
    return PetStage.egg;
  }

  /// 到下一階段還需多少 exp
  int get expToNextStage {
    switch (stage) {
      case PetStage.egg:
        return 50 - exp;
      case PetStage.baby:
        return 200 - exp;
      case PetStage.teen:
        return 500 - exp;
      case PetStage.adult:
        return 1000 - exp;
      case PetStage.master:
        return 0; // 已滿級
    }
  }

  /// 當前階段的進度 (0.0 ~ 1.0)
  double get stageProgress {
    switch (stage) {
      case PetStage.egg:
        return exp / 50;
      case PetStage.baby:
        return (exp - 50) / 150;
      case PetStage.teen:
        return (exp - 200) / 300;
      case PetStage.adult:
        return (exp - 500) / 500;
      case PetStage.master:
        return 1.0;
    }
  }

  /// 階段的中文名稱
  String get stageName {
    switch (stage) {
      case PetStage.egg:
        return '神秘蛋';
      case PetStage.baby:
        return '幼貓';
      case PetStage.teen:
        return '少年貓';
      case PetStage.adult:
        return '招財貓';
      case PetStage.master:
        return '金財神貓';
    }
  }

  /// 階段對應的 emoji（fallback）
  String get stageEmoji {
    switch (stage) {
      case PetStage.egg:
        return '🥚';
      case PetStage.baby:
        return '🐱';
      case PetStage.teen:
        return '😺';
      case PetStage.adult:
        return '😸';
      case PetStage.master:
        return '🏆';
    }
  }

  /// 取得圖片路徑（根據階段 + 心情）
  String get imagePath {
    if (stage == PetStage.egg) return 'assets/images/pet/egg.png';
    return 'assets/images/pet/${stage.name}_${mood.name}.png';
  }

  /// 心情對應的表情
  String get moodEmoji {
    switch (mood) {
      case PetMood.happy:
        return '✨';
      case PetMood.neutral:
        return '😊';
      case PetMood.hungry:
        return '😿';
      case PetMood.sleepy:
        return '😴';
    }
  }

  /// 寵物根據狀態說的話
  String get dialogue {
    String raw;
    switch (mood) {
      case PetMood.happy:
        raw = _happyDialogues[totalEntries % _happyDialogues.length];
      case PetMood.neutral:
        raw = _neutralDialogues[totalEntries % _neutralDialogues.length];
      case PetMood.hungry:
        raw = _hungryDialogues[streak % _hungryDialogues.length];
      case PetMood.sleepy:
        raw = _sleepyDialogues[streak % _sleepyDialogues.length];
    }
    // 插值模板變數
    return raw
        .replaceAll('{streak}', '$streak')
        .replaceAll('{name}', name)
        .replaceAll('{level}', '$level')
        .replaceAll('{exp}', '$exp');
  }

  /// 記帳時的反饋語
  String feedbackOnEntry(int amount) {
    if (amount > 1000) return '哇！這筆花得不少耶，要注意預算喔～';
    if (amount > 500) return '記下來了！中等花費，繼續保持記錄的好習慣 👍';
    if (amount > 0) return '很好！小額消費也不放過，你很棒！';
    return '收入進帳了，繼續加油！💰';
  }

  PetModel copyWith({
    String? id,
    String? name,
    PetSpecies? species,
    int? exp,
    int? streak,
    PetMood? mood,
    DateTime? lastFedAt,
    DateTime? createdAt,
    int? totalEntries,
    int? level,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      exp: exp ?? this.exp,
      streak: streak ?? this.streak,
      mood: mood ?? this.mood,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      createdAt: createdAt ?? this.createdAt,
      totalEntries: totalEntries ?? this.totalEntries,
      level: level ?? this.level,
    );
  }

  /// JSON 序列化（給 SharedPreferences / Supabase）
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species.name,
    'exp': exp,
    'streak': streak,
    'mood': mood.name,
    'lastFedAt': lastFedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'totalEntries': totalEntries,
    'level': level,
  };

  factory PetModel.fromJson(Map<String, dynamic> json) => PetModel(
    id: json['id'] as String,
    name: json['name'] as String,
    species: PetSpecies.values.firstWhere(
      (e) => e.name == json['species'],
      orElse: () => PetSpecies.moneycat,
    ),
    exp: json['exp'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    mood: PetMood.values.firstWhere(
      (e) => e.name == json['mood'],
      orElse: () => PetMood.neutral,
    ),
    lastFedAt:
        json['lastFedAt'] != null
            ? DateTime.tryParse(json['lastFedAt'] as String)
            : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    totalEntries: json['totalEntries'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
  );

  /// 建立新寵物
  factory PetModel.create({String name = '小財'}) => PetModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    createdAt: DateTime.now(),
  );
}

// === 對話庫 ===

const _happyDialogues = [
  '今天記錄很勤勞！我好開心～',
  '連續記錄 {streak} 天了，你是最棒的主人！',
  '省錢達標！離下次進化又近了一步 ✨',
  '每一筆帳都讓我更強壯～繼續加油！',
  '你的財務管理越來越好了呢！',
];

const _neutralDialogues = [
  '嗨～今天過得怎麼樣？記得寫日記喔！',
  '我在這裡等你寫日記呢～',
  '有什麼花費嗎？說給我聽吧！',
  '今天也要好好管理財務喔～',
];

const _hungryDialogues = [
  '好餓啊⋯⋯你是不是忘了寫日記？',
  '主人～我需要你的日記來補充能量！',
  '一天沒寫日記了，別讓我餓著呀⋯⋯',
];

const _sleepyDialogues = [
  '好睏⋯⋯兩天沒寫日記了，我要睡著了⋯⋯',
  'Zzz⋯⋯寫篇日記叫醒我吧⋯⋯',
  '主人去哪了⋯⋯好久沒看到你了⋯⋯😴',
];
