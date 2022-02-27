################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

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
  ## キャラクターシート倉庫
  if($set_url =~ m"^https?://character-sheets\.appspot\.com/dx3/edit.html"){
    $set_url =~ s/edit\.html\?/display\?ajax=1&/;
    my $data = urlDataGet($set_url) or error 'キャラクターシート倉庫のデータが取得できませんでした';
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };
    
    return convertSoukoToYtsheet(\%in);
  }
  ## 旧ゆとシート
  {
    foreach my $url (keys %set::convert_url){
      if($set_url =~ s"^${url}data/(.*?).html"$1"){
        open my $IN, '<', "$set::convert_url{$url}data/${set_url}.cgi" or error '旧ゆとシートのデータが開けませんでした';
        my %pc;
        $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
        close($IN);
        
        return convert1to2(\%pc);
      }
    }
  }
  ## ゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
    my %pc = %{ decode_json(join '', $data) };
    if($pc{'result'} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{'convertSource'} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{'result'}) {
      error 'コンバート元のゆとシートⅡでエラーがありました<br>>'.$pc{'result'};
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
    'convertSource' => 'キャラクター保管所',
    'tags' => convertTags($in{'pc_tags'}),
    'age' => $in{'age'},
    'gender' => $in{'sex'},
    'height' => $in{'pc_height'},
    'weight' => $in{'pc_weight'},
    'works' => $in{'works_name'},
    'cover' => $in{'cover_name'},
    'syndrome1' => $in{'class1_name'},
    'syndrome2' => $in{'class2_name'} eq $in{'class1_name'} ? '' : $in{'class2_name'},
    'syndrome3' => $in{'class3_name'},
    'sttWorks' => $in{'SW1'}?'body' : $in{'SW2'}?'sense' : $in{'SW3'}?'mind': $in{'SW1'}?'social' : '',
    'sttGrowBody'   => $in{'SA1'}+$in{'BP1'},
    'sttGrowSense'  => $in{'SA2'}+$in{'BP2'},
    'sttGrowMind'   => $in{'SA3'}+$in{'BP3'},
    'sttGrowSocial' => $in{'SA4'}+$in{'BP4'},
    'sttAddBody'    => $in{'TM1'},
    'sttAddSense'   => $in{'TM2'},
    'sttAddMind'    => $in{'TM3'},
    'sttAddSocial'  => $in{'TM4'},
    'maxHpAdd' => $in{'TM5'},
    'lifepathOtherEncroach' => $in{'TM6'},
    'initiativeAdd' => $in{'TM7'},
    'moveAdd' => $in{'TM8'},
    'lifepathOrigin'     => $in{'shutuji_name'}, 'lifepathOriginNote'     => $in{'shutuji_sonota'},
    'lifepathExperience' => $in{'keiken_name'},  'lifepathExperienceNote' => $in{'keiken_sonota'},
    'lifepathEncounter'  => $in{'kaikou_name'},  'lifepathEncounterNote'  => $in{'kaikou_sonota'},
    'lifepathAwaken'     => $in{'birth_name'},   'lifepathAwakenNote'     => $in{'birth_sonota'},
    'lifepathImpulse'    => $in{'think_name'},   'lifepathImpulseNote'    => $in{'think_sonota'},
    'skillMelee'     => $in{'skill_tokugi'}[ 0], 'skillAddMelee'     => $in{'skill_sonota'}[ 0],
    'skillDodge'     => $in{'skill_tokugi'}[ 1], 'skillAddDodge'     => $in{'skill_sonota'}[ 1],
    'skillRide1'     => $in{'skill_tokugi'}[ 2], 'skillAddRide1'     => $in{'skill_sonota'}[ 2], 'skillRide1Name' => '運転:'.$in{'skill_memo'}[ 2],
    'skillRanged'    => $in{'skill_tokugi'}[ 3], 'skillAddRanged'    => $in{'skill_sonota'}[ 3],
    'skillPercept'   => $in{'skill_tokugi'}[ 4], 'skillAddPercept'   => $in{'skill_sonota'}[ 4],
    'skillArt1'      => $in{'skill_tokugi'}[ 5], 'skillAddArt1'      => $in{'skill_sonota'}[ 5], 'skillArt1Name'  => '芸術:'.$in{'skill_memo'}[ 5],
    'skillRC'        => $in{'skill_tokugi'}[ 6], 'skillAddRC'        => $in{'skill_sonota'}[ 6],
    'skillWill'      => $in{'skill_tokugi'}[ 7], 'skillAddWill'      => $in{'skill_sonota'}[ 7],
    'skillKnow1'     => $in{'skill_tokugi'}[ 8], 'skillAddKnow1'     => $in{'skill_sonota'}[ 8], 'skillKnow1Name' => '知識:'.$in{'skill_memo'}[ 8],
    'skillNegotiate' => $in{'skill_tokugi'}[ 9], 'skillAddNegotiate' => $in{'skill_sonota'}[ 9],
    'skillProcure'   => $in{'skill_tokugi'}[10], 'skillAddProcure'   => $in{'skill_sonota'}[10],
    'skillInfo1'     => $in{'skill_tokugi'}[11], 'skillAddInfo1'     => $in{'skill_sonota'}[11], 'skillInfo1Name' => '情報:'.$in{'skill_memo'}[11],
    '' => $in{''},
  );
  ##名前
  ($pc{'characterName'},$pc{'characterNameRuby'}) = convertNameRuby($in{'pc_name'} || $in{'data_title'});
  ($pc{'aka'},$pc{'akaRuby'}) = convertNameRuby($in{'pc_codename'});

  ## 技能
  my %skills = (1=>'Ride', 2=>'Art', 3=>'Know', 4=>'Info');
  my %skillsjp = (1=>'運転', 2=>'芸術', 3=>'知識', 4=>'情報');
  my $i = 12;
  foreach my $id (@{$in{'V_skill_id'}}){
    my $num = 2;
    while(1){
      if($pc{"skill$skills{$id}${num}"} eq '' && $pc{"skill$skills{$id}${num}Name"} eq ''){
        $pc{"skill$skills{$id}${num}"}     = $in{'skill_tokugi'}[$i];
        $pc{"skill$skills{$id}${num}Name"} = $skillsjp{$id}.':'.$in{'skill_memo'}[$i];
        last;
      }
      $num++;
    }
    $pc{"skill$skills{$id}Num"} = $num;
    $i++;
  }
  
  ## ロイス
  foreach my $i (1..7){
    $pc{"lois${i}Relation"} = $in{'roice_type'}[$i-1] == 1 ? 'Dロイス':'';
    $pc{"lois${i}Name"} = $in{'roice_name'}[$i-1];
    $pc{"lois${i}EmoPosi"} = $in{'roice_pos'}[$i-1];
    $pc{"lois${i}EmoNega"} = $in{'roice_neg'}[$i-1];
    $pc{"lois${i}Note"} = $in{'roice_memo'}[$i-1];
  }
  
  ## エフェクト
  ($pc{'effect1Type'},$pc{'effect1Name'},$pc{'effect1Lv'},$pc{'effect1Timing'},$pc{'effect1Skill'},$pc{'effect1Dfclty'},$pc{'effect1Target'},$pc{'effect1Range'},$pc{'effect1Encroach'},$pc{'effect1Restrict'},$pc{'effect1Note'})
    = ('auto','リザレクト',$in{'ressurect_lv'}+1,'オート','―','自動成功','自身','至近','効果参照','―','(Lv)D点HP回復、侵蝕値上昇');
  ($pc{'effect2Type'},$pc{'effect2Name'},$pc{'effect2Lv'},$pc{'effect2Timing'},$pc{'effect2Skill'},$pc{'effect2Dfclty'},$pc{'effect2Target'},$pc{'effect2Range'},$pc{'effect2Encroach'},$pc{'effect2Restrict'},$pc{'effect2Note'})
    = ('auto','ワーディング',1,'オート','―','自動成功','シーン','視界','0','―','非オーヴァードをエキストラ化');
  my $n = 3; my $i = 0;
  foreach my $name (@{$in{'effect_name'}}){
    $pc{'effect'.($n).'Name'} = $name;
    $pc{'effect'.($n).'Lv'} = convertEffectLv($in{'effect_lv'}[$i]);
    $pc{'effect'.($n).'Timing'}   = convertTiming($in{'effect_timing'}[$i]);
    $pc{'effect'.($n).'Skill'}    = $in{'effect_shozoku'}[$i];
    $pc{'effect'.($n).'Dfclty'}   = $in{'effect_hantei'}[$i];
    $pc{'effect'.($n).'Target'}   = $in{'effect_taisho'}[$i];
    $pc{'effect'.($n).'Range'}    = $in{'effect_range'}[$i];
    $pc{'effect'.($n).'Encroach'} = $in{'effect_cost'}[$i];
    $pc{'effect'.($n).'Restrict'} = $in{'effect_page'}[$i];
    $pc{'effect'.($n).'Note'}     = $in{'effect_memo'}[$i];
    $n++; $i++;
  }
  my $i = 0;
  foreach my $name (@{$in{'easyeffect_name'}}){
    $pc{'effect'.($n).'Type'} = 'easy';
    $pc{'effect'.($n).'Name'} = $name;
    $pc{'effect'.($n).'Lv'} = convertEffectLv($in{'easyeffect_lv'}[$i]);
    $pc{'effect'.($n).'Timing'}   = convertTiming($in{'easyeffect_timing'}[$i]);
    $pc{'effect'.($n).'Skill'}    = $in{'easyeffect_shozoku'}[$i];
    $pc{'effect'.($n).'Dfclty'}   = $in{'easyeffect_hantei'}[$i];
    $pc{'effect'.($n).'Target'}   = $in{'easyeffect_taisho'}[$i];
    $pc{'effect'.($n).'Range'}    = $in{'easyeffect_range'}[$i];
    $pc{'effect'.($n).'Encroach'} = $in{'easyeffect_cost'}[$i];
    $pc{'effect'.($n).'Restrict'} = $in{'easyeffect_page'}[$i];
    $pc{'effect'.($n).'Note'}     = $in{'easyeffect_memo'}[$i];
    $n++; $i++;
  }
  $pc{'effectNum'} = $n-1;
  sub convertEffectLv {
    my $lv = shift;
    if   ($lv > 9) { return $lv - 10; }
    elsif($lv > 5) { return $lv -  6; }
    elsif($lv < 1) { return 1; }
    return $lv;
  }
  
  ## コンボ・武器
  my @weapon_skill = ('', '白兵', '射撃', 'RC', '運転', '交渉');
  my @combo_status = ('', '肉体', '感覚', '精神', '社会');
  my $i = 0; my $w = 1;
  foreach my $name (@{$in{'arms_name'}}){
    my ($cost, $crit);
    $in{'arms_sonota'}[$i] =~ s/[侵浸コ][蝕食ス][率値ト]?([0-9]+\+?[0-9]?D?)/$cost = $1;''/e;
    $in{'arms_sonota'}[$i] =~ s/C値([0-9]+)|クリテ?ィ?カ?ル?値?([0-9]+)/$crit = $1;''/e;
    my($acc, $fixed) = split(/r\+?-?/, $in{'arms_hit'}[$i]);
    ## 武器
    if($in{'arms_price'}[$i] || $in{'arms_guard_level'}[$i]){
      $pc{'weapon'.($w).'Name'}  = $name;
      $pc{'weapon'.($w).'Stock'} = $in{'arms_price'}[$i];
      $pc{'weapon'.($w).'Skill'} = $weapon_skill[ $in{'arms_hit_param'}[$i] ];
      $pc{'weapon'.($w).'Acc'}   = $acc;
      $pc{'weapon'.($w).'Atk'}   = $in{'arms_power'}[$i];
      $pc{'weapon'.($w).'Guard'} = $in{'arms_guard_level'}[$i];
      $pc{'weapon'.($w).'Range'} = $in{'arms_range'}[$i];
      $w++;
    }
    ## コンボ
    $pc{'combo'.($i+1).'Name'} = $name;
    $pc{'combo'.($i+1).'Timing'}   = '';
    $pc{'combo'.($i+1).'Skill'}    = $weapon_skill[ $in{'arms_hit_param'}[$i] ];
    $pc{'combo'.($i+1).'Stt'}      = $combo_status[ $in{'V_arms_hit_status'}[$i] ];
    $pc{'combo'.($i+1).'Dfclty'}   = '';
    $pc{'combo'.($i+1).'Target'}   = '';
    $pc{'combo'.($i+1).'Range'}    = $in{'arms_range'}[$i];
    $pc{'combo'.($i+1).'Encroach'} = $cost;
    $pc{'combo'.($i+1).'DiceAdd1'} = $in{'arms_hit_dice_mod'}[$i];
    $pc{'combo'.($i+1).'Dice1'}    = $acc;
    $pc{'combo'.($i+1).'Crit1'}    = $crit;
    $pc{'combo'.($i+1).'FixedAdd1'}= $in{'arms_hit_mod'}[$i];
    $pc{'combo'.($i+1).'Fixed1'}   = $fixed;
    $pc{'combo'.($i+1).'Atk1'}     = $in{'arms_power'}[$i];
    $pc{'combo'.($i+1).'Note'}     = $in{'arms_sonota'}[$i];
    $pc{'combo'.($i+1).'Condition1'} = '100%未満';
    $pc{'combo'.($i+1).'Condition2'} = '100%以上';
    $i++;
  }
  $pc{'comboNum'} = $i;
  $pc{'weaponNum'} = $w-1;
  ## 防具
  $pc{'armorNum'} = 1;
  if($in{'armer_name'}){
    $pc{'armor1Name'} = $in{'armer_name'};
    $pc{'armor1Type'} = '防具';
    $pc{'armor1Stock'}      = $in{'armer_price'};
    $pc{'armor1Initiative'} = $in{'armer_move'};
    $pc{'armor1Dodge'}      = $in{'armer_dodge'};
    $pc{'armor1Armor'}      = $in{'armer_def'};
    $pc{'armor1Note'}       = $in{'armer_sonota'};
  }
  if($in{'armer2_name'}){
    $pc{'armor2Name'} = $in{'armer2_name'};
    $pc{'armor2Type'} = '防具';
    $pc{'armor2Stock'}      = $in{'armer2_price'};
    $pc{'armor2Initiative'} = $in{'armer2_move'};
    $pc{'armor2Dodge'}      = $in{'armer2_dodge'};
    $pc{'armor2Armor'}      = $in{'armer2_def'};
    $pc{'armor2Note'}       = $in{'armer2_sonota'};
    $pc{'armorNum'} = 2;
  }
  ## アイテム
  my $i = 0;
  foreach my $name (@{$in{'item_name'}}){
    $pc{'item'.($i+1).'Name'} = $name;
    $pc{'item'.($i+1).'Stock'} = $in{'item_price'}[$i];
    $pc{'item'.($i+1).'Note'}  = $in{'item_memo'}[$i];
    $i++;
  }
  $pc{'itemNum'} = $i;
  ## 履歴
  my $i = 0;
  foreach my $exp (@{$in{'get_exp_his'}}){
    $pc{'history'.($i+1).'Exp'}   = $exp;
    $pc{'history'.($i+1).'ExpApply'} = 1 if $exp;
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    $i++;
  }
  $pc{'historyNum'} = $i;
  $pc{'history0Exp'} = $in{'sum_seichoten_default'};
  
  ## プロフィール追加
  my $profile;
  $profile .= ": 髪 |$in{'color_hair'}\n";
  $profile .= ": 瞳 |$in{'color_eye'}\n";
  $profile .= ": 肌 |$in{'color_skin'}\n";
  
  $pc{'freeNote'} = $profile.$in{'pc_making_memo'};
  $pc{'freeNoteView'} = (tag_unescape tag_unescape_lines $profile).$in{'pc_making_memo'};
  $pc{'freeNoteView'} =~ s/\r\n?|\n/<br>/g;
  
  ## 〆
  $pc{'ver'} = 0;
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
### キャラクターシート倉庫 --------------------------------------------------
sub convertSoukoToYtsheet {
  my %in = %{$_[0]};
  ## 単純変換
  (my $aka = $in{'base'}{'nameKana'}) =~ s/^["“”](.*)["“”]$/$1/;
  my %pc = (
    'convertSource' => 'キャラクターシート倉庫',
    
    'playerName' => $in{'base'}{'player'},
    
    'age' => $in{'base'}{'age'},
    'gender' => $in{'base'}{'sex'},
    'height' => $in{'base'}{'Height'},
    'weight' => $in{'base'}{'weight'},
    'sign' => $in{'base'}{'zodiac'},
    'blood' => $in{'base'}{'blood'},
    'works' => $in{'base'}{'works'},
    'cover' => $in{'base'}{'cover'},
    'syndrome1' => $in{'base'}{'syndromes'}{'primary'}{'syndrome'},
    'syndrome2' => $in{'base'}{'syndromes'}{'secondary'}{'syndrome'},
    'syndrome3' => $in{'base'}{'syndromes'}{'tertiary'}{'syndrome'},
    'sttWorks' => $in{'baseAbility'}{'body'   }{'selected'} ? 'body'
                : $in{'baseAbility'}{'sense'  }{'selected'} ? 'sense'
                : $in{'baseAbility'}{'mind'   }{'selected'} ? 'mind'
                : $in{'baseAbility'}{'society'}{'selected'} ? 'social'
                : '',
    'sttGrowBody'   => $in{'baseAbility'}{'body'   }{'growth'},
    'sttGrowSense'  => $in{'baseAbility'}{'sense'  }{'growth'},
    'sttGrowMind'   => $in{'baseAbility'}{'mind'   }{'growth'},
    'sttGrowSocial' => $in{'baseAbility'}{'society'}{'growth'},
    'sttAddBody'    => $in{'baseAbility'}{'body'   }{'descript'}+$in{'baseAbility'}{'body'   }{'free'}||'',
    'sttAddSense'   => $in{'baseAbility'}{'sense'  }{'descript'}+$in{'baseAbility'}{'sense'  }{'free'}||'',
    'sttAddMind'    => $in{'baseAbility'}{'mind'   }{'descript'}+$in{'baseAbility'}{'mind'   }{'free'}||'',
    'sttAddSocial'  => $in{'baseAbility'}{'society'}{'descript'}+$in{'baseAbility'}{'society'}{'free'}||'',
    'maxHpAdd'      => $in{'subAbility'}{'hp'      }{'correct'},
    'stockAdd'      => $in{'subAbility'}{'standing'}{'correct'},
    'savingAdd'     => $in{'subAbility'}{'property'}{'correct'},
    'initiativeAdd' => $in{'subAbility'}{'action'  }{'correct'},
    'moveAdd'       => $in{'subAbility'}{'moveSen' }{'correct'},
    'dashAdd'       => $in{'subAbility'}{'moveZen' }{'correct'},
    'lifepathOrigin'         => $in{'lifepath'}{'origins'}{'name'},
    'lifepathOriginNote'     => $in{'lifepath'}{'origins'}{'rois'}.'／'.$in{'lifepath'}{'origins'}{'txt'},
    'lifepathExperience'     => $in{'lifepath'}{'experience'}{'name'},
    'lifepathExperienceNote' => $in{'lifepath'}{'experience'}{'rois'}.'／'.$in{'lifepath'}{'experience'}{'txt'},
    'lifepathEncounter'      => $in{'lifepath'}{'encounter'}{'name'},
    'lifepathEncounterNote'  => $in{'lifepath'}{'encounter'}{'rois'}.'／'.$in{'lifepath'}{'encounter'}{'txt'},
    'lifepathAwaken'         => $in{'lifepath'}{'arousal'}{'name'},
    'lifepathImpulse'        => $in{'lifepath'}{'impulse'}{'name'},
    'lifepathOtherEncroach'  => $in{'subAbility'}{'erotion'}{'correct'},
    'skillMelee'     => $in{'skills'}{'hak'}{'A'}{'lv'},
    'skillDodge'     => $in{'skills'}{'kai'}{'A'}{'lv'},
    'skillRanged'    => $in{'skills'}{'sha'}{'A'}{'lv'},
    'skillPercept'   => $in{'skills'}{'tik'}{'A'}{'lv'},
    'skillRC'        => $in{'skills'}{'rc' }{'A'}{'lv'},
    'skillWill'      => $in{'skills'}{'isi'}{'A'}{'lv'},
    'skillNegotiate' => $in{'skills'}{'kou'}{'A'}{'lv'},
    'skillProcure'   => $in{'skills'}{'tyo'}{'A'}{'lv'},
    'skillAddMelee'     => $in{'skills'}{'hak'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'hak'}{'D'}{'dlv'} - $in{'skills'}{'hak'}{'A'}{'lv'} : '',
    'skillAddDodge'     => $in{'skills'}{'kai'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'kai'}{'D'}{'dlv'} - $in{'skills'}{'kai'}{'A'}{'lv'} : '',
    'skillAddRanged'    => $in{'skills'}{'sha'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'sha'}{'D'}{'dlv'} - $in{'skills'}{'sha'}{'A'}{'lv'} : '',
    'skillAddPercept'   => $in{'skills'}{'tik'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'tik'}{'D'}{'dlv'} - $in{'skills'}{'tik'}{'A'}{'lv'} : '',
    'skillAddRC'        => $in{'skills'}{'rc' }{'D'}{'dlv'} ne '' ? $in{'skills'}{'rc' }{'D'}{'dlv'} - $in{'skills'}{'rc' }{'A'}{'lv'} : '',
    'skillAddWill'      => $in{'skills'}{'isi'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'isi'}{'D'}{'dlv'} - $in{'skills'}{'isi'}{'A'}{'lv'} : '',
    'skillAddNegotiate' => $in{'skills'}{'kou'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'kou'}{'D'}{'dlv'} - $in{'skills'}{'kou'}{'A'}{'lv'} : '',
    'skillAddProcure'   => $in{'skills'}{'tyo'}{'D'}{'dlv'} ne '' ? $in{'skills'}{'tyo'}{'D'}{'dlv'} - $in{'skills'}{'tyo'}{'A'}{'lv'} : '',
    'freeNote' => $in{'base'}{'memo'},
  );
  ##名前
  ($pc{'characterName'},$pc{'characterNameRuby'}) = convertNameRuby($in{'base'}{'name'});
  ($pc{'aka'},$pc{'akaRuby'}) = convertNameRuby($aka);
  ## シンドローム
  foreach my $i (1 .. 3){
    $pc{'syndrome'.$i} =~ s/ハ[イィ]ロ[ウゥ]/ハィロゥ/;
  }
  ## 技能
  my $i = 1;
  foreach (@{$in{'skills'}{'B'}}){
    $pc{'skillRide'.$i.'Name'} = @$_{'name1'} ? '運転:'.@$_{'name1'} : '';
    $pc{'skillArt' .$i.'Name'} = @$_{'name2'} ? '芸術:'.@$_{'name2'} : '';
    $pc{'skillKnow'.$i.'Name'} = @$_{'name3'} ? '知識:'.@$_{'name3'} : '';
    $pc{'skillInfo'.$i.'Name'} = @$_{'name4'} ? '情報:'.@$_{'name4'} : '';
    $pc{'skillRide'.$i} = @$_{'lv1'};
    $pc{'skillArt' .$i} = @$_{'lv2'};
    $pc{'skillKnow'.$i} = @$_{'lv3'};
    $pc{'skillInfo'.$i} = @$_{'lv4'};
    $pc{'skillAddRide'.$i} = @$_{'dlv1'} ne '' ? @$_{'dlv1'} - @$_{'lv1'} : '';
    $pc{'skillAddArt' .$i} = @$_{'dlv2'} ne '' ? @$_{'dlv2'} - @$_{'lv2'} : '';
    $pc{'skillAddKnow'.$i} = @$_{'dlv3'} ne '' ? @$_{'dlv3'} - @$_{'lv3'} : '';
    $pc{'skillAddInfo'.$i} = @$_{'dlv4'} ne '' ? @$_{'dlv4'} - @$_{'lv4'} : '';
    $i++;
  }
  $pc{'skillRideNum'} = $pc{'skillArtNum'} = $pc{'skillKnowNum'} = $pc{'skillInfoNum'} = $i-1;
  ## ロイス
  my $i = 1;
  foreach (@{$in{'lois'}}){
    @$_{'type'} =~ s/^[DＤ]$/Dロイス/;
    $pc{"lois${i}Relation"} = @$_{'type'};
    $pc{"lois${i}Name"}     = @$_{'name'};
    $pc{"lois${i}EmoPosi"}  = @$_{'Pfeel'}; $pc{"lois${i}EmoPosiCheck"} = @$_{'Pemotion'};
    $pc{"lois${i}EmoNega"}  = @$_{'Nfeel'}; $pc{"lois${i}EmoNegaCheck"} = @$_{'Nemotion'};
    $pc{"lois${i}Note"}     = @$_{'txt'};
    $pc{"lois${i}State"}    = @$_{'titus'} ? 'タイタス' : 'ロイス';
    $i++;
  }
  ## メモリー
  my $i = 1;
  foreach (@{$in{'memory'}}){
    $pc{"memory${i}Gain"}     = @$_{'check'};
    $pc{"memory${i}Relation"} = @$_{'type'};
    $pc{"memory${i}Name"}     = @$_{'name'};
    $pc{"memory${i}Emo"}      = @$_{'feel'};
    $pc{"memory${i}Note"}     = @$_{'txt'}.(@$_{'use'}?'[使用済]':'');
    $i++;
  }
  ## エフェクト
  my $i = 1;
  foreach (@{$in{'arts'}}){
    @$_{'name'} =~ s/\n/ /;
    $pc{"effect${i}Type"}     = @$_{'check'}==1?'auto' : @$_{'check'}==2?'dlois' : @$_{'check'}==3?'easy' : @$_{'check'}==5?'enemy' : '';
    $pc{"effect${i}Name"}     = @$_{'name'};
    $pc{"effect${i}Lv"}       = @$_{'level'};
    $pc{"effect${i}Timing"}   = convertTiming(@$_{'timing'});
    $pc{"effect${i}Skill"}    = @$_{'type'};
    $pc{"effect${i}Dfclty"}   = @$_{'judge'};
    $pc{"effect${i}Target"}   = @$_{'target'};
    $pc{"effect${i}Range"}    = @$_{'range'};
    $pc{"effect${i}Encroach"} = @$_{'cost'};
    $pc{"effect${i}Restrict"} = @$_{'limit'};
    $pc{"effect${i}Note"}     = @$_{'notes'};
    $i++;
  }
  $pc{'effectNum'} = $i-1;
  ## コンボ
  my $i = 1;
  $pc{'comboCalcOff'} = 1;
  foreach (@{$in{'combo'}}){
    my %un = %{@$_{'under100'}};
    my %ov = %{@$_{'over100'}};
    $pc{"combo${i}Name"}     = @$_{'name'};
    $pc{"combo${i}Combo"}    = $un{'combination'} && $ov{'combination'} && $un{'combination'} ne $ov{'combination'} ? "$un{'combination'}／$ov{'combination'}"
                             : $un{'combination'} ? $un{'combination'} : $ov{'combination'};
    $pc{"combo${i}Timing"}   = $un{'timing'} && $ov{'timing'} && $un{'timing'} ne $ov{'timing'} ? "$un{'timing'}／$ov{'timing'}"
                             : $un{'timing'} ? $un{'timing'} : $ov{'timing'};
    $pc{"combo${i}Skill"}    = $un{'type'} && $ov{'type'} && $un{'type'} ne $ov{'type'} ? "$un{'type'}／$ov{'type'}"
                             : $un{'type'} ? $un{'type'} : $ov{'type'};
    $pc{"combo${i}Dfclty"}   = $un{'judge'} && $ov{'judge'} && $un{'judge'} ne $ov{'judge'} ? "$un{'judge'}／$ov{'judge'}"
                             : $un{'judge'} ? $un{'judge'} : $ov{'judge'};
    $pc{"combo${i}Target"}   = $un{'target'} && $ov{'target'} && $un{'target'} ne $ov{'target'} ? "$un{'target'}／$ov{'target'}"
                             : $un{'target'} ? $un{'target'} : $ov{'target'};
    $pc{"combo${i}Range"}    = $un{'range'} && $ov{'range'} && $un{'range'} ne $ov{'range'} ? "$un{'range'}／$ov{'range'}"
                             : $un{'range'} ? $un{'range'} : $ov{'range'};
    $pc{"combo${i}Encroach"} = $un{'cost'} && $ov{'cost'} && $un{'cost'} ne $ov{'cost'} ? "$un{'cost'}／$ov{'cost'}"
                             : $un{'cost'} ? $un{'cost'} : $ov{'cost'};
    $pc{"combo${i}DiceAdd1"} = $un{'dice'};
    $pc{"combo${i}Crit1"}    = $un{'critical'};
    $pc{"combo${i}Atk1"}     = $un{'attack'};
    $pc{"combo${i}DiceAdd2"} = $ov{'dice'};
    $pc{"combo${i}Crit2"}    = $ov{'critical'};
    $pc{"combo${i}Atk2"}     = $ov{'attack'};
    $pc{"combo${i}Note"}     = $un{'notes'} && $ov{'notes'} && $un{'notes'} ne $ov{'notes'} ? "$un{'notes'}／$ov{'notes'}"
                             : $un{'notes'} ? $un{'notes'} : $ov{'notes'};
    $pc{"combo${i}Condition1"} = '100%未満';
    $pc{"combo${i}Condition2"} = '100%以上';
    $i++;
  }
  $pc{'comboNum'} = $i-1;
  ## 武器
  my $i = 1;
  foreach (@{$in{'weapons'}}){
    $pc{"weapon${i}Name"}     = @$_{'name'};
    $pc{"weapon${i}Stock"}    = @$_{'standing'};
    $pc{"weapon${i}Exp"}      = @$_{'exp'};
    $pc{"weapon${i}Type"}     = @$_{'type'};
    $pc{"weapon${i}Skill"}    = @$_{'skill'};
    $pc{"weapon${i}Acc"}      = @$_{'judge'};
    $pc{"weapon${i}Atk"}      = @$_{'attack'};
    $pc{"weapon${i}Guard"}    = @$_{'guard'};
    $pc{"weapon${i}Range"}    = @$_{'range'};
    $pc{"weapon${i}Note"}     = @$_{'notes'};
    $i++;
  }
  $pc{'weaponNum'} = $i-1;
  ## 防具
  my $i = 1;
  foreach (@{$in{'armours'}}){
    $pc{"armor${i}Name"}       = @$_{'name'};
    $pc{"armor${i}Stock"}      = @$_{'standing'};
    $pc{"armor${i}Exp"}        = @$_{'exp'};
    $pc{"armor${i}Type"}       = @$_{'type'};
    $pc{"armor${i}Initiative"} = @$_{'action'};
    $pc{"armor${i}Dodge"}      = @$_{'dodge'};
    $pc{"armor${i}Armor"}      = @$_{'armour'};
    $pc{"armor${i}Note"}       = @$_{'notes'};
    $i++;
  }
  $pc{'armorNum'} = $i-1;
  ## アイテム
  my $i = 1;
  foreach (@{$in{'items'}}){
    $pc{"item${i}Name"}       = @$_{'name'};
    $pc{"item${i}Stock"}      = @$_{'standing'};
    $pc{"item${i}Exp"}        = @$_{'exp'};
    $pc{"item${i}Type"}       = @$_{'type'};
    $pc{"item${i}Skill"}      = @$_{'skill'};
    $pc{"item${i}Note"}       = @$_{'notes'};
    $i++;
  }
  $pc{'itemNum'} = $i-1;
  ## 履歴
  $pc{'history0Exp'} = 130;
  $pc{'history1Title'} = '追加経験点';
  $pc{'history1Exp'} = $in{'exp'}{'acquire'};
  $pc{'historyNum'} = 3;
  ## 〆
  $pc{'ver'} = 0;
  return %pc;
}
### 旧ゆとシート => ゆとシートⅡ --------------------------------------------------
sub convert1to2 {
  my %pc = %{$_[0]};
  $pc{'convertSource'} = '旧ゆとシート';
  
  $pc{'playerName'} = $pc{'player'};
  
  $pc{'characterName'} = $pc{'name'};
  $pc{'aka'} = $pc{'codename'};
  $pc{'words'} = $pc{'word'};
  
  $pc{'tags'} = $pc{'tag'};
  
  $pc{'age'}      = $pc{'prof_age'};
  $pc{'gender'}   = $pc{'prof_sex'};
  $pc{'height'}   = $pc{'prof_height'};
  $pc{'weight'}   = $pc{'prof_weight'};
  $pc{'sign'}     = $pc{'prof_sign'};
  $pc{'blood'}    = $pc{'prof_blood'};
  
  $pc{'sttWorks'}      = $pc{'stt_works'};
  $pc{'sttWorks'} =~ s/spirit/mind/;
  $pc{'sttGrowBody'}   = $pc{'stt_grow_body'};
  $pc{'sttGrowSense'}  = $pc{'stt_grow_sense'};
  $pc{'sttGrowMind'}   = $pc{'stt_grow_spirit'};
  $pc{'sttGrowSocial'} = $pc{'stt_grow_social'};
  $pc{'sttAddBody'}   = $pc{'stt_add_body'};
  $pc{'sttAddSense'}  = $pc{'stt_add_sense'};
  $pc{'sttAddMind'}   = $pc{'stt_add_spirit'};
  $pc{'sttAddSocial'} = $pc{'stt_add_social'};
  
  $pc{'maxHpAdd'} = $pc{'sub_hp_add'};
  $pc{'stockAdd'} = $pc{'sub_provide_add'};
  $pc{'initiativeAdd'} = $pc{'sub_speed_add'};
  $pc{'moveAdd'} = $pc{'sub_move_add'};
  
  $pc{'skillMelee'}     = $pc{'skill_fight_lv'};
  $pc{'skillRanged'}    = $pc{'skill_shoot_lv'};
  $pc{'skillRC'}        = $pc{'skill_RC_lv'};
  $pc{'skillNegotiate'} = $pc{'skill_nego_lv'};
  $pc{'skillDodge'}     = $pc{'skill_dodge_lv'};
  $pc{'skillPercept'}   = $pc{'skill_perce_lv'};
  $pc{'skillWill'}      = $pc{'skill_will_lv'};
  $pc{'skillProcure'}   = $pc{'skill_raise_lv'};
  
  $pc{'skillRideNum'} = $pc{'skillArtNum'} = $pc{'skillKnowNum'} = $pc{'skillInfoNum'} = $pc{'count_skill'};
  foreach my $num (1 .. $pc{'count_skill'}){
    $pc{"skillRide${num}Name"} = '運転:'.$pc{"skill_drive${num}_name"}; $pc{"skillRide${num}"} = $pc{"skill_drive${num}_lv"};
    $pc{"skillArt${num}Name" } = '芸術:'.$pc{"skill_art${num}_name"  }; $pc{"skillArt${num}" } = $pc{"skill_art${num}_lv"  };
    $pc{"skillKnow${num}Name"} = '知識:'.$pc{"skill_know${num}_name" }; $pc{"skillKnow${num}"} = $pc{"skill_know${num}_lv" };
    $pc{"skillInfo${num}Name"} = '情報:'.$pc{"skill_info${num}_name" }; $pc{"skillInfo${num}"} = $pc{"skill_info${num}_lv" };
  }
  
  $pc{'lifepathOrigin'}     = $pc{'lifepath_birth'};
  $pc{'lifepathOriginNote'} = $pc{'lifepath_birth_note'};
  $pc{'lifepathExperience'} = $pc{'lifepath_exp'};
  $pc{'lifepathExperienceNote'} = $pc{'lifepath_exp_note'};
  $pc{'lifepathEncounter'}      = $pc{'lifepath_meet'};
  $pc{'lifepathEncounterNote'}  = $pc{'lifepath_meet_note'};
  $pc{'lifepathAwaken'}          = $pc{'lifepath_awaken'};
  $pc{'lifepathAwakenEncroach'}  = $pc{'lifepath_awaken_invade'};
  $pc{'lifepathAwakenNote'}      = $pc{'lifepath_awaken_note'};
  $pc{'lifepathImpulse'}         = $pc{'lifepath_urge'};
  $pc{'lifepathImpulseEncroach'} = $pc{'lifepath_urge_invade'};
  $pc{'lifepathImpulseNote'}     = $pc{'lifepath_urge_note'};
  $pc{'lifepathOtherEncroach'} = $pc{'lifepath_other_invade'};
  $pc{'lifepathOtherNote'}     = $pc{'lifepath_other_note'};
  
  foreach my $num (1 .. 7) {
    $pc{"lois${num}Relation"}     = $pc{"lois${num}_relation"};
    $pc{"lois${num}Name"}         = $pc{"lois${num}_name"};
    $pc{"lois${num}EmoPosi"}      = $pc{"lois${num}_positive"};
    $pc{"lois${num}EmoNega"}      = $pc{"lois${num}_negative"};
    $pc{"lois${num}EmoPosiCheck"} = $pc{"lois${num}_check"} ne 'P' ? 1 : 0;
    $pc{"lois${num}EmoNegaCheck"} = $pc{"lois${num}_check"} ne 'N' ? 1 : 0;
    $pc{"lois${num}Note"}         = $pc{"lois${num}_note"};
    $pc{"lois${num}State"}        = $pc{"lois${num}_titus"} ? 'タイタス' : '';
  }
  foreach my $num (1 .. 3) {
    $pc{"memory${num}Relation"} = $pc{"memory${num}_relation"};
    $pc{"memory${num}Name"}     = $pc{"memory${num}_name"};
    $pc{"memory${num}Emo"}      = $pc{"memory${num}_emotion"};
    $pc{"memory${num}Note"}     = $pc{"memory${num}_note"};
    $pc{"memory${num}State"}    = $pc{"memory${num}_titus"} ? 'タイタス' : '';
  }
  
  $pc{'effectNum'} = $pc{'count_effect'}+2;
  my $i = 1;
  foreach my $num (3 .. $pc{'effectNum'}) {
    $pc{"effect${num}Name"}     = $pc{"effect${i}_name"};
    $pc{"effect${num}Lv"}       = $pc{"effect${i}_lv"};
    $pc{"effect${num}Timing"}   = $pc{"effect${i}_timing"};
    $pc{"effect${num}Skill"}    = $pc{"effect${i}_skill"};
    $pc{"effect${num}Dfclty"}   = $pc{"effect${i}_diffi"};
    $pc{"effect${num}Target"}   = $pc{"effect${i}_target"};
    $pc{"effect${num}Range"}    = $pc{"effect${i}_range"};
    $pc{"effect${num}Encroach"} = $pc{"effect${i}_point"};
    $pc{"effect${num}Restrict"} = $pc{"effect${i}_limit"};
    $pc{"effect${num}Note"}     = $pc{"effect${i}_note"};
    $i++;
  }
  my $i = 1;
  foreach my $num ($pc{'effectNum'}+1 .. $pc{'effectNum'}+$pc{'count_effect_ez'}) {
    $pc{"effect${num}Type"}     = 'easy';
    $pc{"effect${num}Name"}     = $pc{"effect_ez${i}_name"};
    $pc{"effect${num}Lv"}       = $pc{"effect_ez${i}_lv"};
    $pc{"effect${num}Timing"}   = $pc{"effect_ez${i}_timing"};
    $pc{"effect${num}Skill"}    = $pc{"effect_ez${i}_skill"};
    $pc{"effect${num}Dfclty"}   = $pc{"effect_ez${i}_diffi"};
    $pc{"effect${num}Target"}   = $pc{"effect_ez${i}_target"};
    $pc{"effect${num}Range"}    = $pc{"effect_ez${i}_range"};
    $pc{"effect${num}Encroach"} = $pc{"effect_ez${i}_point"};
    $pc{"effect${num}Restrict"} = $pc{"effect_ez${i}_limit"};
    $pc{"effect${num}Note"}     = $pc{"effect_ez${i}_note"};
    $i++;
  }
  $pc{'effectNum'} += $pc{'count_effect_ez'};
  
  $pc{'comboNum'} = $pc{'count_combo'};
  foreach my $num (1 .. $pc{'comboNum'}) {
    $pc{"combo${num}Name"}     = $pc{"combo${num}_name"};
    $pc{"combo${num}Combo"}    = $pc{"combo${num}_set"};
    $pc{"combo${num}Timing"}   = $pc{"combo${num}_timing"};
    $pc{"combo${num}Skill"}    = $pc{"combo${num}_skill"};
    $pc{"combo${num}Dfclty"}   = $pc{"combo${num}_diffi"};
    $pc{"combo${num}Target"}   = $pc{"combo${num}_target"};
    $pc{"combo${num}Range"}    = $pc{"combo${num}_range"};
    $pc{"combo${num}Encroach"} = $pc{"combo${num}_point"};
    $pc{"combo${num}Restrict"} = $pc{"combo${num}_limit"};
    $pc{"combo${num}Note"}     = $pc{"combo${num}_note"};
    $pc{"combo${num}Condition1"}  = '100%未満';
    $pc{"combo${num}Dice1"}       = $pc{"combo${num}_under_dice"};
    $pc{"combo${num}Crit1"}       = $pc{"combo${num}_under_crit"};
    $pc{"combo${num}Atk1"}        = $pc{"combo${num}_under_power"};
    $pc{"combo${num}Condition2"}  = '100%以上';
    $pc{"combo${num}Dice2"}       = $pc{"combo${num}_over_dice"};
    $pc{"combo${num}Crit2"}       = $pc{"combo${num}_over_crit"};
    $pc{"combo${num}Atk2"}        = $pc{"combo${num}_over_power"};
  }
  
  $pc{'weaponNum'} = $pc{'count_weapon'};
  foreach my $num (1 .. $pc{'weaponNum'}) {
    $pc{"weapon${num}Name"}  = $pc{"weapon${num}_name"};
    $pc{"weapon${num}Stock"} = $pc{"weapon${num}_point"};
    $pc{"weapon${num}Exp"}   = $pc{"weapon${num}_exp"};
    $pc{"weapon${num}Type"}  = $pc{"weapon${num}_type"};
    $pc{"weapon${num}Skill"} = $pc{"weapon${num}_skill"};
    $pc{"weapon${num}Acc"}   = $pc{"weapon${num}_hit"};
    $pc{"weapon${num}Atk"}   = $pc{"weapon${num}_power"};
    $pc{"weapon${num}Guard"} = $pc{"weapon${num}_guard"};
    $pc{"weapon${num}Range"} = $pc{"weapon${num}_range"};
    $pc{"weapon${num}Note"}  = $pc{"weapon${num}_note"};
  }
  $pc{'armorNum'} = $pc{'count_armour'};
  foreach my $num (1 .. $pc{'armorNum'}) {
    $pc{"armor${num}Name"}       = $pc{"armor${num}_name"};
    $pc{"armor${num}Stock"}      = $pc{"armor${num}_point"};
    $pc{"armor${num}Exp"}        = $pc{"armor${num}_exp"};
    $pc{"armor${num}Type"}       = $pc{"armor${num}_type"};
    $pc{"armor${num}Initiative"} = $pc{"armor${num}_dodge"};
    $pc{"armor${num}Dodge"}      = $pc{"armor${num}_speed"};
    $pc{"armor${num}Armor"}      = $pc{"armor${num}_guard"};
    $pc{"armor${num}Note"}       = $pc{"armor${num}_note"};
  }
  $pc{'armorNum'} = $pc{'count_item'};
  foreach my $num (1 .. $pc{'armorNum'}) {
    $pc{"item${num}Name"}       = $pc{"item${num}_name"};
    $pc{"item${num}Stock"}      = $pc{"item${num}_point"};
    $pc{"item${num}Exp"}        = $pc{"item${num}_exp"};
    $pc{"item${num}Type"}       = $pc{"item${num}_type"};
    $pc{"item${num}Skill"}      = $pc{"item${num}_skill"};
    $pc{"item${num}Note"}       = $pc{"item${num}_note"};
  }
  
  $pc{'freeNote'} = $pc{'text_free'};
  $pc{'freeHistory'} = $pc{'text_history'};
  
  $pc{'historyNum'} = $pc{'count_history'};
  foreach my $num (1 .. $pc{'historyNum'}) {
    $pc{"history${num}Date"}       = $pc{"hist_date$num"};
    $pc{"history${num}Title"}      = $pc{"hist_name$num"};
    $pc{"history${num}Exp"}        = $pc{"hist_exp$num"};
    $pc{"history${num}Gm"}         = $pc{"hist_gm$num"};
    $pc{"history${num}Member"}     = $pc{"hist_member$num"};
  }
  $pc{"history0Exp"} = $pc{"make_exp"};
  
  $pc{'ver'} = 0;
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