################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

require $set::data_class;
require $set::data_races;

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
    'race' => $in{'shuzoku'} || $in{'manual_shuzoku'},
    'money' => ($in{'money'}),
    'classSupport' => $in{'support_class'},
    'classSupportLv1' => $in{'start_sub_class'},
    'level' => $in{'SL_level'},
    'sttStrRace' => $in{'S1'}+0 || '',
    'sttDexRace' => $in{'S2'}+0 || '',
    'sttAgiRace' => $in{'S3'}+0 || '',
    'sttIntRace' => $in{'S4'}+0 || '',
    'sttSenRace' => $in{'S5'}+0 || '',
    'sttMndRace' => $in{'S6'}+0 || '',
    'sttLukRace' => $in{'S7'}+0 || '',
    'sttStrMake' => $in{'BP1'}+0 || '',
    'sttDexMake' => $in{'BP2'}+0 || '',
    'sttAgiMake' => $in{'BP3'}+0 || '',
    'sttIntMake' => $in{'BP4'}+0 || '',
    'sttSenMake' => $in{'BP5'}+0 || '',
    'sttMndMake' => $in{'BP6'}+0 || '',
    'sttLukMake' => $in{'BP7'}+0 || '',
    'sttStrBaseAdd' => $in{'TM1'}+0 || '',
    'sttDexBaseAdd' => $in{'TM2'}+0 || '',
    'sttAgiBaseAdd' => $in{'TM3'}+0 || '',
    'sttIntBaseAdd' => $in{'TM4'}+0 || '',
    'sttSenBaseAdd' => $in{'TM5'}+0 || '',
    'sttMndBaseAdd' => $in{'TM6'}+0 || '',
    'sttLukBaseAdd' => $in{'TM7'}+0 || '',
    'sttStrGrow' => $in{'SA1'}+0 || '',
    'sttDexGrow' => $in{'SA2'}+0 || '',
    'sttAgiGrow' => $in{'SA3'}+0 || '',
    'sttIntGrow' => $in{'SA4'}+0 || '',
    'sttSenGrow' => $in{'SA5'}+0 || '',
    'sttMndGrow' => $in{'SA6'}+0 || '',
    'sttLukGrow' => $in{'SA7'}+0 || '',
    'sttStrBase' => $in{'NK1'}+0 || '',
    'sttDexBase' => $in{'NK2'}+0 || '',
    'sttAgiBase' => $in{'NK3'}+0 || '',
    'sttIntBase' => $in{'NK4'}+0 || '',
    'sttSenBase' => $in{'NK5'}+0 || '',
    'sttMndBase' => $in{'NK6'}+0 || '',
    'sttLukBase' => $in{'NK7'}+0 || '',
    'sttStrMain' => $in{'MC1'}+0 || '',
    'sttDexMain' => $in{'MC2'}+0 || '',
    'sttAgiMain' => $in{'MC3'}+0 || '',
    'sttIntMain' => $in{'MC4'}+0 || '',
    'sttSenMain' => $in{'MC5'}+0 || '',
    'sttMndMain' => $in{'MC6'}+0 || '',
    'sttLukMain' => $in{'MC7'}+0 || '',
    'sttStrSupport' => $in{'SC1'}+0 || '',
    'sttDexSupport' => $in{'SC2'}+0 || '',
    'sttAgiSupport' => $in{'SC3'}+0 || '',
    'sttIntSupport' => $in{'SC4'}+0 || '',
    'sttSenSupport' => $in{'SC5'}+0 || '',
    'sttMndSupport' => $in{'SC6'}+0 || '',
    'sttLukSupport' => $in{'SC7'}+0 || '',
    'sttStrAdd' => $in{'NM1'}+0 || '',
    'sttDexAdd' => $in{'NM2'}+0 || '',
    'sttAgiAdd' => $in{'NM3'}+0 || '',
    'sttIntAdd' => $in{'NM4'}+0 || '',
    'sttSenAdd' => $in{'NM5'}+0 || '',
    'sttMndAdd' => $in{'NM6'}+0 || '',
    'sttLukAdd' => $in{'NM7'}+0 || '',
    'rollStrDice' => 2,
    'rollDexDice' => 2,
    'rollAgiDice' => 2,
    'rollIntDice' => 2,
    'rollSenDice' => 2,
    'rollMndDice' => 2,
    'rollLukDice' => 2,
    'hpSupport' => $in{'SC8'}+0 || '',
    'mpSupport' => $in{'SC9'}+0 || '',
    'hpAdd' => $in{'TM8'} + $in{'NM8'},
    'mpAdd' => $in{'TM9'} + $in{'NM9'},
    'lifepathOrigin'     => $in{'shutuji_name'},
    'lifepathExperience' => $in{'kyougu_name'},
    'lifepathMotive'     => $in{'unmei_name'},
    'lifepathOriginNote'     => $in{'shutuji_memo'},
    'lifepathExperienceNote' => $in{'kyougu_memo'},
    'lifepathMotiveNote'     => $in{'unmei_memo'},
    'skill1Type'     => 'race',
    'skill1Name'     => $in{'shuzoku_skill_name'},
    'skill1Lv'       => 1,
    'skill1Timing'   => convertTiming($in{'shuzoku_skill_timing'}),
    'skill1Roll'     => $in{'shuzoku_skill_hantei'},
    'skill1Target'   => $in{'shuzoku_skill_taisho'},
    'skill1Range'    => $in{'shuzoku_skill_range'},
    'skill1Reqd'     => $in{'shuzoku_skill_cost'},
    'skill1Cost'     => $in{'shuzoku_skill_cost'},
    'skill1Note'     => $in{'shuzoku_skill_memo'},
    'skill2Type'     => $in{'m_cls_skill_shozoku'},
    'skill2Name'     => $in{'m_cls_skill_name'},
    'skill2Lv'       => convertSkillLv($in{'V_mcls_skill_lv'}),
    'skill2Timing'   => convertTiming($in{'m_cls_skill_timing'}),
    'skill2Roll'     => $in{'m_cls_skill_hantei'},
    'skill2Target'   => $in{'m_cls_skill_taisho'},
    'skill2Range'    => $in{'m_cls_skill_range'},
    'skill2Cost'     => $in{'m_cls_skill_cost'},
    'skill2Reqd'     => $in{'m_cls_skill_page'},
    'skill2Note'     => $in{'m_cls_skill_memo'},

    'armamentHandRName'   => $in{'IR_name'},
    'armamentHandRWeight' => $in{'IR_weight'},
    'armamentHandRAcc'    => $in{'BIR1'}+0 || '',
    'armamentHandRAtk'    => $in{'BIR2'}+0 || '',
    'armamentHandREva'    => $in{'BIR3'}+0 || '',
    'armamentHandRDef'    => $in{'BIR4'}+0 || '',
    'armamentHandRMDef'   => $in{'BIR5'}+0 || '',
    'armamentHandRIni'    => $in{'BIR6'}+0 || '',
    'armamentHandRMove'   => $in{'BIR7'}+0 || '',
    'armamentHandRRange'  => $in{'IR_shatei'},
    'armamentHandRType'   => $in{'IR_type'},
    'armamentHandRNote'   => ($in{'IR_lv'} ? "Lv$in{'IR_lv'} ":'').($in{'IR_only_cls'} ? "制限:$in{'IR_only_cls'} ":'').$in{'IL_memo'},

    'armamentHandLName'   => $in{'IL_name'},
    'armamentHandLWeight' => $in{'IL_weight'},
    'armamentHandLAcc'    => $in{'BIL1'}+0 || '',
    'armamentHandLAtk'    => $in{'BIL2'}+0 || '',
    'armamentHandLEva'    => $in{'BIL3'}+0 || '',
    'armamentHandLDef'    => $in{'BIL4'}+0 || '',
    'armamentHandLMDef'   => $in{'BIL5'}+0 || '',
    'armamentHandLIni'    => $in{'BIL6'}+0 || '',
    'armamentHandLMove'   => $in{'BIL7'}+0 || '',
    'armamentHandLRange'  => $in{'IL_shatei'},
    'armamentHandLType'   => $in{'IL_type'},
    'armamentHandLNote'   => ($in{'IL_lv'} ? "Lv$in{'IL_lv'} ":'').($in{'IL_only_cls'} ? "制限:$in{'IL_only_cls'} ":'').$in{'IL_memo'},

    'armamentHeadName'   => $in{'IH_name'},
    'armamentHeadWeight' => $in{'IH_weight'},
    'armamentHeadAcc'    => $in{'BIH1'}+0 || '',
    'armamentHeadAtk'    => $in{'BIH2'}+0 || '',
    'armamentHeadEva'    => $in{'BIH3'}+0 || '',
    'armamentHeadDef'    => $in{'BIH4'}+0 || '',
    'armamentHeadMDef'   => $in{'BIH5'}+0 || '',
    'armamentHeadIni'    => $in{'BIH6'}+0 || '',
    'armamentHeadMove'   => $in{'BIH7'}+0 || '',
    'armamentHeadRange'  => $in{'IH_shatei'},
    'armamentHeadType'   => $in{'IH_type'},
    'armamentHeadNote'   => ($in{'IH_lv'} ? "Lv$in{'IH_lv'} ":'').($in{'IH_only_cls'} ? "制限:$in{'IH_only_cls'} ":'').$in{'IH_memo'},

    'armamentBodyName'   => $in{'IB_name'},
    'armamentBodyWeight' => $in{'IB_weight'},
    'armamentBodyAcc'    => $in{'BIB1'}+0 || '',
    'armamentBodyAtk'    => $in{'BIB2'}+0 || '',
    'armamentBodyEva'    => $in{'BIB3'}+0 || '',
    'armamentBodyDef'    => $in{'BIB4'}+0 || '',
    'armamentBodyMDef'   => $in{'BIB5'}+0 || '',
    'armamentBodyIni'    => $in{'BIB6'}+0 || '',
    'armamentBodyMove'   => $in{'BIB7'}+0 || '',
    'armamentBodyRange'  => $in{'IB_shatei'},
    'armamentBodyType'   => $in{'IB_type'},
    'armamentBodyNote'   => ($in{'IB_lv'} ? "Lv$in{'IB_lv'} ":'').($in{'IB_only_cls'} ? "制限:$in{'IB_only_cls'} ":'').$in{'IB_memo'},
    
    'armamentSubName'   => $in{'IS_name'},
    'armamentSubWeight' => $in{'IS_weight'},
    'armamentSubAcc'    => $in{'BIS1'}+0 || '',
    'armamentSubAtk'    => $in{'BIS2'}+0 || '',
    'armamentSubEva'    => $in{'BIS3'}+0 || '',
    'armamentSubDef'    => $in{'BIS4'}+0 || '',
    'armamentSubMDef'   => $in{'BIS5'}+0 || '',
    'armamentSubIni'    => $in{'BIS6'}+0 || '',
    'armamentSubMove'   => $in{'BIS7'}+0 || '',
    'armamentSubRange'  => $in{'IS_shatei'},
    'armamentSubType'   => $in{'IS_type'},
    'armamentSubNote'   => ($in{'IS_lv'} ? "Lv$in{'IS_lv'} ":'').($in{'IS_only_cls'} ? "制限:$in{'IS_only_cls'} ":'').$in{'IS_memo'},
    
    'armamentOtherName'   => $in{'IA_name'},
    'armamentOtherWeight' => $in{'IA_weight'},
    'armamentOtherAcc'    => $in{'BIA1'}+0 || '',
    'armamentOtherAtk'    => $in{'BIA2'}+0 || '',
    'armamentOtherEva'    => $in{'BIA3'}+0 || '',
    'armamentOtherDef'    => $in{'BIA4'}+0 || '',
    'armamentOtherMDef'   => $in{'BIA5'}+0 || '',
    'armamentOtherIni'    => $in{'BIA6'}+0 || '',
    'armamentOtherMove'   => $in{'BIA7'}+0 || '',
    'armamentOtherRange'  => $in{'IA_shatei'},
    'armamentOtherType'   => $in{'IA_type'},
    'armamentOtherNote'   => ($in{'IA_lv'} ? "Lv$in{'IA_lv'} ":'').($in{'IA_only_cls'} ? "制限:$in{'IA_only_cls'} ":'').$in{'IA_memo'},

    'battleSkillName'   => $in{'BSK_memo'},
    'battleSkillAcc'    => $in{'BSK1'}+0 || '',
    'battleSkillAtk'    => $in{'BSK2'}+0 || '',
    'battleSkillEva'    => $in{'BSK3'}+0 || '',
    'battleSkillDef'    => $in{'BSK4'}+0 || '',
    'battleSkillMDef'   => $in{'BSK5'}+0 || '',
    'battleSkillIni'    => $in{'BSK6'}+0 || '',
    'battleSkillMove'   => $in{'BSK7'}+0 || '',

    'battleOtherName'   => $in{'BOT_memo'},
    'battleOtherAcc'    => $in{'BOT1'}+0 || '',
    'battleOtherAtk'    => $in{'BOT2'}+0 || '',
    'battleOtherEva'    => $in{'BOT3'}+0 || '',
    'battleOtherDef'    => $in{'BOT4'}+0 || '',
    'battleOtherMDef'   => $in{'BOT5'}+0 || '',
    'battleOtherIni'    => $in{'BOT6'}+0 || '',
    'battleOtherMove'   => $in{'BOT7'}+0 || '',
    
    'battleSkillAccDice' => $in{'dice_meichu'}-2 || '',
    'battleSkillAtkDice' => $in{'dice_attack'}-2 || '',
    'battleSkillEvaDice' => $in{'dice_kaihi' }-2 || '',
    
    'rollTrapDetectSkill'   => $in{'THS1'}+0 || '',
    'rollTrapReleaseSkill'  => $in{'THS2'}+0 || '',
    'rollDangerDetectSkill' => $in{'THS3'}+0 || '',
    'rollEnemyLoreSkill'    => $in{'THS4'}+0 || '',
    'rollAppraisalSkill'    => $in{'THS5'}+0 || '',
    'rollMagicSkill'        => $in{'THS6'}+0 || '',
    'rollSongSkill'         => $in{'THS7'}+0 || '',
    'rollAlchemySkill'      => $in{'THS8'}+0 || '',
    
    'rollTrapDetectOther'   => $in{'THO1'}+0 || '',
    'rollTrapReleaseOther'  => $in{'THO2'}+0 || '',
    'rollDangerDetectOther' => $in{'THO3'}+0 || '',
    'rollEnemyLoreOther'    => $in{'THO4'}+0 || '',
    'rollAppraisalOther'    => $in{'THO5'}+0 || '',
    'rollMagicOther'        => $in{'THO6'}+0 || '',
    'rollSongOther'         => $in{'THO7'}+0 || '',
    'rollAlchemyOther'      => $in{'THO8'}+0 || '',
    
    'rollTrapDetectDiceAdd'   => $in{'dice_wanatanti'}-2 || '',
    'rollTrapReleaseDiceAdd'  => $in{'dice_wanakaijo'}-2 || '',
    'rollEnemyLoreDiceAdd'    => $in{'dice_kanti'}-2     || '',
    'rollDangerDetectDiceAdd' => $in{'dice_sikibetu'}-2  || '',
    'rollAppraisalDiceAdd'    => $in{'dice_kantei'}-2    || '',
    'rollMagicDiceAdd'        => ($in{'dice_majutu'}+0 || 2)-2 || '',
    'rollSongDiceAdd'         => ($in{'dice_juka'}+0   || 2)-2 || '',
    'rollAlchemyDiceAdd'      => ($in{'dice_renkin'}+0 || 2)-2 || '',

    'weightLimitAddWeapon' => $in{'weight_arms_mod'}+0 || '',
    'weightLimitAddArmour' => $in{'weight_body_mod'}+0 || '',
    'weightLimitAddItems'  => $in{'weight_item_mod'}+0 || '',
  );
  ## 名前
  ($pc{'characterName'},$pc{'characterNameRuby'}) = convertNameRuby($in{'pc_name'} || $in{'data_title'});
  ($pc{'aka'},$pc{'akaRuby'}) = convertNameRuby($in{'pc_codename'});
  ## 種族
  $pc{'race'} =~ s/[:：](.+)$/（$1）/;

  ## メインクラス
  $pc{'classMain'} = $in{'main_class'};
  $pc{'classMainLv1'} = $data::class{$in{'main_class'}}{'base'} || $in{'main_class'};
  
  $pc{'hpMain'} = $data::class{$pc{'classMainLv1'}}{'stt'}{'Hp'};
  $pc{'mpMain'} = $data::class{$pc{'classMainLv1'}}{'stt'}{'Mp'};
  
  ## スキル
  my $n = 3; my $i = 0;
  foreach my $name (@{$in{'skill_name'}}){
    $pc{'skill'.($n).'Name'}   = $name;
    $pc{'skill'.($n).'Lv'}     = convertSkillLv($in{'skill_lv'}[$i]);
    $pc{'skill'.($n).'Timing'} = convertTiming($in{'skill_timing'}[$i]);
    $pc{'skill'.($n).'Roll'}   = $in{'skill_hantei'}[$i];
    $pc{'skill'.($n).'Target'} = $in{'skill_taisho'}[$i];
    $pc{'skill'.($n).'Range'}  = $in{'skill_range'}[$i];
    $pc{'skill'.($n).'Cost'}   = $in{'skill_cost'}[$i];
    $pc{'skill'.($n).'Reqd'}   = $in{'skill_page'}[$i];
    $pc{'skill'.($n).'Note'}   = $in{'skill_memo'}[$i];
    $pc{'skill'.($n).'Type'}   = convertSkillType($in{'skill_shozoku'}[$i]);
    $n++; $i++;
  }
  my $i = 0;
  foreach my $name (@{$in{'ippanskill_name'}}){
    $pc{'skill'.($n).'Name'}   = $name;
    $pc{'skill'.($n).'Lv'}     = convertSkillLv($in{'ippanskill_lv'}[$i]);
    $pc{'skill'.($n).'Timing'} = convertTiming($in{'ippanskill_timing'}[$i]);
    $pc{'skill'.($n).'Roll'}   = $in{'ippanskill_hantei'}[$i];
    $pc{'skill'.($n).'Target'} = $in{'ippanskill_taisho'}[$i];
    $pc{'skill'.($n).'Range'}  = $in{'ippanskill_range'}[$i];
    $pc{'skill'.($n).'Cost'}   = $in{'ippanskill_cost'}[$i];
    $pc{'skill'.($n).'Reqd'}   = $in{'ippanskill_page'}[$i];
    $pc{'skill'.($n).'Note'}   = $in{'ippanskill_memo'}[$i];
    $pc{'skill'.($n).'Type'}   = 'general';
    $n++; $i++;
  }
  $pc{'skillsNum'} = $n-1;
  sub convertSkillLv {
    my $lv = shift;
    if   ($lv !~ /^[0-9]+$/) { return 1; }
    return $lv;
  }
  sub convertSkillType {
    my $type = shift;
    if($type eq '一般'){ return 'general'; }
    if($type eq '流派'){ return 'style'; }
    if($type eq '誓約'){ return 'geis'; }
    if($type eq '異才'){ return 'another'; }
    else {
      foreach (keys %data::races){
        if($type eq $_){ return 'race' }
      }
    }
    return $type
  }
  ## 装備金額
  if($in{'IR_price'}){ $pc{'cashbook'} .= "$in{'IR_name'} ::-$in{'IR_price'}\n"; }
  if($in{'IL_price'}){ $pc{'cashbook'} .= "$in{'IL_name'} ::-$in{'IL_price'}\n"; }
  if($in{'IH_price'}){ $pc{'cashbook'} .= "$in{'IH_name'} ::-$in{'IH_price'}\n"; }
  if($in{'IB_price'}){ $pc{'cashbook'} .= "$in{'IB_name'} ::-$in{'IB_price'}\n"; }
  if($in{'IS_price'}){ $pc{'cashbook'} .= "$in{'IS_name'} ::-$in{'IS_price'}\n"; }
  if($in{'IA_price'}){ $pc{'cashbook'} .= "$in{'IA_name'} ::-$in{'IA_price'}\n"; }
  ## 所持品
  my $i = 0; my $itemlength = 0;
  foreach my $name (@{$in{'item_name'}}){
    $pc{'items'} .= "|${name} | ";
    $pc{'items'} .= "@[$in{'item_weight'}[$i]]" if $in{'item_weight'}[$i] ne '';
    $pc{'items'} .= " $in{'item_memo'}[$i] |\n";
    if($in{'item_price'}[$i]){
      $pc{'cashbook'} .= "${name} ::-$in{'item_price'}[$i]\n";
    }
    my $len = length($name);
    if($len > $itemlength){ $itemlength = $len; }
    $i++;
  }
  if($pc{'items'}){ $pc{'items'} = "|${itemlength}em| |c\n".$pc{'items'}; }
  if($in{'debt'}){ $pc{'items'} = "借金：$in{'debt'} G".$pc{'items'}; }
  $pc{'itemsView'} = tag_unescape tag_unescape_lines $pc{'items'};
  $pc{'itemsView'} =~ s/\r\n?|\n/<br>/g;

  ## レベルアップ履歴
  my $advlv = $in{'SL_main_change_lv'} || 10;
  my $fatelv;
  foreach my $lv (2 .. $pc{'level'}){
    $pc{'lvUp'.($lv).'SttStr'} = $in{'LvupH_KN1'}[$lv-2];
    $pc{'lvUp'.($lv).'SttDex'} = $in{'LvupH_KN2'}[$lv-2];
    $pc{'lvUp'.($lv).'SttAgi'} = $in{'LvupH_KN3'}[$lv-2];
    $pc{'lvUp'.($lv).'SttInt'} = $in{'LvupH_KN4'}[$lv-2];
    $pc{'lvUp'.($lv).'SttSen'} = $in{'LvupH_KN5'}[$lv-2];
    $pc{'lvUp'.($lv).'SttMnd'} = $in{'LvupH_KN6'}[$lv-2];
    $pc{'lvUp'.($lv).'SttLuk'} = $in{'LvupH_KN7'}[$lv-2];
    $pc{'lvUp'.($lv).'Class'}  = $in{'LvupH_scls_name'}[$lv-2] || '';
    $pc{'lvUp'.($lv).'Skill1'}  = $in{'LvupH_skill1'}[$lv-2];
    $pc{'lvUp'.($lv).'Skill2'}  = $in{'LvupH_skill2'}[$lv-2];
    $pc{'lvUp'.($lv).'Skill3'}  = $in{'LvupH_skill3'}[$lv-2];
    if($data::class{$in{'main_class'}}{'type'} eq 'fate'
      && $in{'LvupH_skill1'}[$lv-2] =~ /$in{'main_class'}|運命/
      || $in{'LvupH_skill2'}[$lv-2] =~ /$in{'main_class'}|運命/
      || $in{'LvupH_skill3'}[$lv-2] =~ /$in{'main_class'}|運命/
    ){ $fatelv = $lv; }
    elsif(!$pc{'lvUp'.($lv).'Class'}
      && $in{'LvupH_skill1'}[$lv-2] =~ /称号(?:クラス|ｸﾗｽ)?[:：]?([ァ-ヶー]*)/
      || $in{'LvupH_skill2'}[$lv-2] =~ /称号(?:クラス|ｸﾗｽ)?[:：]?([ァ-ヶー]*)/
      || $in{'LvupH_skill3'}[$lv-2] =~ /称号(?:クラス|ｸﾗｽ)?[:：]?([ァ-ヶー]*)/
    ){ $pc{'lvUp'.($lv).'Class'} = 'title'; $pc{'lvUp'.($lv).'ClassFree'} = $1; }
    elsif(!$pc{'lvUp'.($lv).'Class'}
      && $in{'LvupH_skill1'}[$lv-2] =~ /フェイト|fate/
      || $in{'LvupH_skill2'}[$lv-2] =~ /フェイト|fate/
      || $in{'LvupH_skill3'}[$lv-2] =~ /フェイト|fate/
    ){
      $pc{'lvUp'.($lv).'Class'} = 'fate';
    }
    $i++;
  }
  if($data::class{$in{'main_class'}}{'type'} eq 'adv'){
    $pc{'lvUp'.($advlv).'Class'} ||= $in{'main_class'};
  }
  elsif($data::class{$in{'main_class'}}{'type'} eq 'fate'){
    $pc{'lvUp'.($advlv).'Class'} ||= $data::class{$in{'main_class'}}{'adv'};
    $pc{'lvUp'.($fatelv || 20).'Class'} ||= $in{'main_class'};
  }

  ## 履歴
  $pc{'history0Exp'} = $in{'sum_seichoten_default'} || 0;
  $pc{'history0Money'} = 500;
  my $i = 0;
  foreach my $exp (@{$in{'get_exp_his'}}){
    $pc{'history'.($i+1).'Exp'}   = $in{'adv_exp_his'}[$i].addNum($in{'bns_exp_his'}[$i]);
    $pc{'history'.($i+1).'Money'} = $in{'get_money_his'}[$i];
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    $i++;
  }
  $pc{'historyNum'} = $i;
  
  ## 履歴
  my $i = 0;
  foreach my $name (@{$in{'cone_name'}}){
    $pc{'connection'.($i+1).'Money'} = $name;
    $pc{'connection'.($i+1).'Note'}  = $in{'cone_kankei'}[$i];
    $i++;
  }

  ## プロフィール追加
  my $profile;
  $profile .= ":身長|$in{'pc_height'}\n";
  $profile .= ":体重|$in{'pc_weight'}\n";
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
  $str =~ s/ﾑｰﾌﾞ|ﾑｰｳﾞ/ムーブ/;
  $str =~ s/ﾘｱｸｼｮﾝ/リアクション/;
  $str =~ s/ﾘｱ/リア/;
  $str =~ s/ｱｸｼｮﾝ/アクション/;
  $str =~ s/ｾｯﾄｱｯﾌﾟ/セットアップ/;
  $str =~ s/ｲﾆｼｱﾁﾌﾞ/イニシアチブ/;
  $str =~ s/ｸﾘﾝﾅｯﾌﾟ/クリンナップ/;
  $str =~ s/ﾌﾟﾛｾｽ/プロセス/;
  $str =~ s/ﾊﾟｯｼﾌﾞ|ﾊﾟｯｼｳﾞ/パッシブ/;
  $str =~ s/ｱｲﾃﾑ/アイテム/;
  $str =~ s/ﾒｲｷﾝｸﾞ/メイキング/;
  return $str;
}
sub convertNameRuby {
  my $name = shift;
  if    ($name =~ /^(.+)[\(（](.+?)[\)）]$/){ return $1,$2; }
  elsif ($name =~ /^(.+)[\"“](.+?)[\"”]$/){ return $1,$2; }
  else { return $name; }
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