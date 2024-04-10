#################### 種族 ####################
use strict;
use utf8;

package data;

### 種族データ --------------------------------------------------
our @races_data = (
  { name => '只人',
    kana => 'ヒューム',
    move => 3,
  },
  { name => '鉱人',
    kana => 'ドワーフ',
    move => 2,
  },
  { name => '森人',
    kana => 'エルフ',
    move => 4,
  },
  { name => '蜥蜴人',
    kana => 'リザードマン',
    move => 2,
  },
  { name => '圃人',
    kana => 'レーア',
    move => 3,
  },
  { name => '闇人',
    kana => 'ダークエルフ',
    move => 3,
  },
  { name => '獣人',
    kana => 'パットフット',
    move => 'variant',
    variant => ['格闘態','剛力態','俊敏態','知覚態'],
    variantData => {
      '格闘態' => {
        move => 3,
      },
      '剛力態' => {
        move => 2,
      },
      '俊敏態' => {
        move => 4,
      },
      '知覚態' => {
        move => 3,
      }
    }
  },
  { name => '獣憑き',
    kana => 'ビーストバインド',
    base => ['只人','鉱人','森人','蜥蜴人','圃人','闇人','獣人'],
    move => 3,
  },
  { name => '昼歩く者',
    kana => 'デイウォーカー',
    variant => ['ダンピール','クルースニク','ズドゥハチ'],
    base => ['只人','鉱人','森人','蜥蜴人','圃人','闇人','獣人:格闘態','獣人:剛力態','獣人:俊敏態','獣人:知覚態'],
    move => 'base',
  },
);

our @padfoots_data = (
  { name => '犬人',
    kana => 'カニス',
  },
  { name => '狼人',
    kana => 'ルプス',
  },
  { name => '猫人',
    kana => 'フェリス',
  },
  { name => '虎人',
    kana => 'パンテラ',
  },
  { name => '熊人',
    kana => 'ウルス',
  },
  { name => '牛人',
    kana => 'ミノタウロス',
  },
  { name => '蝙蝠人',
    kana => 'カイロプテラン',
  },
  { name => '馬人',
    kana => 'セントール',
  },
  { name => '兎人',
    kana => 'ササカ',
  },
  { name => '鼠人',
    kana => 'ムーソ',
  },
  { name => '鳥人',
    kana => 'ハルピュイア',
  },
  { name => '鶻人',
    kana => 'ペレグリン',
  },
  { name => '鴉人',
    kana => 'コルバス',
  },
  { name => '鴨人',
    kana => 'プラティリンコス',
  },
  { name => '駝鳥人',
    kana => 'ストルチオ',
  },
  { name => '鶏人',
    kana => 'ガルス',
  },
  { name => '鰓人',
    kana => 'ギルマン',
  },
  { name => '蟲人',
    kana => 'ミュルミドン',
  },
  { name => '蚕人',
    kana => 'ボンビクス',
  },
  { name => '蜻蛉人',
    kana => 'オドネーター',
  },
  { name => '飛蝗人',
    kana => 'ローカスト',
  },
  { name => '蟷螂人',
    kana => 'マントデア',
  },
  { name => '蜘蛛人',
    kana => 'アラネア',
  },
);

our @beastbind_data = (
  { name => '人狼',
    kana => 'ルーガルー',
  },
  { name => '人虎',
    kana => 'マカン・ガドゥンガン',
  },
  { name => '妖狐',
    kana => 'フォックステイル',
  },
  { name => '化狸',
    kana => 'タヌキ',
  },
  { name => '貂',
    kana => 'マーテン',
  },
  { name => '仙鶴',
    kana => 'フェイラン',
  },
  { name => '化猫',
    kana => 'ワーキャット',
  },
);

our %races;
our @race_names;
foreach my $data (@races_data){
  my $name = $data->{name};
  $races{$name} = $data;
  push(@race_names, $name);
}
our @race_list;
foreach my $name (@race_names){
  if($races{$name}{variant}){
    foreach my $varname (@{ $races{$name}{variant} }){ push(@race_list, "${name}:${varname}") }
  }
  else {
    push(@race_list, $name)
  }
}

our @padfoots_names;
our %padfoots;
foreach my $data (@padfoots_data){
  my $name = $data->{name};
  $padfoots{$name} = $data;
  push(@padfoots_names, $name);
}

our @beastbind_names;
our %beastbind;
foreach my $data (@beastbind_data){
  my $name = $data->{name};
  $beastbind{$name} = $data;
  push(@beastbind_names, $name);
}

1;