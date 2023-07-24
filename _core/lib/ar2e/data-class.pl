#################### データ ####################
use strict;
use utf8;

package data;

### クラスデータ --------------------------------------------------
our %class = (
  'ウォーリア' => {
    sort => '001',
    type => 'main',
    stt => {
      Str => 1, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 0,
      Luk => 0,
      Hp => 13, Mp => 10,
      HpGrow => 7, MpGrow => 4,
    },
    skill => {
      name => 'バッシュ',
      timing => 'メジャー',
      roll => '命中判定',
      target => '単体',
      range => '武器',
      cost => '4',
      max => '5',
      note => '武器攻撃。ダメージ+[(SL)D]',
    }
  },
  'アコライト' => {
    sort => '002',
    type => 'main',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 11, Mp => 12,
      HpGrow => 5, MpGrow => 6,
    },
  },
  'メイジ' => {
    sort => '003',
    type => 'main',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 1, Mnd => 1,
      Luk => 0,
      Hp => 10, Mp => 13,
      HpGrow => 4, MpGrow => 7,
    },
  },
  'シーフ' => {
    sort => '004',
    type => 'main',
    stt => {
      Str => 0, Dex => 1, Agi => 1,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 12, Mp => 11,
      HpGrow => 6, MpGrow => 5,
    },
  },
  'アルケミスト' => {
    sort => '101',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 10, Mp => 13,
    },
  },
  'イリュージョニスト' => {
    sort => '102',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 1,
      Hp => 10, Mp => 13,
    },
  },
  'ガンスリンガー' => {
    sort => '103',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 0, Sen => 1, Mnd => 1,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
  'サムライ' => {
    sort => '104',
    stt => {
      Str => 1,Dex => 1,Agi => 0,
      Int => 0,Sen => 0,Mnd => 1,
      Luk => 0,
      Hp => 12,Mp => 11,
    },
  },
  'サモナー' => {
    sort => '105',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 1,
      Hp =>  8, Mp => 15,
    },
  },
  'セージ' => {
    sort => '106',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 1,
      Hp => 9, Mp => 14,
    },
  },
  'ダンサー' => {
    sort => '107',
    stt => {
      Str => 0,Dex => 0, Agi => 1,
      Int => 0,Sen => 0, Mnd => 1,
      Luk => 1,
      Hp => 11, Mp => 12,
    },
  },
  'ニンジャ' => {
    sort => '108',
    stt => {
      Str => 0, Dex => 1, Agi => 1,
      Int => 1, Sen => 0, Mnd => 0,
      Luk => 0,
      Hp => 10, Mp => 13,
    },
  },
  'バーサーカー' => {
    sort => '109',
    stt => {
      Str => 1, Dex => 1, Agi => 0,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 13, Mp => 10,
    },
  },
  'バード' => {
    sort => '110',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 0, Sen => 1, Mnd => 1,
      Luk => 1,
      Hp => 10, Mp => 13,
    },
  },
  'モンク' => {
    sort => '111',
    stt => {
      Str => 1, Dex => 0, Agi => 1,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
  'レンジャー' => {
    sort => '112',
    stt => {
      Str => 1, Dex => 1, Agi => 0,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
  'ブラックスミス' => {
    sort => '201',
    stt => {
      Str => 1, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 0,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
  'エクセレント' => {
    sort => '202',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 1,
      Hp => 12, Mp => 11,
    },
  },
  'サイバーオーガン' => {
    sort => '203',
    stt => {
      Str => 1, Dex => 0, Agi => 1,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 14, Mp => 9,
    },
  },
  'ハッカー' => {
    sort => '204',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 1,
      Hp => 9, Mp => 14,
    },
  },
  'グラディエーター' => {
    sort => '301',
    area => 'エリンディル大陸西方',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 1,
      Hp => 13, Mp => 10,
    },
  },
  'シャーマン' => {
    sort => '302',
    area => 'エリンディル大陸西方',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 11, Mp => 12,
    },
  },
  'ドルイド' => {
    sort => '303',
    area => 'エリンディル大陸西方',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 11, Mp => 12,
    },
  },
  'バイキング' => {
    sort => '304',
    area => 'エリンディル大陸西方',
    stt => {
      Str => 0, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 0,
      Luk => 1,
      Hp => 12, Mp => 11,
    },
  },
  'ヒーラー' => {
    sort => '305',
    area => 'エリンディル大陸西方',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 9, Mp => 14,
    },
  },
  'カンナギ' => {
    sort => '401',
    area => 'エリンディル大陸東方',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 0, Sen => 1, Mnd => 1,
      Luk => 1,
      Hp => 10, Mp => 13,
    },
  },
  'チューシ' => {
    sort => '402',
    area => 'エリンディル大陸東方',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 0,
      Luk => 1,
      Hp => 11, Mp => 12,
    },
  },
  'バートル' => {
    sort => '403',
    area => 'エリンディル大陸東方',
    stt => {
      Str => 0, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 13, Mp => 10,
    },
  },
  'ファランクス' => {
    sort => '501',
    area => 'アルディオン大陸東方',
    stt => {
      Str => 1, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 0,
      Luk => 0,
      Hp => 13, Mp => 10,
    },
  },
  'フォーキャスター' => {
    sort => '502',
    area => 'アルディオン大陸東方',
    stt => {
      Str => 0, Dex => 0, Agi => 1,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 10, Mp => 13,
    },
  },
  'プリーチャー' => {
    sort => '503',
    area => 'アルディオン大陸東方',
    stt => {
      Str => 1, Dex => 0, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
  'サロゲート' => {
    sort => '601',
    area => 'アースラン',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 1,
      Hp => 12, Mp => 11,
    },
  },
  'ルイネーター' => {
    sort => '602',
    area => 'アースラン',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 11, Mp => 12,
    },
  },
  'ガーデナー' => {
    sort => '701',
    area => 'マジェラニカ大陸',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 0,
      Luk => 1,
      Hp => 10, Mp => 13,
    },
  },
  'ハンター' => {
    sort => '702',
    area => 'マジェラニカ大陸',
    stt => {
      Str => 1, Dex => 1, Agi => 0,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 13, Mp => 10,
    },
  },
  'ウォーロード' => {
    sort => '801',
    type => 'adv',
    base => 'ウォーリア',
    stt => {
      Str => 2, Dex => 2, Agi => 1,
      Int => 0, Sen => 0, Mnd => 0,
      Luk => 0,
      HpGrow => 9, MpGrow => 6,
    },
  },
  'ナイト' => {
    sort => '802',
    type => 'adv',
    base => 'ウォーリア',
    stt => {
      Str => 2, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 1,
      Luk => 0,
      HpGrow => 10, MpGrow => 5,
    },
  },
  'パラディン' => {
    sort => '803',
    type => 'adv',
    base => 'アコライト',
    stt => {
      Str => 1, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 2,
      Luk => 0,
      HpGrow => 8, MpGrow => 7,
    },
  },
  'プリースト' => {
    sort => '804',
    type => 'adv',
    base => 'アコライト',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 2,
      Luk => 1,
      HpGrow => 7, MpGrow => 8,
    },
  },
  'ウィザード' => {
    sort => '805',
    type => 'adv',
    base => 'メイジ',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 2, Sen => 2, Mnd => 1,
      Luk => 0,
      HpGrow => 6, MpGrow => 9,
    },
  },
  'ソーサラー' => {
    sort => '806',
    type => 'adv',
    base => 'メイジ',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 2, Sen => 1, Mnd => 2,
      Luk => 0,
      HpGrow => 5, MpGrow => 10,
    },
  },
  'エクスプローラー' => {
    sort => '807',
    type => 'adv',
    base => 'シーフ',
    stt => {
      Str => 0, Dex => 1, Agi => 2,
      Int => 0, Sen => 2, Mnd => 0,
      Luk => 0,
      HpGrow => 8, MpGrow => 7,
    },
  },
  'スカウト' => {
    sort => '808',
    type => 'adv',
    base => 'シーフ',
    stt => {
      Str => 0, Dex => 2, Agi => 0,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 2,
      HpGrow => 7, MpGrow => 8,
    },
  },
  'ドレッドノート' => {
    sort => '901',
    type => 'fate',
    base => 'ウォーリア',
    adv  => 'ウォーロード',
    stt => {
      HpGrow => 9, MpGrow => 6,
    },
  },
  'バナレット' => {
    sort => '902',
    type => 'fate',
    base => 'ウォーリア',
    adv  => 'ナイト',
    stt => {
      HpGrow => 10, MpGrow => 5,
    },
  },
  'クルセイダー' => {
    sort => '903',
    type => 'fate',
    adv  => 'パラディン',
    base => 'アコライト',
    stt => {
      HpGrow => 8, MpGrow => 7,
    },
  },
  'ビショップ' => {
    sort => '904',
    type => 'fate',
    adv  => 'プリースト',
    base => 'アコライト',
    stt => {
      HpGrow => 7, MpGrow => 8,
    },
  },
  'エレメンタリスト' => {
    sort => '905',
    type => 'fate',
    base => 'メイジ',
    adv  => 'ウィザード',
    stt => {
      HpGrow => 6, MpGrow => 9,
    },
  },
  'メイガス' => {
    sort => '906',
    type => 'fate',
    base => 'メイジ',
    adv  => 'ソーサラー',
    stt => {
      HpGrow => 5, MpGrow => 10,
    },
  },
  'ランペイジ' => {
    sort => '907',
    type => 'fate',
    base => 'シーフ',
    adv  => 'エクスプローラー',
    stt => {
      HpGrow => 8, MpGrow => 7,
    },
  },
  'デッドアイ' => {
    sort => '908',
    type => 'fate',
    base => 'シーフ',
    adv  => 'スカウト',
    stt => {
      HpGrow => 7, MpGrow => 8,
    },
  },

  'ミリタント' => {
    sort => 'a01',
    type => 'legacy',
    limited => 'ウォーリア',
    stt => {
      Str => 1, Dex => 1, Agi => 1,
      Int => 0, Sen => 0, Mnd => 0,
      Luk => 0,
      Hp => 13, Mp => 10,
    },
  },
  'コントラクター' => {
    sort => 'a02',
    type => 'legacy',
    limited => 'アコライト',
    stt => {
      Str => 0, Dex => 1, Agi => 0,
      Int => 1, Sen => 0, Mnd => 1,
      Luk => 0,
      Hp => 11, Mp => 12,
    },
  },
  'ウォーロック' => {
    sort => 'a03',
    type => 'legacy',
    limited => 'メイジ',
    stt => {
      Str => 0, Dex => 0, Agi => 0,
      Int => 1, Sen => 1, Mnd => 1,
      Luk => 0,
      Hp => 10, Mp => 13,
    },
  },
  'フォーチュネイト' => {
    sort => 'a04',
    type => 'legacy',
    limited => 'シーフ',
    stt => {
      Str => 0, Dex => 1, Agi => 1,
      Int => 0, Sen => 1, Mnd => 0,
      Luk => 0,
      Hp => 12, Mp => 11,
    },
  },
);


1;