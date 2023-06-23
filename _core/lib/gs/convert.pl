################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

require $set::data_class;

sub urlDataGet {
  my $url = shift;
  my $ua  = LWP::UserAgent->new;
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->decoded_content;
  }
  else {
    return undef;
  }
}

sub dataConvert {
  my $set_url = shift;
  my $file;
  
  ## キャラクター保管所
  if($set_url =~ m"(^https?://charasheet\.vampire-blood\.net/m?[a-f0-9]+)"){
    my $data = urlDataGet($1.'.js') or error 'キャラクター保管所のデータが取得できませんでした';
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };
    
    return convertHokanjoToYtsheet(\%in);
  }
  ## ゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
    $data = thanSignEscape($data);
    my %pc = %{ decode_json(join '', $data) };
    if($pc{'result'} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{'convertSource'} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{'result'}) {
      error 'コンバート元のゆとシートⅡでエラーがありました。<br>>'.$pc{'result'};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

### キャラクター保管所 --------------------------------------------------
sub convertHokanjoToYtsheet {
  my %in = %{$_[0]};

  my %classes = (1 => '戦士', 2 => '武道家', 3 => '野伏', 4 => '斥候',);
  my %weapons = (1 => '片手剣', 2 => '両手剣', 3 => '斧', 4 => '槍', 5 => '戦鎚', 6 => '棍杖', 7 => '格闘武器', 8 => '投擲武器', 9 => '弩弓');
  my %armors  = (1 => '衣鎧', 2 => '軽鎧', 3 => '重鎧');
  my %shields = (1 => '小型盾', 2 => '大型盾', 3 => '小型盾');

  my %pc = (
    convertSource => 'キャラクター保管所',
    characterName => $in{'pc_name'} || $in{'data_title'},
    tags => convertTags($in{'pc_tags'}),
    race => $in{'shuzoku_name'},
    birth => $in{'umare_name'},
    age => $in{'age'},
    gender => $in{'sex'},
    traits => "$in{'pc_height'}／$in{'pc_weight'}／肌の色:$in{'color_skin'}",
    traitsHair => $in{'color_hair'},
    traitsEyes => $in{'color_eye'},
    money => $in{'money'},
    deposit => $in{'debt'},
    ability1StrBase => $in{'BP1'},
    ability1PsyBase => $in{'BP2'},
    ability1TecBase => $in{'BP3'},
    ability1IntBase => $in{'BP4'},
    ability2FocBase => $in{'BP5'},
    ability2EduBase => $in{'BP6'},
    ability2RefBase => $in{'BP7'},
    statusLifeDice  => $in{'BP8'},
    statusMoveDice  => $in{'BP9'},
    statusSpellDice => $in{'BP10'},
    ability1StrMod => $in{'SA1'},
    ability1PsyMod => $in{'SA2'},
    ability1TecMod => $in{'SA3'},
    ability1IntMod => $in{'SA4'},
    ability2FocMod => $in{'SA5'},
    ability2EduMod => $in{'SA6'},
    ability2RefMod => $in{'SA7'},
    statusLifeMod  => $in{'SA8'},
    statusMoveMod  => $in{'SA9'},
    statusSpellMod => $in{'SA10'},
    statusResistMod=> $in{'SA11'},
    lvFig => $in{'GLv1'} || '',
    lvMon => $in{'GLv2'} || '',
    lvRan => $in{'GLv3'} || '',
    lvSco => $in{'GLv4'} || '',
    lvSor => $in{'GLv5'} || '',
    lvPri => $in{'GLv6'} || '',
    lvDra => $in{'GLv7'} || '',
    lvSha => $in{'GLv8'} || '',
    lvNec => $in{'GLv9'} || '',
    careerOrigin => $in{'shutuji_name'},
    careerGenesis => $in{'raireki_name'},
    careerEncounter => $in{'kaikou_name'},
    careerOriginClass => $in{'create_ginou_name'},

    dodgeClass    => $classes{$in{'kaihi_ginou'}},
    dodgeModName  => $in{'armor_tokugi_memo'},
    dodgeModValue => $in{'bougu_kaihi_mod'},
    MoveModValue  => $in{'shield_name'},
    armor1Name    => $in{'armor_name'},
    armor1Type    => $armors{$in{'armer_type'}},
    armor1Weight  => $in{'armer_weight'} ? '重' : '軽',
    armor1DodgeMod=> $in{'armor_kaihi'},
    armor1Armor   => $in{'armor_bougo'},
    armor1MoveMod => $in{'armor_move'},
    armor1Stealth => $in{'armer_onmitu'} == 2 ? '悪い' : $in{'armer_onmitu'} ? '普通' : '良い',
    armor1Note    => $in{'armor_memo'},

    blockClass     => $classes{$in{'kaihi_ginou'}},
    shield1Name    => $in{'shield_name'},
    shield1Type    => $shields{$in{'shield_type'}},
    shield1Weight  => $in{'shield_weight'} ? '重' : '軽',
    shield1BlockMod=> $in{'shield_kaihi'},
    shield1Armor   => $in{'shield_bougo'},
    shield1Stealth => $in{'shield_onmitu'} == 2 ? '悪い' : $in{'shield_onmitu'} ? '普通' : '良い',
    shield1Note    => $in{'shield_memo'},
  );
  ## 能力値ボーナス
  if   ($in{'nouryoku_bonus'} eq "1"){ $pc{ability1Bonus} = 'Str' }
  elsif($in{'nouryoku_bonus'} eq "2"){ $pc{ability1Bonus} = 'Psy' }
  elsif($in{'nouryoku_bonus'} eq "3"){ $pc{ability1Bonus} = 'Tec' }
  elsif($in{'nouryoku_bonus'} eq "4"){ $pc{ability1Bonus} = 'Int' }

  ## 種族
  ($pc{race}     = $in{'shuzoku_name'}) =~ s|/|:|;
  ($pc{raceBase} = $in{'shuzoku2_name'}) =~ s|/|:|;
  
  ## 等級
  $pc{rank} = ($in{'toukyuu'} !~ /等級$/ ? "$in{'toukyuu'}等級" : $in{'toukyuu'});

  ## 武器
  my $i = 0;
  foreach my $name (@{$in{'arms_name'}}){
    $pc{'weapon'.($i+1).'Name'}    = $name;
    $pc{'weapon'.($i+1).'Type'}    = $weapons{$in{'arms_cate'}[$i]};
    $pc{'weapon'.($i+1).'Usage'}   = $in{'arms_yoho'}[$i];
    $pc{'weapon'.($i+1).'Weight'}  = $in{'arms_weights'}[$i] ? '重' : '軽';
    $pc{'weapon'.($i+1).'Attr'}    = $in{'arms_rank'}[$i];
    $pc{'weapon'.($i+1).'HitMod'}  = $in{'arms_hit_mod'}[$i]*1 + $in{'arms_hit_mod_sub'}[$i]*1;
    $pc{'weapon'.($i+1).'Power'}   = $in{'arms_iryoku'}[$i];
    $pc{'weapon'.($i+1).'PowerMod'}= $in{'arms_damage_mod'}[$i] *1;
    $pc{'weapon'.($i+1).'Note'}    = $in{'arms_memo'}[$i];
    $pc{'weapon'.($i+1).'Class'}   = $classes{$in{'arms_hit_ginou'}[$i]};

    $pc{cashbook} .= "${name} ::-$in{'arms_price'}[$i]\n";
    $i++;
  }
  $pc{weaponNum} = $i;

  $pc{cashbook} .= "$in{'armor_name'} ::-$in{'armor_price'}\n";
  $pc{cashbook} .= "$in{'shield_name'} ::-$in{'shield_price'}\n";
  ## 所持品
  my $i = 0;
  foreach my $name (@{$in{'item_name'}}){
    if($name && $in{'item_tanka'}[$i] && $in{'item_num'}[$i]){
      $pc{items} .= "${name} ($in{'item_tanka'}[$i]) × $in{'item_num'}[$i]".($in{'item_memo'}[$i] ? ' …… ': '').$in{'item_memo'}[$i]."\n";
      $pc{cashbook} .= "${name} ::-$in{'item_tanka'}[$i]*$in{'item_num'}[$i]\n";
    }
    elsif($name){
      $pc{items} .= "${name}".($in{'item_memo'}[$i] ? ' …… ': '').$in{'item_memo'}[$i]."\n";
      $pc{cashbook} .= "${name}\n";
    }
    else {
      $pc{items} .= "\n";
      $pc{cashbook} .= "\n";
    }
    $i++;
  }

  ## 技能
  {
    my $i = 0;
    my $sa = 0;
    my $sg = 0;
    my %grade = ( 1 => '初歩', 2 => '習熟', 3 => '熟練', 4 => '達人', 5 => '伝説' );
    foreach my $name (@{$in{'ginou_name'}}){
      if($in{'ginou_type'}[$i]){ $sg++ } else { $sa++; }
      my $type = $in{'ginou_type'}[$i] ? 'generalSkill'.($sg) : 'skill'.($sa);
      
      ($pc{$type.'Name'} = $name) =~ s/^【(.*?)】$/$1/;

      $pc{$type.'Grade'} = $grade{$in{'ginou_lv'}[$i]};
      $pc{$type.'Page'}  = $in{'ginou_shozoku'}[$i];
      $pc{$type.'Note'}  = ( $in{'ginou_header' }[$i] ? "［$in{'ginou_header'}[$i]］" : '' ) . $in{'ginou_memo'}[$i];

      if($in{'shoki_ginou'} =~ /$name/ || $in{'ginou_header'}[$i] =~ /出自|来歴|種族/){ $pc{$type.'Auto'} = 1 }

      $i++;
    }
    $pc{skillNum} = $i;
    $pc{generalSkillNum} = $i;
  }

  ## 呪文
  {
    my $i = 0;
    foreach my $name (@{$in{'effect_name'}}){
      ($pc{'spell'.($i+1).'Name'} = $name) =~ s/^《(.*?)》$/$1/;
      
      $pc{'spell'.($i+1).'System'}= $in{'effect_keitou'}[$i];
      $pc{'spell'.($i+1).'Attr'}  = $in{'effect_zokusei'}[$i];
      $pc{'spell'.($i+1).'Dfclt'} = $in{'effect_nanido'}[$i];
      $pc{'spell'.($i+1).'Page'}  = $in{'effect_shozoku'}[$i];
      $pc{'spell'.($i+1).'Note'}
        = ( $in{'effect_header' }[$i] ? "［$in{'effect_header'}[$i]］" : '' )
        . ( $in{'effect_taishou'}[$i] ? "「対象：$in{'effect_taishou'}[$i]」" : '' )
        . ( $in{'effect_range'  }[$i] ? "「射程：$in{'effect_range'  }[$i]」" : '' )
        . $in{'effect_memo'}[$i];
      
      if($pc{'spell'.($i+1).'Attr'} =~ /^(.+?)(?:呪文)?[（(](.+?)[)）]$/){
        $pc{'spell'.($i+1).'Type'} = $1;
        $pc{'spell'.($i+1).'Attr'} = $2;
      }
      $i++;
    }
    $pc{spellNum} = $i;
  }
  ## 履歴
  $pc{history0Exp}   = 3000;
  $pc{history0Adp}   = 0;
  $pc{history0Money} = 100;
  my $i = 0; my $growcount;
  foreach my $comleted (@{$in{'adv_completed'}}){
    $pc{'history'.($i+1).'Completed'} = $comleted;
    if(!$comleted && ($in{'adv_exp_his'}[$i] || $in{'ap_his'}[$i])){
      $pc{'history'.($i+1).'Completed'} = -1;
    }

    $pc{'history'.($i+1).'Exp'}  = $in{'adv_exp_his'}[$i];
    if($in{'bns_exp_his'}[$i] ne ''){
      if($in{'adv_exp_his'}[$i] ne ''){ $pc{'history'.($i+1).'Exp'} .= '+' }
      $pc{'history'.($i+1).'Exp'} .= $in{'bns_exp_his'}[$i];
    }

    $pc{'history'.($i+1).'Adp'}   = $in{'ap_his'}[$i];
    $pc{'history'.($i+1).'Money'} = $in{'get_money_his'}[$i];
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    $i++;
  }
  $pc{historyNum} = $i;
  ## プロフィール追加
  my $profile;
  $profile .= ":経歴|$in{'keireki'}[0]\n";
  $profile .= ":    |$in{'keireki'}[1]\n";
  $profile .= ":    |$in{'keireki'}[2]\n";
  
  $pc{freeNote} = $profile.$in{'pc_making_memo'},
  $pc{freeNoteView} = (tagUnescape tagUnescapeLines $profile).$in{'pc_making_memo'};
  $pc{freeNoteView} =~ s/\r\n?|\n/<br>/g;
  
  ## チャットパレット
  $pc{paletteUseBuff} = 1;
  
  ## 〆
  $pc{ver} = 0;
  return %pc;
}

## タグ：全角スペース・英数を半角に変換 --------------------------------------------------
sub convertTags {
  my $tags = shift;
  $tags =~ tr/　/ /;
  $tags =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $tags =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  $tags =~ tr/ / /s;
  return $tags
}

1;