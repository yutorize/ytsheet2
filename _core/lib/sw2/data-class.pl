#################### データ ####################
use strict;
use utf8;

package data;

### 技能名一覧 --------------------------------------------------
# 基本的な並び
our @class_names = (
  'ファイター',
  'グラップラー',
  'バトルダンサー',
  'フェンサー',
  'シューター',
  'ソーサラー',
  'コンジャラー',
  'プリースト',
  'マギテック',
  'フェアリーテイマー',
  'ドルイド',
  'デーモンルーラー',
  'アビスゲイザー',
  'グリモワール',
  'スカウト',
  'レンジャー',
  'セージ',
  'エンハンサー',
  'バード',
  'ライダー',
  'アルケミスト',
  'ジオマンサー',
  'ウォーリーダー',
  'ダークハンター',
  'フィジカルマスター',
  'ミスティック',
  'アーティザン',
  'アリストクラシー',
);

### 技能初出順一覧 --------------------------------------------------
# （並べ替えるとキャラ一覧での技能表示が入れ替わるので注意）
our @class_list = (
  'ファイター',
  'グラップラー',
  'フェンサー',
  'シューター',
  'ソーサラー',
  'コンジャラー',
  'プリースト',
  'フェアリーテイマー',
  'マギテック',
  'スカウト',
  'レンジャー',
  'セージ',
  'エンハンサー',
  'バード',
  'ライダー',
  'アルケミスト',
  'ウォーリーダー',
  'ミスティック',
  'デーモンルーラー',
  'フィジカルマスター',
  'グリモワール',
  'アーティザン',
  'アリストクラシー',
  'ドルイド',
  'ジオマンサー',
  'バトルダンサー',
  'アビスゲイザー',
  'ダークハンター',
);

### 魔法技能一覧 --------------------------------------------------
our @class_caster = (
  'ソーサラー',
  'コンジャラー',
  'ウィザード',
  'プリースト',
  'マギテック',
  'フェアリーテイマー',
  'ドルイド',
  'デーモンルーラー',
  'アビスゲイザー',
  'グリモワール',
);

### 技能詳細データ --------------------------------------------------
our %class = (
  'ファイター' => {
    type     => 'weapon-user',
    expTable => 'A',
    id       => 'Fig',
    eName    => 'fighter',
  },
  'グラップラー' => {
    type     => 'weapon-user',
    expTable => 'A',
    id       => 'Gra',
    eName    => 'grappler',
  },
  'バトルダンサー' => {
    '2.5' => 1,
    type     => 'weapon-user',
    expTable => 'A',
    id       => 'Bat',
    eName    => 'battledancer',
  },
  'フェンサー' => {
    type     => 'weapon-user',
    expTable => 'B',
    id       => 'Fen',
    eName    => 'fencer',
  },
  'シューター' => {
    type     => 'weapon-user',
    expTable => 'B',
    id       => 'Sho',
    eName    => 'shooter',
    evaUnlock => { feat => '射手の体術' }
  },
  'ソーサラー' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Sor',
    eName    => 'sorcerer',
    magic => {
      jName => '真語魔法',
      eName => 'sorcery',
    },
    language => {
      '魔法文明語' => { talk => 1, read => 1 },
    },
  },
  'コンジャラー' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Con',
    eName    => 'conjurer',
    magic => {
      jName => '操霊魔法',
      eName => 'conjury',
    },
    language => {
      '魔法文明語' => { talk => 1, read => 1 },
    },
  },
  'ウィザード' => {
    type     => 'magic-user',
    expTable => '',
    id       => 'Wiz',
    eName    => 'wizard',
    magic => {
      jName => '深智魔法',
      eName => 'wizardry',
    },
  },
  'プリースト' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Pri',
    eName    => 'priest',
    magic => {
      jName => '神聖魔法',
      eName => 'holypray',
    },
  },
  'フェアリーテイマー' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Fai',
    eName    => 'fairytamer',
    magic => {
      jName => '妖精魔法',
      eName => 'fairyism',
    },
    language => {
      '妖精語' => { talk => 1 },
    },
  },
  'マギテック' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Mag',
    eName    => 'magitech',
    magic => {
      jName => '魔動機術',
      eName => 'magitech',
    },
    language => {
      '魔動機文明語' => { talk => 1, read => 1 },
    },
  },
  'スカウト' => {
    expTable => 'B',
    id       => 'Sco',
    eName    => 'scout',
    package  => {
      Tec => { name => '技巧', stt => 'A' },
      Agi => { name => '運動', stt => 'B', initiative => 1 },
      Obs => { name => '観察', stt => 'E' },
    },
  },
  'レンジャー' => {
    expTable => 'B',
    id       => 'Ran',
    eName    => 'ranger',
    package  => {
      Tec => { name => '技巧', stt => 'A' },
      Agi => { name => '運動', stt => 'B' },
      Obs => { name => '観察', stt => 'E' },
    },
  },
  'セージ' => {
    expTable => 'B',
    id       => 'Sag',
    eName    => 'sage',
    language => {
      any => { talk => 1, read => 1 },
    },
    package  => {
      Kno => { name => '知識', stt => 'E', monsterLore => 1 },
    },
  },
  'エンハンサー' => {
    expTable => 'B',
    id       => 'Enh',
    eName    => 'enhancer',
    accUnlock => { lv => 10, craft => 'バルーンシードショット|フェンリルバイト' },
    craft => {
      jName => '練技',
      eName => 'enhance',
      data => [
        [1,'アンチボディ','[補][準]'],
        [1,'オウルビジョン','[補]'],
        [1,'ガゼルフット','[補][準]'],
        [1,'キャッツアイ','[補]'],
        [1,'スケイルレギンス','[補]'],
        [1,'ストロングブラッド','[補][準]'],
        [1,'チックチック','[補]'],
        [1,'ドラゴンテイル','[補]'],
        [1,'ビートルスキン','[補][準]'],
        [1,'マッスルベアー','[補]'],
        [1,'メディテーション','[補][準]'],
        [1,'ラビットイヤー','[補]'],
        [5,'ケンタウロスレッグ','[補][準]'],
        [5,'シェイプアニマル','[補]'],
        [5,'ジャイアントアーム','[補]'],
        [5,'スフィンクスノレッジ','[補][準]'],
        [5,'デーモンフィンガー','[補]'],
        [5,'ファイアブレス','[補]'],
        [5,'リカバリィ','[補]'],
        [5,'ワイドウィング','[補]'],
        [10,'カメレオンカムフラージュ','[補][準]'],
        [10,'クラーケンスタビリティ','[補][準]'],
        [10,'ジィプロフェシー','[補][準]'],
        [10,'ストライダーウォーク','[補]'],
        [10,'スパイダーウェブ','[補]'],
        [10,'タイタンフット','[補]'],
        [10,'トロールバイタル','[補][準]'],
        [10,'バルーンシードショット','[補]'],
        [10,'フェンリルバイト','[補]'],
        [10,'ヘルシーボディ','[補]'],
        [16,'アナライズブレイン','2.0[補]'],
        [16,'ウェンディゴハイド','2.0[補]'],
        [16,'ヴジャトーアイ','2.0[補]'],
      ],
    },
  },
  'バード' => {
    expTable => 'B',
    id       => 'Bar',
    eName    => 'bard',
    language => {
      any => { talk => 1 },
    },
    package  => {
      Kno => { name => '見識', stt => 'E' },
    },
    craft => {
      jName => '呪歌',
      eName => 'song',
      stt => '精神力',
      power => '奏力',
      data => [
        [1,'アーリーバード',''],
        [1,'アンビエント',''],
        [1,'サモン・スモールアニマル',''],
        [1,'サモン・フィッシュ',''],
        [1,'ノイズ',''],
        [1,'バラード',''],
        [1,'モラル',''],
        [1,'レクイエム',''],
        [1,'レジスタンス',''],
        [5,'アトリビュート',''],
        [5,'キュアリオスティ',''],
        [5,'チャーミング',''],
        [5,'トランス',''],
        [5,'ノスタルジィ',''],
        [5,'ブレイク',''],
        [5,'ラブソング',''],
        [5,'ララバイ',''],
        [10,'クラップ',''],
        [10,'コーラス',''],
        [10,'ダル',''],
        [10,'ダンス',''],
        [10,'フォール',''],
        [10,'リダクション',''],
        [10,'レイジィ',''],
        [1,'終律：春の強風',''],
        [1,'終律：夏の生命',''],
        [1,'終律：秋の実り',''],
        [1,'終律：冬の寒風',''],
        [5,'終律：獣の咆吼',''],
        [5,'終律：草原の息吹',''],
        [5,'終律：華の宴',''],
        [5,'終律：蛇穴の苦鳴',''],
        [10,'終律：火竜の舞',''],
        [10,'終律：水竜の轟',''],
        [10,'終律：蒼月の光',''],
        [10,'終律：白日の暖',''],
        [16,'グラント','2.0'],
        [16,'ヒム','2.0'],
        [16,'リラックス','2.0'],
      ],
    },
  },
  'ライダー' => {
    expTable => 'B',
    id       => 'Rid',
    eName    => 'rider',
    package  => {
      Agi => { name => '運動', stt => 'B' },
      Obs => { name => '観察', stt => 'E', unlockCraft => '探索指令' },
      Kno => { name => '知識', stt => 'E', monsterLore => 1 },
    },
    craft => {
      jName => '騎芸',
      eName => 'riding',
      data => [
        [1,'威嚇','[補]'],
        [1,'以心伝心','[常]'],
        [1,'遠隔指示','[常]'],
        [1,'探索指令','[常]'],
        [1,'騎獣強化','[常]'],
        [1,'騎獣の献身','[常]'],
        [1,'攻撃阻害','[常]'],
        [1,'高所攻撃','[常]'],
        [1,'タンデム','[常]'],
        [1,'チャージ','[主]'],
        [1,'魔法指示','[主]'],
        [1,'ＨＰ強化','[常]'],
        [5,'限界駆動','[補]'],
        [5,'獅子奮迅','[常]'],
        [5,'姿勢堅持','[補]'],
        [5,'人馬一体','[常]'],
        [5,'超高所攻撃','[常]'],
        [5,'特殊能力解放','[常]'],
        [5,'トランプル','[主]'],
        [5,'魔法指示回数増加','[常]'],
        [5,'ＨＰ超強化','[常]'],
        [10,'騎獣超強化','[常]'],
        [10,'騎乗指揮','[主]'],
        [10,'極高所攻撃','[常]'],
        [10,'瞬時魔法指示','[常]'],
        [10,'スーパーチャージ','[常]'],
        [10,'超過駆動','[補]'],
        [10,'超攻撃阻害','[常]'],
        [10,'特殊能力完全解放','[常]'],
        [10,'八面六臂','[主]'],
        [10,'バランス','[常]'],
        [16,'潜在覚醒','2.0'],
        [16,'超越騎獣','2.0'],
        [16,'超人馬一体','2.0'],
        [16,'瞬発力','ケンタウロス専用'],
        [16,'零距離突撃','ケンタウロス専用'],
        [16,'スーパートランプル','ケンタウロス専用'],
      ],
    },
  },
  'アルケミスト' => {
    expTable => 'B',
    id       => 'Alc',
    eName    => 'alchemist',
    language => {
      '魔動機文明語' => { talk => 1, read => 1 },
    },
    package  => {
      Kno => { name => '知識', stt => 'E' },
    },
    craft => {
      jName => '賦術',
      eName => 'alchemy',
      stt => '知力',
      data => [
        [1,'インスタントウェポン','[白][補]'],
        [1,'ヴォーパルウェポン','[赤][補]'],
        [1,'クラッシュファング','[赤][補][準]'],
        [1,'クリティカルレイ','[金][補]'],
        [1,'バークメイル','[緑][補][準]'],
        [1,'パラライズミスト','[緑][補]'],
        [1,'ポイズンニードル','[黒][補]'],
        [1,'ミラージュデイズ','[白][補][準]'],
        [1,'ヒールスプレー','[緑][補]'],
        [5,'アーマーラスト','[黒][補]'],
        [5,'アンロックニードル','[黒][補]'],
        [5,'イニシアティブブースト','[赤][準]'],
        [5,'エンサイクロペディア','[白][補][準]'],
        [5,'ディスペルニードル','[黒][補]'],
        [5,'バインドアビリティ','[白][補][準]'],
        [5,'ビビッドリキッド','[緑][補]'],
        [5,'マナスプラウト','[金][補][準]'],
        [5,'マナダウン','[金][補][準]'],
        [5,'リーンフォース','[赤][補]'],
        [10,'クレイフィールド','[黒]'],
        [10,'コンバインマテリアル','[白][黒]'],
        [10,'スラッシュフィールド','[白]'],
        [10,'デラックスマテリアル','[赤][緑]'],
        [10,'バリアフィールド','[金]'],
        [10,'フレイムフィールド','[赤]'],
        [10,'レストフィールド','[緑]'],
        [16,'プリズムカーテン','2.0'],
        [16,'ライフステイシス','2.0'],
        [16,'マテリアルブレイク','2.0'],
      ],
    },
  },
  'ドルイド' => {
    '2.5' => 1,
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Dru',
    eName    => 'druid',
    magic => {
      jName => '森羅魔法',
      eName => 'druidry',
    },
  },
  'デーモンルーラー' => {
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Dem',
    eName    => 'demonruler',
    accUnlock => { lv => 11, dmg => 'power' },
    evaUnlock => { lv =>  2 },
    magic => {
      jName => '召異魔法',
      eName => 'demonology',
    },
    language => {
      '魔神語' => { talk => 1 },
      '魔法文明語' => { read => 1 },
    },
  },
  'ジオマンサー' => {
    '2.5' => 1,
    expTable => 'B',
    id       => 'Geo',
    eName    => 'geomancer',
    package  => {
      Obs => { name => '観察', stt => 'E' },
    },
    craft => {
      jName => '相域',
      eName => 'geomancy',
      data => [
        [ 1,'天相：降雷',''],
        [ 1,'天相：空を欺く',''],
        [ 1,'天相：見えない傘',''],
        [ 1,'地相：地脈の吸収',''],
        [ 1,'地相：地を泳ぐ',''],
        [ 1,'地相：泥濘に沈む',''],
        [ 1,'人相：活',''],
        [ 1,'人相：恐慌',''],
        [ 1,'人相：反撃の意思',''],
        [ 5,'天相：因果',''],
        [ 5,'天相：天魔の一撃',''],
        [ 5,'天相：導きの矢',''],
        [ 5,'地相：宿命の戦士',''],
        [ 5,'地相：属性の乖離',''],
        [ 5,'地相：巻き上がる砂塵の鎧',''],
        [ 5,'人相：魂の別離',''],
        [ 5,'人相：漏れ出るマナ',''],
        [ 5,'人相：夢喰い',''],
        [10,'天相：七星流れ',''],
        [10,'天相：マナの離別',''],
        [10,'天相：烙印',''],
        [10,'地相：足掻き',''],
        [10,'地相：大いなる蛇の目',''],
        [10,'地相：蜃気楼',''],
        [10,'人相：残像',''],
        [10,'人相：存在の消失',''],
        [10,'人相：人写し',''],
      ],
    },
  },
  'ウォーリーダー' => {
    expTable => 'B',
    id       => 'War',
    eName    => 'warleader',
    package  => {
      Agi => { name => '先制', stt => 'B', initiative => 1 },
      Int => { name => '先制(知)', stt => 'E', initiative => 1, unlockCraft => '陣率：軍師の知略' },
    },
    craft => {
      jName => '鼓咆／陣率',
      eName => 'command',
      data => [
        [ 1,'瑕疵への追撃','[補]'],
        [ 1,'神展の構え','[補]'],
        [ 5,'勇壮なる軍歌','[補]'],
        [ 5,'蘇る秘奥','[補]'],
        [10,'大いなる挑発','[補]'],
        [10,'傷痍の見立て','[補]'],
        [ 1,'怒涛の攻陣Ⅰ','[補]'],
        [ 1,'怒涛の攻陣Ⅱ：烈火','[補]'],
        [ 1,'怒涛の攻陣Ⅱ：旋風','[補]'],
        [ 5,'怒涛の攻陣Ⅲ：轟炎','[補]'],
        [ 5,'怒涛の攻陣Ⅲ：旋刃','[補]'],
        [ 5,'怒涛の攻陣Ⅳ：爆焔','[補]'],
        [ 5,'怒涛の攻陣Ⅳ：輝斬','[補]'],
        [10,'怒涛の攻陣Ⅴ：獄火','[補]'],
        [10,'怒涛の攻陣Ⅴ：颱風','[補]'],
        [ 1,'流麗なる俊陣Ⅰ','[補]'],
        [ 1,'流麗なる俊陣Ⅱ','[補]'],
        [ 5,'流麗なる俊陣Ⅲ','[補]'],
        [ 5,'流麗なる俊陣Ⅳ','[補]'],
        [10,'流麗なる俊陣Ⅴ','[補]'],
        [ 1,'鉄壁の防陣Ⅰ','[補]'],
        [ 1,'鉄壁の防陣Ⅱ：鉄鎧','[補]'],
        [ 1,'鉄壁の防陣Ⅱ：堅体','[補]'],
        [ 5,'鉄壁の防陣Ⅲ：鋼鎧','[補]'],
        [ 5,'鉄壁の防陣Ⅲ：甲盾','[補]'],
        [ 5,'鉄壁の防陣Ⅳ：城鎧','[補]'],
        [ 5,'鉄壁の防陣Ⅳ：鏡盾','[補]'],
        [10,'鉄壁の防陣Ⅴ：鋼城','[補]'],
        [10,'鉄壁の防陣Ⅴ：巨壁','[補]'],
        [ 1,'強靭なる丈陣Ⅰ','[補]'],
        [ 1,'強靭なる丈陣Ⅱ','[補]'],
        [ 5,'強靭なる丈陣Ⅲ','[補]'],
        [ 5,'強靭なる丈陣Ⅳ','[補]'],
        [10,'強靭なる丈陣Ⅴ：激生','[補]'],
        [10,'強靭なる丈陣Ⅴ：魔泉','[補]'],

        [ 1,'陣率：軍師の知略','[準]'],
        [ 1,'陣率：慮外なる烈撃Ⅰ','[補]'],
        [ 5,'陣率：慮外なる烈撃Ⅱ','[補]'],
        [ 1,'陣率：挙措の予見Ⅰ','[補]'],
        [ 5,'陣率：挙措の予見Ⅱ','[補]'],
        [ 1,'陣率：衝戟の刪削Ⅰ','[補]'],
        [ 5,'陣率：衝戟の刪削Ⅱ','[補]'],
        [ 1,'陣率：抗拒の推断Ⅰ','[補]'],
        [ 5,'陣率：抗拒の推断Ⅱ','[補]'],
        [ 1,'陣率：行使専心Ⅰ','[補]'],
        [ 5,'陣率：行使専心Ⅱ','[補]'],
        [ 1,'陣率：効力亢進Ⅰ','[補]'],
        [ 5,'陣率：効力亢進Ⅱ','[補]'],
        [ 5,'陣率：掃討の勝鬨',''],
        [ 5,'陣率：堅固なる布陣',''],

        [1,'神速の構え','2.0'],
        [1,'堅陣の構え','2.0'],
        [1,'流麗なる俊陣Ⅱ：陽炎','2.0'],
        [1,'流麗なる俊陣Ⅱ：流水','2.0'],
        [1,'強靭なる丈陣Ⅰ：抵体','2.0'],
        [1,'強靭なる丈陣Ⅰ：抗心','2.0'],
        [1,'強靭なる丈陣Ⅱ：強身','2.0'],
        [1,'強靭なる丈陣Ⅱ：精定','2.0'],
        [1,'強靭なる丈陣Ⅱ：安精','2.0'],
        [1,'軍師の知略','2.0'],
        [5,'流麗なる俊陣Ⅲ：浮身','2.0'],
        [5,'流麗なる俊陣Ⅲ：幻惑','2.0'],
        [5,'流麗なる俊陣Ⅳ：残影','2.0'],
        [5,'流麗なる俊陣Ⅳ：瞬脱','2.0'],
        [5,'鉄壁の防陣Ⅳ：反攻','2.0'],
        [5,'鉄壁の防陣Ⅳ：無敵','2.0'],
        [5,'強靭なる丈陣Ⅲ：剛体','2.0'],
        [5,'強靭なる丈陣Ⅲ：整身','2.0'],
        [5,'強靭なる丈陣Ⅲ：心清','2.0'],
        [5,'強靭なる丈陣Ⅳ：克己','2.0'],
        [5,'強靭なる丈陣Ⅳ：賦活','2.0'],
        [5,'強靭なる丈陣Ⅳ：清涼','2.0'],
        [10,'流麗なる俊陣Ⅴ：水鏡','2.0'],
        [10,'流麗なる俊陣Ⅴ：影駆','2.0'],
        [10,'鉄壁の防陣Ⅴ：槍塞','2.0'],

      ],
    },
  },
  'アビスゲイザー' => {
    '2.5' => 1,
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Aby',
    eName    => 'abyssgazer',
    magic => {
      jName => '奈落魔法',
      eName => 'abyssalpray',
    },
    language => {
      '魔神語' => { talk => 1 },
    },
  },
  'ダークハンター' => {
    expTable => 'B',
    id       => 'Dar',
    eName    => 'darkhunter',
    accUnlock => { lv => 1, craft => '気操法', reqd => 'Mnd', acc => 'power', dmg => 'power' },
    package  => {
      Int => { name => '知識', stt => 'E', monsterLore => 1 },
    },
    craft => {
      jName => '操気',
      eName => 'psychokinesis',
      stt => '精神力',
      power => '理力',
      data => [
        [1,'気集中','[補]'],
        [1,'気操法','[主]'],
        [1,'気防陣','[補][準]'],
        [1,'剛力弾','[常]'],
        [1,'属性付・轟','[補]'],
        [1,'属性付・裂','[補]'],
        [1,'大乱獲','[常]'],
        [1,'念糸還','[補]'],
        [1,'念縛術Ⅰ','[補]'],
        [1,'魔観察','[常]'],
        [1,'魔探法','[補][準]'],
        [5,'遠操法','[常]'],
        [5,'皆操法','[常]'],
        [5,'気旋法','[補]'],
        [5,'双操法','[補]'],
        [5,'操浮術','[補][準]'],
        [5,'念糸手Ⅰ','[主]'],
        [5,'念縛術Ⅱ','[補][準]'],
        [5,'念避印','[補]'],
        [5,'破邪健身','[補][準]'],
        [5,'破邪光弾','[主]'],
        [5,'魔生法','[常]'],
        [10,'重操法','[常]'],
        [10,'念糸手Ⅱ','[主]'],
        [10,'念縛術Ⅲ','[補][準]'],
        [10,'縛術強化','[補][準]'],
        [10,'破邪光槍','[主]'],
        [10,'魔遊法','[常]'],
      ],
    },
  },
  'ミスティック' => {
    '2.0' => 1,
    expTable => 'B',
    id       => 'Mys',
    eName    => 'mystic',
    craft => {
      jName => '占瞳',
      eName => 'divination',
      stt => '知力',
      data => [
        [1,'幸運の星の導きを知る',''],
        [1,'幸運は手指を助ける',''],
        [1,'幸運は動きを助ける',''],
        [1,'幸運は力を助ける',''],
        [1,'幸運は知恵を助ける',''],
        [1,'幸運は勝ち戦を授ける',''],
        [1,'幸運は富をもたらす',''],
        [1,'星は剣を導く',''],
        [1,'星は盾を掲げる',''],
        [1,'星は札を翻す',''],
        [1,'星は調べを誘う',''],
        [1,'星は安らぎをもたらす',''],
        [5,'凶星の光を避ける道を知る',''],
        [5,'賢星に語らるべかりし言葉を問う',''],
        [5,'光る星は弱点を暴く',''],
        [5,'光る星は神秘を誘う',''],
        [5,'怒れる言葉の幻',''],
        [5,'崩れる壁の幻',''],
        [5,'背後から迫る闇の幻',''],
        [5,'襲いかかる敵の幻',''],
        [10,'光り輝く星は高みへと導く',''],
        [10,'黒き死の幻影',''],
        [10,'灰色なる敗北の幻影',''],
        [10,'無色なる不備の幻影',''],
        [16,'天の星々は未来の絶望を識る',''],
        [16,'黄昏に万物の源を枯らす幻夢',''],
        [16,'新月に砕ける刀の幻夢',''],
      ],
    },
  },
  'フィジカルマスター' => {
    expTable => 'B',
    id       => 'Phy',
    eName    => 'physicalmaster',
    package  => {
      Agi => { name => '先制'    , stt => 'B', initiative => 1 ,unlockCraft => '魔将の慧眼' },
      Int => { name => '魔物知識', stt => 'E', monsterLore => 1,unlockCraft => '魔将の経験' },
    },
    accUnlock => { lv => 1 },
    evaUnlock => { lv => 1 },
    craft => {
      jName => '魔装',
      eName => 'potential',
      data => [
        [1,'アイテム収納',''],
        [1,'コア耐久増強',''],
        [1,'生来武器強化A',''],
        [1,'部位即応＆強化',''],
        [1,'部位属性付与',''],
        [1,'部位耐久増強',''],
        [1,'魔将の慧眼',''],
        [1,'宣言特技使用','ディアボロ専用'],
        [1,'戦士系技能使用','ディアボロ専用'],
        [1,'呪傷の連鎖','ディアボロ専用'],
        [1,'魔人の眼光','ディアボロ専用'],
        [1,'魔人能力拡大／達成値','ディアボロ専用'],
        [1,'ブレス強化','ドレイク専用'],
        [1,'魔剣形状変更','ドレイク専用'],
        [1,'魔剣ランク上昇A','ドレイク専用'],
        [1,'暗視','バジリスク専用'],
        [1,'邪視MP半減／石化','バジリスク専用'],
        [1,'邪視MP半減／貫き','バジリスク専用'],
        [1,'邪視MP半減／破錠','バジリスク専用'],
        [1,'邪視MP半減／賦活','バジリスク専用'],
        [1,'邪視MP半減／高揚','バジリスク専用'],
        [1,'邪視MP半減／消散','バジリスク専用'],
        [1,'邪視MP半減／回生','バジリスク専用'],
        [1,'邪視MP半減／全天','バジリスク専用'],
        [1,'邪視MP半減／操位','バジリスク専用'],
        [1,'邪視MP半減／潜魂','バジリスク専用'],
        [1,'邪視MP半減／停滞','バジリスク専用'],
        [1,'邪視MP半減／その他','バジリスク専用'],
        [1,'邪視強化A／石化','バジリスク専用'],
        [1,'邪視強化A／貫き','バジリスク専用'],
        [1,'邪視強化A／破錠','バジリスク専用'],
        [1,'邪視強化A／賦活','バジリスク専用'],
        [1,'邪視強化A／高揚','バジリスク専用'],
        [1,'邪視強化A／消散','バジリスク専用'],
        [1,'邪視強化A／回生','バジリスク専用'],
        [1,'邪視強化A／全天','バジリスク専用'],
        [1,'邪視強化A／操位','バジリスク専用'],
        [1,'邪視強化A／潜魂','バジリスク専用'],
        [1,'邪視強化A／停滞','バジリスク専用'],
        [1,'邪視強化A／その他','バジリスク専用'],
        [1,'邪視達成値強化','バジリスク専用'],
        [1,'機動射撃','シザースコーピオン専用'],
        [1,'減衰の毒液','シザースコーピオン専用'],
        [5,'コア耐久超増強',''],
        [5,'渾身攻撃',''],
        [5,'生来武器強化S',''],
        [5,'部位耐久超増強',''],
        [5,'部位超強化',''],
        [5,'魔将の経験',''],
        [5,'練技使用',''],
        [5,'侵蝕の毒息','ディアボロ専用'],
        [5,'胴体効果継続Ⅰ','ディアボロ専用'],
        [5,'魔人の咆哮','ディアボロ専用'],
        [5,'魔剣+1','ドレイク専用'],
        [5,'魔剣吸収','ドレイク専用'],
        [5,'魔剣ランク上昇S','ドレイク専用'],
        [5,'巨大な身体','バジリスク専用'],
        [5,'邪視MP無償化／石化','バジリスク専用'],
        [5,'邪視MP無償化／貫き','バジリスク専用'],
        [5,'邪視MP無償化／破錠','バジリスク専用'],
        [5,'邪視MP無償化／賦活','バジリスク専用'],
        [5,'邪視MP無償化／高揚','バジリスク専用'],
        [5,'邪視MP無償化／消散','バジリスク専用'],
        [5,'邪視MP無償化／回生','バジリスク専用'],
        [5,'邪視MP無償化／全天','バジリスク専用'],
        [5,'邪視MP無償化／操位','バジリスク専用'],
        [5,'邪視MP無償化／潜魂','バジリスク専用'],
        [5,'邪視MP無償化／停滞','バジリスク専用'],
        [5,'邪視MP無償化／その他','バジリスク専用'],
        [5,'邪視強化S／石化','バジリスク専用'],
        [5,'邪視強化S／貫き','バジリスク専用'],
        [5,'邪視強化S／破錠','バジリスク専用'],
        [5,'邪視強化S／賦活','バジリスク専用'],
        [5,'邪視強化S／高揚','バジリスク専用'],
        [5,'邪視強化S／消散','バジリスク専用'],
        [5,'邪視強化S／回生','バジリスク専用'],
        [5,'邪視強化S／全天','バジリスク専用'],
        [5,'邪視強化S／操位','バジリスク専用'],
        [5,'邪視強化S／潜魂','バジリスク専用'],
        [5,'邪視強化S／停滞','バジリスク専用'],
        [5,'邪視強化S／その他','バジリスク専用'],
        [5,'邪視変異Ⅰ','バジリスク専用'],
        [5,'交差攻撃','シザースコーピオン専用'],
        [5,'毒効果拡大','シザースコーピオン専用'],
        [10,'コア耐久極増強',''],
        [10,'生来武器強化SS',''],
        [10,'部位極強化',''],
        [10,'部位耐久極増強',''],
        [10,'魔将の領域',''],
        [10,'マナ解除',''],
        [10,'異界の挙動','ディアボロ専用'],
        [10,'魂の吸収','ディアボロ専用'],
        [10,'胴体効果継続Ⅱ','ディアボロ専用'],
        [10,'不平等な契約','ディアボロ専用'],
        [10,'魔人能力超拡大／達成値','ディアボロ専用'],
        [10,'燦光のブレス','ドレイク専用'],
        [10,'魔剣ランク上昇SS','ドレイク専用'],
        [10,'邪眼追加','バジリスク専用'],
        [10,'邪視貫通制御','バジリスク専用'],
        [10,'邪視強化SS／石化','バジリスク専用'],
        [10,'邪視強化SS／貫き','バジリスク専用'],
        [10,'邪視強化SS／破錠','バジリスク専用'],
        [10,'邪視強化SS／賦活','バジリスク専用'],
        [10,'邪視強化SS／高揚','バジリスク専用'],
        [10,'邪視強化SS／消散','バジリスク専用'],
        [10,'邪視強化SS／回生','バジリスク専用'],
        [10,'邪視強化SS／全天','バジリスク専用'],
        [10,'邪視強化SS／操位','バジリスク専用'],
        [10,'邪視強化SS／潜魂','バジリスク専用'],
        [10,'邪視強化SS／停滞','バジリスク専用'],
        [10,'邪視強化SS／その他','バジリスク専用'],
        [10,'邪視変異Ⅱ','バジリスク専用'],
        [10,'魔法使用','バジリスク専用'],
        [10,'蠍の姿勢制御','シザースコーピオン専用'],
        [10,'毒効果超拡大','シザースコーピオン専用'],

        [1,'属性付与','2.0'],
        [1,'部位強化','2.0'],
        [1,'暗視付与','バジリスク専用,2.0'],
        [1,'邪視強化A／貫く','バジリスク専用,2.0'],
        [1,'邪視強化A／蘇る','バジリスク専用,2.0'],
        [1,'邪視拡大／達成値','バジリスク専用,2.0'],
        [1,'邪視拡大／戦闘特技','バジリスク専用,2.0'],
        [5,'邪視拡大／数','バジリスク専用,2.0'],
        [5,'邪視強化S／貫く','バジリスク専用,2.0'],
        [5,'邪視強化S／蘇る','バジリスク専用,2.0'],
        [10,'邪視強化SS／貫く','バジリスク専用,2.0'],
        [10,'邪視強化SS／蘇る','バジリスク専用,2.0'],
        [16,'再生／その他部位','2.0'],
        [16,'マナ耐性／その他部位','2.0'],
        [16,'灼熱のブレス','ドレイク専用,2.0'],
        [16,'魔剣+2','ドレイク専用,2.0'],
        [16,'邪眼追加Ⅱ','バジリスク専用,2.0'],
        [16,'巨大な身体Ⅱ','バジリスク専用,2.0'],
      ],
    },
  },
  'グリモワール' => {
    '2.0' => 1,
    type     => 'magic-user',
    expTable => 'A',
    id       => 'Gri',
    eName    => 'grimoir',
    language => {
      '魔法文明語' => { read => 1 },
    },
    magic => {
      jName => '秘奥魔法',
      eName => 'gramarye',
      stt => '知力',
      data => [
        [1,"悪意の針",'アクス＝マリスティアス'],
        [1,"拒絶の障壁",'ウェルム＝リイェクタス'],
        [1,"肉体修復",'コルプス＝レストラーレ'],
        [1,"猛毒の霧",'ネブラ＝ウェネーヌムス'],
        [1,"破滅の槍",'ランケア＝ルイナス'],
        [4,"退魔活性",'アクティオ＝エクソキスムス'],
        [4,"属性付加",'アディシオ＝エレメントゥム'],
        [4,"容姿端麗",'プルケリトゥード'],
        [4,"魔力増強",'マギカ＝アウゲータス'],
        [4,"貫く光条",'ルクス＝トライキエンス'],
        [7,"大気爆発",'アトモス＝イラプティオ'],
        [7,"大跳躍",'マグナ＝サルトゥス'],
        [7,"瞬間修復",'モメント＝レストラーレ'],
        [7,"断罪の槍",'ランケア＝ダムナトリウス'],
        [7,"再生起動",'レナトゥス＝イニシアトゥス'],
        [10,"高速飛行",'ケレリタス＝ウォラートゥス'],
        [10,"完全防護",'デフェンシオス＝ペルフェクタス'],
        [10,"闇を裂く閃光",'デネブラス＝カイエンデンス＝ルミナス'],
        [10,"仮想の死",'モルス＝ウィルトゥアリス'],
        [13,"空間転移",'スパティウム＝テレポータス'],
        [13,"死の嵐",'モルス＝テンペスタス'],
        [13,"神殺の槍",'ランケア＝フェリオデウス'],
        [13,"聖魔の光来",'ルクス＝サンクトゥム＝アドヴェントゥス'],
        [16,"全能の一",'オムニポテンス'],
        [16,"術式解体",'マギカ＝ディコンストゥルオ'],
        [16,"絶命の禁則",'モルティス＝ウェウェテュウム'],
        [16,"星を断つ戦士",'ステラ＝スキスラ＝ベルラトル'],
        #【ジェレ・コ・サーレ抑制術学派】
        [4,"射すくめる視線",'コンジェラティオ＝オクルス'],
        [7,"目眩む光条",'ルクス＝カエクス'],
        [10,"精神爆発",'メンティス＝イラプティオ'],
        [13,"災禍の疾走",'マルム＝コンシートゥス'],
        #【モントメル背水賦活学派】
        [4,"負傷増力",'ヴルネラスティ＝ヴィス'],
        [7,"危地での俊敏",'ペリクロ＝アジリタス'],
        [10,"危地での抵抗",'ペリクロ＝パティエンティア'],
        [13,"死者の奇跡",'モーリ＝モンストルム'],
      ],
    },
  },
  'アーティザン' => {
    '2.0' => 1,
    expTable => 'B',
    id       => 'Art',
    eName    => 'artisan',
    craft => {
      jName => '呪印',
      eName => 'seal',
      data => [
        [1,'威力増強／+5',''],
        [1,'命中増強／+1',''],
        [1,'C値増強／-1',''],
        [1,'七色の武器',''],
        [1,'自動帰還',''],
        [1,'追撃の魔力',''],
        [1,'防護点増強／+1',''],
        [1,'回避増強／+1',''],
        [1,'危機回避','',''],
        [1,'幸運の誘い','',''],
        [1,'秘奥射程増強／+5m',''],
        [1,'秘奥ダメージ増強／+1',''],
        [1,'魔物知識増強／+2',''],
        [1,'誤射防止',''],
        [1,'生死判定増強／+3',''],
        [1,'MP自動回復／+1',''],
        [1,'HP増強／+5',''],
        [1,'能力値増強／+2',''],
        [1,'魔法ダメージ軽減／-1',''],
        [1,'浮遊落下',''],
        [1,'移動力増強',''],
        [1,'姿勢補助',''],
        [5,'威力超増強／+10',''],
        [5,'命中超増強／+1',''],
        [5,'C値超増強／-1',''],
        [5,'追撃の魔力増強／+2',''],
        [5,'武器巨大化／+10',''],
        [5,'防護点超増強／+1',''],
        [5,'魔法防御特化／-2＆-2',''],
        [5,'防護点特化／-2＆+3',''],
        [5,'属性ダメージ軽減／-2',''],
        [5,'回避超増強／+1',''],
        [5,'浮遊盾',''],
        [5,'魔力増強／+1',''],
        [5,'魔法クリティカル増強／-1',''],
        [5,'浮遊魔導書',''],
        [5,'魔物解析',''],
        [5,'戦場把握',''],
        [5,'回復増強／+1',''],
        [5,'回復効果クリティカル',''],
        [5,'ブレスダメージ軽減／-2',''],
        [5,'マナ吸収',''],
        [5,'抵抗力増強／+1',''],
        [5,'守護の障壁／-5',''],
        [5,'機先の運び／+2',''],
        [5,'移動力超増強',''],
        [5,'完全姿勢補助',''],
        [5,'不動の礎',''],
        [10,'威力極増強／+15',''],
        [10,'命中極増強／+1',''],
        [10,'C値極増強／-1',''],
        [10,'吸精の武器',''],
        [10,'武器超巨大化／+10',''],
        [10,'防護点極増強／+1',''],
        [10,'属性ダメージ超軽減／-2',''],
        [10,'属性ダメージ軽減範囲拡大',''],
        [10,'回避力極増強／+1',''],
        [10,'双魔増強',''],
        [10,'魔力超増強／+1',''],
        [10,'マナ効率化',''],
        [10,'魔物知識超増強／+2',''],
        [10,'魔導即応',''],
        [10,'回復超増強／+2',''],
        [10,'生死判定超増強／+3',''],
        [10,'魔法ダメージ超軽減／-2',''],
        [10,'ブレスダメージ超軽減／-3',''],
        [10,'HP超増強／+5',''],
        [10,'抵抗力超増強／+1',''],
        [10,'能力値超増強／+1',''],
        [10,'移動力極増強',''],
        [10,'風乗りの靴',''],
        [16,'命中力判定超越増強',''],
        [16,'会心撃／+20',''],
        [16,'威力出目増強／+3',''],
        [16,'瞬間防護点増強／+10点',''],
        [16,'属性ダメージ極軽減／-2',''],
        [16,'防護点超特化／-2＆+3',''],
        [16,'回避力判定超越増強',''],
        [16,'魔法回避',''],
        [16,'行使判定超越増強',''],
        [16,'マナ充填／+10点',''],
        [16,'魔物知識判定超越増強',''],
        [16,'達人の閃き',''],
        [16,'超成功復活',''],
        [16,'MP自動回復増強／+2',''],
        [16,'魔法ダメージ極軽減／-2',''],
        [16,'マナ超吸収／+1',''],
        [16,'抵抗力極増強／+1',''],
        [16,'能力値極限特化／-1＆+6',''],
        [16,'瞬間転移',''],
        [16,'先制判定超越増強',''],
      ],
    },
  },
  'アリストクラシー' => {
    '2.0' => 1,
    expTable => 'B',
    id       => 'Ari',
    eName    => 'aristocracy',
    craft => {
      jName => '貴格',
      eName => 'dignity',
      data => [
        [1,'威厳ある風格Ⅰ',''],
        [1,'麗しき歌声Ⅰ',''],
        [1,'華麗なる言の葉Ⅰ',''],
        [1,'気高き振る舞いⅠ',''],
        [1,'心震わせる美声Ⅰ',''],
        [1,'超然たるまなざしⅠ',''],
        [1,'優雅なる足運びⅠ',''],
        [1,'秘めたる博識Ⅰ',''],
        [1,'囁く気配Ⅰ',''],
        [1,'攻撃陣形',''],
        [1,'遠距離攻撃陣形',''],
        [1,'対レギオン攻撃',''],
        [1,'防御陣形',''],
        [1,'一気呵成の陣',''],
        [1,'高速移動陣形',''],
        [1,'他者追随',''],
        [1,'意思持たぬ兵隊',''],
        [1,'獣との共感',''],
        [1,'高額支給',''],
        [5,'威厳ある風格Ⅱ',''],
        [5,'麗しき歌声Ⅱ',''],
        [5,'華麗なる言の葉Ⅱ',''],
        [5,'心震わせる美声Ⅱ',''],
        [5,'超然たるまなざしⅡ',''],
        [5,'部下の情報収集',''],
        [5,'横一列攻撃陣形',''],
        [5,'波状攻撃陣形',''],
        [5,'一騎駆けの陣',''],
        [5,'魔力増大の陣',''],
        [5,'鶴翼の陣',''],
        [5,'射程延長',''],
        [5,'魚鱗の陣',''],
        [5,'野生のカン',''],
        [5,'硬い身体',''],
        [5,'対属性結界印',''],
        [10,'威厳ある風格Ⅲ',''],
        [10,'麗しき歌声Ⅲ',''],
        [10,'華麗なる言の葉Ⅲ',''],
        [10,'気高き振る舞いⅡ',''],
        [10,'心震わせる美声Ⅲ',''],
        [10,'超然たるまなざしⅢ',''],
        [10,'優雅なる足運びⅡ',''],
        [10,'秘めたる博識Ⅱ',''],
        [10,'囁く気配Ⅱ',''],
        [10,'熟練たる魚鱗の陣',''],
        [10,'魔撃の陣',''],
        [10,'一騎当千の陣',''],
        [10,'魔力暴走の陣',''],
        [10,'緊急覚醒',''],
        [10,'獣の生命力',''],
        [10,'鉄壁のファランクス',''],
        [10,'部隊分割',''],
        [16,'気高き振る舞いⅢ',''],
        [16,'優雅なる足運びⅢ',''],
        [16,'優秀なる部下の進言',''],
        [16,'怒涛の奔走',''],
        [16,'対レギオン防御',''],
        [16,'超高額支給',''],
      ],
    },
  },
);


1;