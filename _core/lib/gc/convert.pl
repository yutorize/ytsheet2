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
    
    if(exists$in{guild_master}){
      return convertHokanjoToYtsheetCountry(\%in);
    }
    else { return convertHokanjoToYtsheet(\%in); }
  }

  ## ゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
    $data = escapeThanSign($data);
    my %pc = utf8::is_utf8($data) ? %{ decode_json(encode('utf8', (join '', $data))) } : %{ decode_json(join '', $data) };
    if($pc{result} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{result}) {
      error 'コンバート元のゆとシートⅡでエラーがありました<br>>'.$pc{result};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

### キャラクター保管所 --------------------------------------------------
sub convertHokanjoToYtsheet {
  my %in = %{$_[0]};
  ## 単純変換
  my %pc = (
    convertSource => 'キャラクター保管所',
    tags => convertTags($in{'pc_tags'}),
    age => $in{'age'},
    gender => $in{'sex'},
    height => $in{'pc_height'},
    weight => $in{'pc_weight'},
    style => $in{'class1_name'},
    works => $in{'class2_name'},
    level => $in{'level'},
    sttStrWorks => $in{'SS1'},
    sttRefWorks => $in{'SS2'},
    sttPerWorks => $in{'SS3'},
    sttIntWorks => $in{'SS4'},
    sttMndWorks => $in{'SS5'},
    sttEmpWorks => $in{'SS6'},
    sttStrMake => $in{'BP1'},
    sttRefMake => $in{'BP2'},
    sttPerMake => $in{'BP3'},
    sttIntMake => $in{'BP4'},
    sttMndMake => $in{'BP5'},
    sttEmpMake => $in{'BP6'},
    sttStrMod => $in{'TB1'},
    sttRefMod => $in{'TB2'},
    sttPerMod => $in{'TB3'},
    sttIntMod => $in{'TB4'},
    sttMndMod => $in{'TB5'},
    sttEmpMod => $in{'TB6'},
    sttStrStyle => $in{'S1'},
    sttRefStyle => $in{'S2'},
    sttPerStyle => $in{'S3'},
    sttIntStyle => $in{'S4'},
    sttMndStyle => $in{'S5'},
    sttEmpStyle => $in{'S6'},
    sttHpWorks => $in{'SS7'},
    sttMpWorks => $in{'SS8'},
    sttHpStyle => $in{'S7'},
    sttMpStyle => $in{'S8'},
    sttHpMod => $in{'TM7'},
    sttMpMod => $in{'TM8'},
    lifepathBirth => ($in{'shutuji_name'} && $in{'shutuji_memo'}) ? $in{'shutuji_name'}."：".$in{'shutuji_memo'} : $in{'shutuji_name'} || $in{'shutuji_memo'},
    lifepathExp1  => ($in{'keiken_name' } && $in{'keiken_memo' }) ? $in{'keiken_name' }."：".$in{'keiken_memo' } : $in{'keiken_name' } || $in{'keiken_memo' },
    lifepathExp2  => ($in{'keiken2_name'} && $in{'keiken2_memo'}) ? $in{'keiken2_name'}."：".$in{'keiken2_memo'} : $in{'keiken2_name'} || $in{'keiken2_memo'},
    beliefPurpose => $in{'keiken2_memo'} || $in{'mokuhyo_name'},
    beliefTaboo   => $in{'kinki_memo'  } || $in{'kinki_name'  },
    beliefQuirk   => $in{'shumi_memo'  } || $in{'shumi_name'  },
    skillStr1Lv => $in{'skill_tokugi'}[0],
    skillStr2Lv => $in{'skill_tokugi'}[1],
    skillStr3Lv => $in{'skill_tokugi'}[2],
    skillStr4Lv => $in{'skill_tokugi'}[3],
    skillStr5Lv => $in{'skill_tokugi'}[4],
    skillRef1Lv => $in{'skill_tokugi'}[5],
    skillRef2Lv => $in{'skill_tokugi'}[6],
    skillRef3Lv => $in{'skill_tokugi'}[7],
    skillRef4Lv => $in{'skill_tokugi'}[8],
    skillRef5Lv => $in{'skill_tokugi'}[9],
    skillPer1Lv => $in{'skill_tokugi'}[10],
    skillPer2Lv => $in{'skill_tokugi'}[11],
    skillPer3Lv => $in{'skill_tokugi'}[12],
    skillPer4Lv => $in{'skill_tokugi'}[13],
    skillInt1Lv => $in{'skill_tokugi'}[14],
    skillInt2Lv => $in{'skill_tokugi'}[15],
    skillInt3Lv => $in{'skill_tokugi'}[16],
    skillInt4Lv => $in{'skill_tokugi'}[17],
    skillInt5Lv => $in{'skill_tokugi'}[18],
    skillMnd1Lv => $in{'skill_tokugi'}[19],
    skillMnd2Lv => $in{'skill_tokugi'}[20],
    skillEmp1Lv => $in{'skill_tokugi'}[21],
    skillEmp2Lv => $in{'skill_tokugi'}[22],
    skillEmp3Lv => $in{'skill_tokugi'}[23],
    skillEmp4Lv => $in{'skill_tokugi'}[24],
    weaponMainName   => $in{'arms_name'}[0],
    weaponMainWeight => $in{'arms_price'}[0],
    weaponMainSkill  => $in{'arms_hit_param'}[0],
    weaponMainAcc    => $in{'arms_hit_mod'}[0],
    weaponMainAtk    => $in{'arms_power'}[0],
    weaponMainRange  => $in{'arms_range'}[0],
    weaponMainGuard  => $in{'arms_guard_level'}[0],
    weaponMainNote  => $in{'arms_sonota'}[0],
    weaponSubName   => $in{'arms_name'}[1],
    weaponSubWeight => $in{'arms_price'}[1],
    weaponSubSkill  => $in{'arms_hit_param'}[1],
    weaponSubAcc    => $in{'arms_hit_mod'}[1],
    weaponSubAtk    => $in{'arms_power'}[1],
    weaponSubRange  => $in{'arms_range'}[1],
    weaponSubGuard  => $in{'arms_guard_level'}[1],
    weaponSubNote   => $in{'arms_sonota'}[1],
    armorMainName        => $in{'armer_name'},
    armorMainWeight      => $in{'armer_price'},
    armorMainEva         => $in{'armer_dodge'},
    armorMainDefWeapon   => $in{'armer_defA'},
    armorMainDefFire     => $in{'armer_defB'},
    armorMainDefShock    => $in{'armer_defC'},
    armorMainDefInternal => $in{'armer_defD'},
    armorMainInit        => $in{'armer_act'},
    armorMainMove        => $in{'armer_move'},
    armorMainNote        => $in{'armer_sonota'},
    armorSubName        => $in{'armer2_name'},
    armorSubWeight      => $in{'armer2_price'},
    armorSubEva         => $in{'armer2_dodge'},
    armorSubDefWeapon   => $in{'armer2_defA'},
    armorSubDefFire     => $in{'armer2_defB'},
    armorSubDefShock    => $in{'armer2_defC'},
    armorSubDefInternal => $in{'armer2_defD'},
    armorSubInit        => $in{'armer2_act'},
    armorSubMove        => $in{'armer2_move'},
    armorSubNote        => $in{'armer2_sonota'},
    armorOtherName        => $in{'armer2_name'},
    armorOtherWeight      => $in{'armer2_price'},
    armorOtherEva         => $in{'armer2_dodge'},
    armorOtherDefWeapon   => $in{'armer2_defA'},
    armorOtherDefFire     => $in{'armer2_defB'},
    armorOtherDefShock    => $in{'armer2_defC'},
    armorOtherDefInternal => $in{'armer2_defD'},
    armorOtherInit        => $in{'armer2_act'},
    armorOtherMove        => $in{'armer2_move'},
    armorOtherNote        => $in{'armer2_sonota'},
  );
  ##名前
  ($pc{characterName},$pc{characterNameRuby}) = convertNameRuby($in{'pc_name'} || $in{'data_title'});
  ($pc{aka},$pc{akaRuby}) = convertNameRuby($in{'pc_codename'});

  ## 
  foreach my $name (@data::styleNames){
    if($name eq $in{'class1_name'}){
      $pc{class} = $data::styleData{$name}{class};
    }
  }
  ## 成長
  {  
    my $i = 2;
    $pc{"freeHistory"} = "**特技取得\n";
    foreach(@{$in{'LvupH_KN1'}}){
      $pc{"sttStrGrow${i}"} = $in{'LvupH_KN1'}[$i-2];
      $pc{"sttRefGrow${i}"} = $in{'LvupH_KN2'}[$i-2];
      $pc{"sttPerGrow${i}"} = $in{'LvupH_KN3'}[$i-2];
      $pc{"sttIntGrow${i}"} = $in{'LvupH_KN4'}[$i-2];
      $pc{"sttMndGrow${i}"} = $in{'LvupH_KN5'}[$i-2];
      $pc{"sttEmpGrow${i}"} = $in{'LvupH_KN6'}[$i-2];

      $pc{"freeHistory"} .= ($i-1)."→$i:";
      $pc{"freeHistory"} .= "《$in{'LvupH_skill1'}[$i-2]》";
      $pc{"freeHistory"} .= "《$in{'LvupH_skill2'}[$i-2]》";
      $pc{"freeHistory"} .= "《$in{'LvupH_skill3'}[$i-2]》\n";
      $pc{"freeHistory"} =~ s/《《/《/g;
      $pc{"freeHistory"} =~ s/》》/》/g;
      $i++;
    }
    $pc{freeHistoryView} = unescapeTags unescapeTagsLines $pc{"freeHistory"};
    $pc{freeHistoryView} =~ s/\r\n?|\n/<br>/g;
  }
  ## 因縁
  foreach my $i (1..5){
    $pc{"bond${i}Name"} = $in{'cone_name'}[$i-1];
    $pc{"bond${i}Relation"} = $in{'cone_kankei'}[$i-1];
    $pc{"bond${i}EmotionMain"} = $in{'cone_mkanjo'}[$i-1];
    $pc{"bond${i}EmotionSub"} = $in{'cone_skanjo'}[$i-1];
  }
  
  ## 特技
  {
    my $classNum = 1;
    my $worksNum = 1;
    my $i = 0;
    foreach my $name (@{$in{'effect_name'}}){
      my $type = 'class';
      my $n = $classNum;
      if($in{'effect_shozoku'}[$i] =~ /ワークス/){
        $type = 'works';
        $n = $worksNum;
      }
      $pc{$type.'Ability'.($n).'Name'} = $name;
      $pc{$type.'Ability'.($n).'Lv'} = convertEffectLv($in{'effect_lv'}[$i]);
      $pc{$type.'Ability'.($n).'Timing'}   = convertTiming($in{'effect_timing'}[$i]);
      $pc{$type.'Ability'.($n).'Check'}    = $in{'effect_hantei'}[$i];
      $pc{$type.'Ability'.($n).'Target'}   = $in{'effect_taisho'}[$i];
      $pc{$type.'Ability'.($n).'Range'}    = $in{'effect_range'}[$i];
      $pc{$type.'Ability'.($n).'Cost'}     = $in{'effect_cost'}[$i];
      $pc{$type.'Ability'.($n).'Restrict'} = $in{'effect_page'}[$i];
      $pc{$type.'Ability'.($n).'Note'}     = $in{'effect_memo'}[$i];
      if($in{'effect_shozoku'}[$i] =~ /天恵|魔法|邪紋/){
        $pc{$type.'Ability'.($n).'Type'} = $in{'effect_shozoku'}[$i];
      }
      $i++;
      if($type eq 'works'){
        $worksNum++;
      }
      else {
        $classNum++;
      }
    }
    $pc{classAbilityNum} = $classNum-1;
    $pc{worksAbilityNum} = $worksNum-1;
  }
  
  ## 魔法
  {
    my $n = 1;
    my $i = 0;
    foreach my $name (@{$in{'magic_name'}}){
      $pc{'magic'.($n).'Name'} = $name;
      $pc{'magic'.($n).'Lv'} = convertEffectLv($in{'magic_lv'}[$i]);
      $pc{'magic'.($n).'Type'}     = $in{'magic_shozoku'}[$i];
      $pc{'magic'.($n).'Timing'}   = convertTiming($in{'magic_timing'}[$i]);
      $pc{'magic'.($n).'Check'}    = $in{'magic_hantei'}[$i];
      $pc{'magic'.($n).'Target'}   = $in{'magic_taisho'}[$i];
      $pc{'magic'.($n).'Range'}    = $in{'magic_range'}[$i];
      $pc{'magic'.($n).'Cost'}     = $in{'magic_cost'}[$i];
      $pc{'magic'.($n).'Restrict'} = $in{'magic_page'}[$i];
      $pc{'magic'.($n).'Note'}     = $in{'magic_memo'}[$i];
      $i++;
      $n++;
    }
    $pc{magicNum} = $n-1;
  }
  sub convertEffectLv {
    my $lv = shift;
    if   ($lv > 9) { return $lv - 10; }
    elsif($lv > 5) { return $lv -  6; }
    elsif($lv < 1) { return 1; }
    return $lv;
  }
  
  ## アイテム
  {
    my $i = 0;
    foreach my $name (@{$in{'item_name'}}){
      $pc{'item'.($i+1).'Name'} = $name;
      $pc{'item'.($i+1).'Weight'} = $in{'item_tanka'}[$i];
      $pc{'item'.($i+1).'Quantity'} = $in{'item_num'}[$i];
      $pc{'item'.($i+1).'Note'}  = $in{'item_memo'}[$i];
      $i++;
    }
    $pc{itemNum} = $i;
  }
  ## アクションセット
  my %numToSkill = (
    1  => '格闘',
    12 => '力技',
    2  => '重武器',
    3  => '軽武器',
    4  => '騎乗',
    5  => '射撃',
    13 => '知覚',
    6  => '霊感',
    7  => '治療',
    8  => '混沌知識',
    9  => '意志',
    10 => '聖印',
    11 => '感性',
  );
  my %numToSkillE = (
    0  => '回避',
    1  => '格闘',
    2  => '重武器',
    3  => '軽武器',
    4  => '隠密',
    5  => '騎乗',
    6  => '射撃',
    13 => '知覚',
    7  => '霊感',
    8  => '治療',
    9  => '混沌知識',
    10 => '意志',
    11 => '聖印',
    12 => '感性',
  );
  my @numToStt = (
    '',
    '筋力',
    '反射',
    '感覚',
    '知力',
    '精神',
    '共感',
    '最大',
    '２番目',
  );
  {
    my $i = 0;
    foreach my $name (@{$in{'acts_name'}}){
      my $n = $i+1;
      $pc{"actionSet${n}Name"} = $name;
      $pc{"actionSet${n}Skill"} = $numToSkill{ $in{'acts_hit_param'}[$i] };
      $pc{"actionSet${n}Check"} = $numToStt[ $in{'V_acts_hit_status'}[$i] ];
      $pc{"actionSet${n}Dice"}  = $in{'acts_hit_dice_mod'}[$i];
      $pc{"actionSet${n}Mod"}   = $in{'acts_hit_mod'}[$i];
      $pc{"actionSet${n}Range"} = $in{'acts_range'}[$i];
      $pc{"actionSet${n}Dmg"}   = $in{'acts_power'}[$i];
      $pc{"actionSet${n}MC"}    = $in{'acts_mc'}[$i];
      $pc{"actionSet${n}Cost"}  = $in{'acts_cist'}[$i];
      $pc{"actionSet${n}Note"}  = $in{'acts_sonota'}[$i];
      $i++;
    }
    $pc{actionSetNum} = $i;
  }
  {
    my $i = 0;
    foreach my $name (@{$in{'evades_name'}}){
      my $n = $i+1;
      $pc{"reactionSet${n}Name"} = $name;
      $pc{"reactionSet${n}Skill"} = $numToSkillE{ $in{'evades_hit_param'}[$i] };
      $pc{"reactionSet${n}Check"} = $numToStt[ $in{'V_evades_hit_status'}[$i] ];
      $pc{"reactionSet${n}Dice"}  = $in{'evades_hit_dice_mod'}[$i];
      $pc{"reactionSet${n}Mod"}   = $in{'evades_hit_mod'}[$i];
      $pc{"reactionSet${n}MC"}    = $in{'evades_mc'}[$i];
      $pc{"reactionSet${n}Cost"}  = $in{'evades_cist'}[$i];
      $pc{"reactionSet${n}Note"}  = $in{'evades_sonota'}[$i];
      $i++;
    }
    $pc{reactionSetNum} = $i;
  }

  ## 履歴
  my $i = 0;
  foreach my $exp (@{$in{'get_exp_his'}}){
    $pc{'history'.($i+1).'Exp'}  = "$in{'adv_exp_his'}[$i]+$in{'bns_exp_his'}[$i]";
    $pc{'history'.($i+1).'Exp'}  =~ s/(^\+|\+$)//;
    $pc{'history'.($i+1).'Note'} = $in{'seicho_memo_his'}[$i];
    $i++;
  }
  $pc{historyNum} = $i;
  $pc{history0Exp} = 0;
  
  ## プロフィール追加
  my $profile;
  $profile .= ": 髪 |$in{'color_hair'}\n";
  $profile .= ": 瞳 |$in{'color_eye'}\n";
  $profile .= ": 肌 |$in{'color_skin'}\n";
  
  $pc{freeNote} = $profile.$in{'pc_making_memo'};
  $pc{freeNoteView} = (unescapeTags unescapeTagsLines $profile).$in{'pc_making_memo'};
  $pc{freeNoteView} =~ s/\r\n?|\n/<br>/g;
  
  ## チャットパレット
  $pc{paletteUseBuff} = 1;

  ## 〆
  $pc{ver} = 0;
  return %pc;
}
sub convertTiming {
  my $str = shift;
  $str =~ s|/|／|;
  $str =~ s/ｵｰﾄ/オート/;
  $str =~ s/ﾒｼﾞｬｰ/メジャー/;
  $str =~ s/ﾏｲﾅｰ/マイナー/;
  $str =~ s/ﾘｱｸｼｮﾝ/リアクション/;
  $str =~ s/ﾘｱ/リア/;
  $str =~ s/ｱｸｼｮﾝ/アクション/;
  $str =~ s/ｾｯﾄｱｯﾌﾟ/セットアップ/;
  $str =~ s/ｲﾆｼｱﾁﾌﾞ/イニシアチブ/;
  $str =~ s/ｸﾘﾝﾅｯﾌﾟ/クリンナップ/;
  $str =~ s/ﾌﾟﾛｾｽ/プロセス/;
  return $str;
}
sub convertNameRuby {
  my $name = shift;
  if    ($name =~ /^(.+)[\(（](.+?)[\)）]$/){ return $1,$2; }
  elsif ($name =~ /^(.+)[\"“](.+?)[\"”]$/){ return $1,$2; }
  else { return $name; }
}


### キャラクター保管所・国 --------------------------------------------------
sub convertHokanjoToYtsheetCountry {
  my %in = %{$_[0]};
  ## 単純変換
  my %pc = (
    convertSource => 'キャラクター保管所',
    type => 'c',
    countryName => $in{'pc_name'} || $in{'data_title'},
    tags => convertTags($in{'pc_tags'}),
    lord => $in{'guild_master'},
    level => $in{'guild_lv'},
    Characteristics1Food    => $in{'MC1'},
    Characteristics1Tech    => $in{'MC2'},
    Characteristics1Horse   => $in{'MC3'},
    Characteristics1Mineral => $in{'MC4'},
    Characteristics1Forest  => $in{'MC5'},
    Characteristics1Funds   => $in{'MC6'},
    growFood    => $in{'LM1'},
    growTech    => $in{'LM2'},
    growHorse   => $in{'LM3'},
    growMineral => $in{'LM4'},
    growForest  => $in{'LM5'},
    growFunds   => $in{'LM6'},
  );
  ## メンバー
  {
    my $i = 0;
    foreach (@{$in{'guild_member_name'}}){
      $pc{"member${i}Name"}  = $in{'guild_member_name'}[$i];
      $pc{"member${i}URL"}   = "./?url=https://charasheet.vampire-blood.net/".$in{'guild_member_id'}[$i] if $in{'guild_member_id'}[$i];
      $pc{"member${i}Class"} = $in{'guild_member_mcls_name'}[$i];
      $pc{"member${i}Style"} = $in{'guild_member_scls_name'}[$i];
      $pc{"member${i}Memo"}  = $in{'guild_member_memo'}[$i];
      $i++;
    }
    $pc{memberNum} = $i + 1;
  }
  
  ## アカデミーサポート
  {
    my $i = 0;
    foreach my $name (@{$in{'guild_skill_name'}}){
      my $n = $i + 1;
      $pc{'academySupport'.($n).'Name'}   = $name;
      $pc{'academySupport'.($n).'Lv'}     = $in{'guild_skill_sl'}[$i];
      $pc{'academySupport'.($n).'Cost'}   = $in{'guild_skill_page'}[$i];
      $pc{'academySupport'.($n).'Timing'} = convertTiming($in{'guild_skill_timing'}[$i]);
      $pc{'academySupport'.($n).'Note'}   = $in{'guild_skill_memo'}[$i];
      $i++;
    }
    $pc{academySupportNum} = $i + 1;
  }
  ## アーティファクト
  {
    my $i = 0;
    foreach my $name (@{$in{'item_name'}}){
      my $n = $i + 1;
      $pc{'artifact'.($n).'Name'}   = $name;
      $pc{'artifact'.($n).'Cost'}   = $in{'item_price'}[$i];
      $pc{'artifact'.($n).'Note'}   = $in{'item_memo'}[$i];
      $i++;
    }
    $pc{artifactNum} = $i + 1;
  }
  ## 履歴
  my $i = 0;
  foreach my $exp (@{$in{'get_exp_his'}}){
    $pc{'history'.($i+1).'Counts'}= "$in{'adv_exp_his'}[$i]+$in{'bns_exp_his'}[$i]";
    $pc{'history'.($i+1).'Counts'}=~ s/(^\+|\+$)//;
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    
    $i++;
  }
  $pc{historyNum} = $i;
  $pc{history0Exp} = 0;
  
  ## プロフィール追加
  my $profile;
  $profile .= ": 髪 |$in{'color_hair'}\n";
  $profile .= ": 瞳 |$in{'color_eye'}\n";
  $profile .= ": 肌 |$in{'color_skin'}\n";
  
  $pc{freeNote} = $profile.$in{'pc_making_memo'};
  $pc{freeNoteView} = (unescapeTags unescapeTagsLines $profile).$in{'pc_making_memo'};
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