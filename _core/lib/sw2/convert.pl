################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

sub data_get {
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

sub data_convert {
  my $set_url = shift;
  my $file;
  
  ## キャラクター保管所
  if($set_url =~ m"^https?://charasheet\.vampire-blood\.net/"){
    my $data = data_get($set_url.'.js') or error 'キャラクター保管所のデータが取得できませんでした';
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };
    
    return convertHokanjoToYtsheet(\%in);
  }
  ## 旧ゆとシート
  {
    foreach my $url (keys %set::convert_url){
      if($set_url =~ s"^${url}data/(.*?).html"$1"){
        open my $IN, '<', "$set::convert_url{$url}data/${set_url}.cgi" or error '旧ゆとシートのデータが開けませんでした';
        my %pc;
        $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
        close($IN);
        
        return convert1to2(\%pc);
      }
    }
  }
  ## ゆとシートⅡ
  {
    my $data = data_get($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
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

  my %pc = (
    'convertSource' => 'キャラクター保管所',
    'characterName' => $in{'pc_name'} || $in{'data_title'},
    'tags' => convertTags($in{'pc_tags'}),
    'race' => $in{'shuzoku_name'},
    'birth' => $in{'umare_name'},
    'age' => $in{'age'},
    'gender' => $in{'sex'},
    'sin' => $in{'V_kegare'},
    'money' => $in{'money'},
    'deposit' => $in{'debt'},
    'sttBaseTec' => $in{'N_waza'}, 'sttBasePhy' => $in{'N_karada'}, 'sttBaseSpi' => $in{'N_kokoro'},
    'sttBaseA' => $in{'V_NC1'}, 'sttAddA' => ($in{'NP1'}-$in{'N_waza'  }-$in{'V_NC1'}-$in{'NS1'}) || '', 
    'sttBaseB' => $in{'V_NC2'}, 'sttAddB' => ($in{'NP2'}-$in{'N_waza'  }-$in{'V_NC2'}-$in{'NS2'}) || '',
    'sttBaseC' => $in{'V_NC3'}, 'sttAddC' => ($in{'NP3'}-$in{'N_karada'}-$in{'V_NC3'}-$in{'NS3'}) || '',
    'sttBaseD' => $in{'V_NC4'}, 'sttAddD' => ($in{'NP4'}-$in{'N_karada'}-$in{'V_NC4'}-$in{'NS4'}) || '',
    'sttBaseE' => $in{'V_NC5'}, 'sttAddE' => ($in{'NP5'}-$in{'N_kokoro'}-$in{'V_NC5'}-$in{'NS5'}) || '',
    'sttBaseF' => $in{'V_NC6'}, 'sttAddF' => ($in{'NP6'}-$in{'N_kokoro'}-$in{'V_NC6'}-$in{'NS6'}) || '',
    'lvFig' => $in{'V_GLv1'} || '', 'lvGra' => $in{'V_GLv2'} || '', 'lvFen' => $in{'V_GLv3'} || '', 'lvSho' => $in{'V_GLv4'} || '',
    'lvSor' => $in{'V_GLv5'} || '', 'lvCon' => $in{'V_GLv6'} || '', 'lvPri' => $in{'V_GLv7'} || '',
    'lvFai' => $in{'V_GLv8'} || '', 'lvMag' => $in{'V_GLv9'} || '', 'lvDem' => $in{'V_GLv17'} || '', 'lvDru' => $in{'V_GLv24'} || '',
    'lvSco' => $in{'V_GLv10'} || '','lvRan' => $in{'V_GLv11'} || '','lvSag' => $in{'V_GLv12'} || '',
    'lvEnh' => $in{'V_GLv13'} || '', 'lvBar' => $in{'V_GLv14'} || '', 'lvRid' => $in{'V_GLv16'} || '',
    'lvAlc' => $in{'V_GLv15'} || '', 'lvWar' => $in{'V_GLv18'} || '', 'lvMys' => $in{'V_GLv19'} || '', 'lvPhy' => $in{'V_GLv20'} || '',
    'lvGri' => $in{'V_GLv21'} || '', 'lvArt' => $in{'V_GLv22'} || '', 'lvAri' => $in{'V_GLv23'} || '',
    'magicPowerAdd' => $in{'arms_maryoku_sum'},
    'evasionClass' => $in{'kaihi_ginou_name'},
    'armourName' => $in{'armor_name'}, 'armourReqd' => $in{'armor_hitsukin'}, 'armourNote' => $in{'armor_memo'},
    'armourDef' => $in{'armor_bougo'} || 0, 'armourEva' => $in{'armor_kaihi'} || 0,
    'shieldName' => $in{'shield_name'}, 'shieldReqd' => $in{'shield_hitsukin'}, 'shieldNote' => $in{'shield_memo'},
    'shieldDef' => $in{'shield_bougo'} || 0, 'shieldEva' => $in{'shield_kaihi'} || 0,
    'defOtherName' => $in{'shield2_name'}, 'defOtherReqd' => $in{'shield2_hitsukin'}, 'defOtherNote' => $in{'shield2_memo'},
    'defOtherDef' =>$in{'shield2_bougo'} || 0, 'defOtherEva' =>$in{'shield2_kaihi'} || 0,
    
    'accessoryOtherName'    => $in{'acce10_name'}[0], 'accessoryOtherNote'    => $in{'acce10_memo'}[0],
    'accessoryOtherOwn'     => $in{'acce10_senyou'}[0] eq 1 ? 'HP' : $in{'acce10_senyou'}[0] eq 2 ? 'MP' : '',
    'accessoryOtherAdd'     => $in{'acce10_name'}[1] ? 1 : 0,
    'accessoryOther_Name'   => $in{'acce10_name'}[1], 'accessoryOther_Note'   => $in{'acce10_memo'}[1],
    'accessoryOther_Own'    => $in{'acce10_senyou'}[1] eq 1 ? 'HP' : $in{'acce10_senyou'}[1] eq 2 ? 'MP' : '',
    'accessoryOther_Add'    => $in{'acce10_name'}[2] ? 1 : 0,
    'accessoryOther__Name'  => $in{'acce10_name'}[2], 'accessoryOther__Note'  => $in{'acce10_memo'}[2],
    'accessoryOther__Own'    => $in{'acce10_senyou'}[2] eq 1 ? 'HP' : $in{'acce10_senyou'}[2] eq 2 ? 'MP' : '',
    
    'accessoryOther2Name'   => $in{'acce10_name'}[3], 'accessoryOther2Note'   => $in{'acce10_memo'}[3],
    'accessoryOther2Own'    => $in{'acce10_senyou'}[3] eq 1 ? 'HP' : $in{'acce10_senyou'}[3] eq 2 ? 'MP' : '',
    'accessoryOther2Add'    => $in{'acce10_name'}[4] ? 1 : 0,
    'accessoryOther2_Name'  => $in{'acce10_name'}[4], 'accessoryOther2_Note'  => $in{'acce10_memo'}[4],
    'accessoryOther2_Own'   => $in{'acce10_senyou'}[4] eq 1 ? 'HP' : $in{'acce10_senyou'}[4] eq 2 ? 'MP' : '',
    'accessoryOther2_Add'   => $in{'acce10_name'}[5] ? 1 : 0,
    'accessoryOther2__Name' => $in{'acce10_name'}[5], 'accessoryOther2__Note' => $in{'acce10_memo'}[5],
    'accessoryOther2__Own'  => $in{'acce10_senyou'}[5] eq 1 ? 'HP' : $in{'acce10_senyou'}[5] eq 2 ? 'MP' : '',
    
    'accessoryOther3Name'   => $in{'acce10_name'}[6], 'accessoryOther3Note'   => $in{'acce10_memo'}[6],
    'accessoryOther3Own'    => $in{'acce10_senyou'}[6] eq 1 ? 'HP' : $in{'acce10_senyou'}[6] eq 2 ? 'MP' : '',
    'accessoryOther3Add'    => $in{'acce10_name'}[7] ? 1 : 0,
    'accessoryOther3_Name'  => $in{'acce10_name'}[7], 'accessoryOther3_Note'  => $in{'acce10_memo'}[7],
    'accessoryOther3_Own'   => $in{'acce10_senyou'}[7] eq 1 ? 'HP' : $in{'acce10_senyou'}[7] eq 2 ? 'MP' : '',
    'accessoryOther3_Add'   => $in{'acce10_name'}[8] ? 1 : 0,
    'accessoryOther3__Name' => $in{'acce10_name'}[8], 'accessoryOther3__Note' => $in{'acce10_memo'}[8],
    'accessoryOther3__Own'  => $in{'acce10_senyou'}[8] eq 1 ? 'HP' : $in{'acce10_senyou'}[8] eq 2 ? 'MP' : '',
    
    'accessoryOther4Name'   => $in{'acce10_name'}[9], 'accessoryOther3Note'   => $in{'acce10_memo'}[9],
    'accessoryOther4Own'    => $in{'acce10_senyou'}[9] eq 1 ? 'HP' : $in{'acce10_senyou'}[9] eq 2 ? 'MP' : '',
    'accessoryOther4Add'    => $in{'acce10_name'}[10] ? 1 : 0,
    'accessoryOther4_Name'  => $in{'acce10_name'}[10], 'accessoryOther3_Note'  => $in{'acce10_memo'}[10],
    'accessoryOther4_Own'   => $in{'acce10_senyou'}[10] eq 1 ? 'HP' : $in{'acce10_senyou'}[10] eq 2 ? 'MP' : '',
    'accessoryOther4_Add'   => $in{'acce10_name'}[11] ? 1 : 0,
    'accessoryOther4__Name' => $in{'acce10_name'}[11], 'accessoryOther3__Note' => $in{'acce10_memo'}[11],
    'accessoryOther4__Own'  => $in{'acce10_senyou'}[11] eq 1 ? 'HP' : $in{'acce10_senyou'}[11] eq 2 ? 'MP' : '',
  );
  ## 種族
  if($in{'special_shuzoku_name'}){
    my $parent = $in{'special_shuzoku_name'};
    if   ($parent =~ /第1/){ $pc{'race'} .= '（ルミエル）'; }
    elsif($parent =~ /第2/){ $pc{'race'} .= '（イグニス）'; }
    elsif($parent =~ /第3/){ $pc{'race'} .= '（カルディア）'; }
    elsif($parent =~ s/生まれ$//){
      $pc{'race'} .= '（'.$parent.'）';
    }
  }
  ## 信仰
  if($in{'priest_sinkou'}){
    foreach my $gods (@data::gods){
      if(
          ($in{'priest_sinkou'} eq "“@$gods[2]”@$gods[3]")
        ||($in{'priest_sinkou'} eq "@$gods[2]@$gods[3]") 
        ||(@$gods[2] && $in{'priest_sinkou'} =~ /(^|[“”"])@$gods[2]([“”"]|$)/)
        ||(@$gods[3] && $in{'priest_sinkou'} eq @$gods[3])
      ){
        $pc{'faith'} = @$gods[2] && @$gods[3] ? "“@$gods[2]”@$gods[3]" : @$gods[2] ? "“@$gods[2]”" : @$gods[3];
        last;
      }
    }
    if(!$pc{'faith'}){
      $pc{'faithOther'} = $in{'priest_sinkou'};
      $pc{'faith'} = 'その他の信仰';
    }
  }
  ## 言語
  my @language; my %talk; my %read;
  if($in{'lang3S' } || $in{'lang3R' }){ push(@language, ['交易共通語'         ,$in{'lang3S' },$in{'lang3R' }]); }
  if($in{'lang4S' } || $in{'lang4R' }){ push(@language, ['神紀文明語'         ,$in{'lang4S' },$in{'lang4R' }]); }
  if($in{'lang11S'} || $in{'lang11R'}){ push(@language, ['魔動機文明語'       ,$in{'lang11S'},$in{'lang11R'}]); }
  if($in{'lang12S'} || $in{'lang12R'}){ push(@language, ['魔法文明語'         ,$in{'lang12S'},$in{'lang12R'}]); }
  if($in{'lang13S'} || $in{'lang13R'}){ push(@language, ['妖精語'             ,$in{'lang13S'},$in{'lang13R'}]); }
  if($in{'lang1S' } || $in{'lang1R' }){ push(@language, ['エルフ語'           ,$in{'lang1S' },$in{'lang1R' }]); }
  if($in{'lang8S' } || $in{'lang8R' }){ push(@language, ['ドワーフ語'         ,$in{'lang8S' },$in{'lang8R' }]); }
  if($in{'lang15S'} || $in{'lang15R'}){ push(@language, ['グラスランナー語'   ,$in{'lang15S'},$in{'lang15R'}]); }
  if($in{'lang17S'} || $in{'lang17R'}){ push(@language, ['シャドウ語'         ,$in{'lang17S'},$in{'lang17R'}]); }
  if($in{'lang18S'} || $in{'lang18R'}){ push(@language, ['ミアキス語'         ,$in{'lang18S'},$in{'lang18R'}]); }
  if($in{'lang21S'} || $in{'lang21R'}){ push(@language, ['ソレイユ語'         ,$in{'lang21S'},$in{'lang21R'}]); }
  if($in{'lang25S'} || $in{'lang25R'}){ push(@language, ['リカント語'         ,$in{'lang25S'},$in{'lang25R'}]); }
  if($in{'lang6S' } || $in{'lang6R' }){ push(@language, ['ドラゴン語'         ,$in{'lang6S' },$in{'lang6R' }]); }
  if($in{'lang9S' } || $in{'lang9R' }){ push(@language, ['汎用蛮族語'         ,$in{'lang9S' },$in{'lang9R' }]); }
  if($in{'lang14S'} || $in{'lang14R'}){ push(@language, ['妖魔語'             ,$in{'lang14S'},$in{'lang14R'}]); }
  if($in{'lang7S' } || $in{'lang7R' }){ push(@language, ['ドレイク語'         ,$in{'lang7S' },$in{'lang7R' }]); }
  if($in{'lang22S'} || $in{'lang22R'}){ push(@language, ['バジリスク語'       ,$in{'lang22S'},$in{'lang22R'}]); }
  if($in{'lang2S' } || $in{'lang2R' }){ push(@language, ['巨人語'             ,$in{'lang2S' },$in{'lang2R' }]); }
  if($in{'lang10S'} || $in{'lang10R'}){ push(@language, ['魔神語'             ,$in{'lang10S'},$in{'lang10R'}]); }
  if($in{'lang19S'} || $in{'lang19R'}){ push(@language, ['バルカン語'         ,$in{'lang19S'},$in{'lang19R'}]); }
  if($in{'lang20S'} || $in{'lang20R'}){ push(@language, ['ライカンスロープ語' ,$in{'lang20S'},$in{'lang20R'}]); }
  if($in{'lang23S'} || $in{'lang23R'}){ push(@language, ['リザードマン語'     ,$in{'lang23S'},$in{'lang23R'}]); }
  if($in{'lang24S'} || $in{'lang24R'}){ push(@language, ['ケンタウロス語'     ,$in{'lang24S'},$in{'lang24R'}]); }
  my $i = 0;
  foreach my $id (@{$in{'V_lang_type_id'}}){
    my $name = $in{'lang_note'}[$i];
    if($name){
      if($in{'V_lang_type_id'}[$i] == 5){ $name = "地方語（${name}）" }
      push( @language, [ $name, $in{'V_langS'}[$i], $in{'V_langR'}[$i] ] );
    }
    my $name = $in{'lang_noteA'}[$i];
    if($name){
      if($in{'V_lang_typeA_id'}[$i] == 5){ $name = "地方語（${name}）" }
      push( @language, [ $name, $in{'V_langSA'}[$i], $in{'V_langRA'}[$i] ] );
    }
    $i++;
  }
  
  my $i = 1;
  foreach my $lang (@language){
    my $next;
    foreach my $default (@{$data::race_language{$pc{'race'}}}){
      if(@$lang[0] eq @$default[0]){ $next = 1; last; }
    }
    next if $next;
    $pc{'language'.$i} = @$lang[0];
    $pc{'language'.$i.'Talk'} = @$lang[1];
    $pc{'language'.$i.'Read'} = @$lang[2];
    $i++;
  }
  $pc{'languageNum'} = $i;
  
  ## 戦闘特技
  my %nums = ('1'=>'Ⅰ', '2'=>'Ⅱ', '3'=>'Ⅲ', '4'=>'Ⅳ', '5'=>'Ⅴ');
  my $i = 0;
  foreach my $lv (@{$in{'ST_lv'}}){
    $pc{'combatFeatsLv'.$lv} = $in{'ST_name'}[$i];
    $pc{'combatFeatsLv'.$lv} =~ s|/|／|;
    $pc{'combatFeatsLv'.$lv} =~ s|A|Ａ|;
    $pc{'combatFeatsLv'.$lv} =~ s|S|Ｓ|;
    $pc{'combatFeatsLv'.$lv} =~ s|MP|ＭＰ|;
    if($in{'ST_tlv'} > 0){
      $pc{'combatFeatsLv'.$lv} .= $nums{$in{'ST_tlv'}[$i]};
    }
    $i++;
  }
  ## 技芸
  foreach my $i (0 .. 16){
    $pc{'craftEnhance'   .($i+1)} = $in{'ES_name'}[$i];
    $pc{'craftSong'      .($i+1)} = $in{'JK_name'}[$i];
    $pc{'craftRiding'    .($i+1)} = $in{'KG_name'}[$i];
    $pc{'craftAlchemy'   .($i+1)} = $in{'HJ_name'}[$i];
    
    $pc{'craftCommand'   .($i+1)} = $in{'HO_name'}[$i];
    $pc{'craftDivination'.($i+1)} = $in{'UR_name'}[$i];
    $pc{'craftPotential' .($i+1)} = $in{'MS_name'}[$i];
    $pc{'craftDignity'   .($i+1)} = $in{'KK_name'}[$i];
    $pc{'magicGramarye'  .($i+1)} = $in{'skill_name'}[$i];
    $pc{'craftSeal'      .($i+1)} = $in{'JI_name'}[$i];
    
    $pc{'craftCommand'.($i+1)} =~ s/:/：/g;
    $pc{'craftCommand'.($i+1)} =~ s/涛/濤/g;
    $pc{'magicGramarye'.($i+1)} =~ s/[=＝]/＝/g;
    foreach(@data::magic_gramarye){
      if ($pc{'magicGramarye'.($i+1)} eq @$_[2]){ $pc{'magicGramarye'.($i+1)} = @$_[1]; last }
    }
    $pc{'craftSeal'.($i+1)} =~ tr#０-９Ａ-Ｚａ-ｚ＋－/#0-9A-Za-z+\-／#;
  }
  ## 武器
  my %skills = (
    '1' => 'ファイター', '2' => 'グラップラー', '3' => 'フェンサー', '4' => 'シューター',
    '13' => 'エンハンサー', '17' => 'デーモンルーラー'
  );
  my $i = 0;
  foreach my $name (@{$in{'arms_name'}}){
    $pc{'weapon'.($i+1).'Name'}    = $name;
    $pc{'weapon'.($i+1).'Usage'}   = $in{'arms_yoho'}[$i];
    $pc{'weapon'.($i+1).'Reqd'}    = $in{'arms_hitsukin'}[$i];
    $pc{'weapon'.($i+1).'Acc'}     = $in{'arms_hit_mod'}[$i] *1;
    $pc{'weapon'.($i+1).'Rate'}    = $in{'arms_iryoku'}[$i];
    $pc{'weapon'.($i+1).'Crit'}    = $in{'arms_critical'}[$i];
    $pc{'weapon'.($i+1).'Dmg'}     = $in{'arms_damage_mod'}[$i] *1;
    $pc{'weapon'.($i+1).'Note'}    = $in{'arms_memo'}[$i];
    $pc{'weapon'.($i+1).'Class'}   = $skills{$in{'V_arms_hit_ginou'}[$i]};
    $pc{'weapon'.($i+1).'Category'}= $in{'arms_cate'}[$i];
    $pc{'weapon'.($i+1).'Own'}     = $in{'arms_is_senyou'}[$i] ? 1: '';
    $i++;
  }
  $pc{'weaponNum'} = $i;
  ## 装飾品(その他以外)
  my $i = 0;
  foreach ('','_','__') {
    $pc{'accessoryHead'.$_.'Name'}  = $in{'acce1_name'}[$i]; $pc{'accessoryHead'.$_.'Note'}  = $in{'acce1_memo' }[$i];
    $pc{'accessoryEar'.$_.'Name'}   = $in{'acce2_name'}[$i]; $pc{'accessoryEar'.$_.'Note'}   = $in{'acce2_memo' }[$i];
    $pc{'accessoryFace'.$_.'Name'}  = $in{'acce3_name'}[$i]; $pc{'accessoryFace'.$_.'Note'}  = $in{'acce3_memo' }[$i];
    $pc{'accessoryNeck'.$_.'Name'}  = $in{'acce4_name'}[$i]; $pc{'accessoryNeck'.$_.'Note'}  = $in{'acce4_memo' }[$i];
    $pc{'accessoryBack'.$_.'Name'}  = $in{'acce5_name'}[$i]; $pc{'accessoryBack'.$_.'Note'}  = $in{'acce5_memo' }[$i];
    $pc{'accessoryHandR'.$_.'Name'} = $in{'acce6_name'}[$i]; $pc{'accessoryHandR'.$_.'Note'} = $in{'acce6_memo' }[$i];
    $pc{'accessoryHandL'.$_.'Name'} = $in{'acce7_name'}[$i]; $pc{'accessoryHandL'.$_.'Note'} = $in{'acce7_memo' }[$i];
    $pc{'accessoryWaist'.$_.'Name'} = $in{'acce8_name'}[$i]; $pc{'accessoryWaist'.$_.'Note'} = $in{'acce8_memo' }[$i];
    $pc{'accessoryLeg'.$_.'Name'}   = $in{'acce9_name'}[$i]; $pc{'accessoryLeg'.$_.'Note'}   = $in{'acce9_memo' }[$i];
    $pc{'accessoryHead'.$_.'Own'}  = $in{'acce1_senyou'}[$i] eq 1 ? 'HP' : $in{'acce1_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryEar'.$_.'Own'}   = $in{'acce2_senyou'}[$i] eq 1 ? 'HP' : $in{'acce2_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryFace'.$_.'Own'}  = $in{'acce3_senyou'}[$i] eq 1 ? 'HP' : $in{'acce3_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryNeck'.$_.'Own'}  = $in{'acce4_senyou'}[$i] eq 1 ? 'HP' : $in{'acce4_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryBack'.$_.'Own'}  = $in{'acce5_senyou'}[$i] eq 1 ? 'HP' : $in{'acce5_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryHandR'.$_.'Own'} = $in{'acce6_senyou'}[$i] eq 1 ? 'HP' : $in{'acce6_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryHandL'.$_.'Own'} = $in{'acce7_senyou'}[$i] eq 1 ? 'HP' : $in{'acce7_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryWaist'.$_.'Own'} = $in{'acce8_senyou'}[$i] eq 1 ? 'HP' : $in{'acce8_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryLeg'.$_.'Own'}   = $in{'acce9_senyou'}[$i] eq 1 ? 'HP' : $in{'acce9_senyou'}[$i] eq 2 ? 'MP' : '';
    $pc{'accessoryHead'.$_.'Add'}   = $in{'acce1_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryEar'.$_.'Add'}    = $in{'acce2_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryFace'.$_.'Add'}   = $in{'acce3_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryNeck'.$_.'Add'}   = $in{'acce4_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryBack'.$_.'Add'}   = $in{'acce5_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryHandR'.$_.'Add'}  = $in{'acce6_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryHandL'.$_.'Add'}  = $in{'acce7_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryWaist'.$_.'Add'}  = $in{'acce8_name'}[$i+1] ? 1 : 0;
    $pc{'accessoryLeg'.$_.'Add'}    = $in{'acce9_name'}[$i+1] ? 1 : 0;
    $i++;
  }
  ## 所持品
  my $i = 0;
  foreach my $name (@{$in{'item_name'}}){
    if($name && $in{'item_tanka'}[$i] && $in{'item_num'}[$i]){
      $pc{'items'} .= "${name} ($in{'item_tanka'}[$i]) × $in{'item_num'}[$i]".($in{'item_memo'}[$i] ? ' …… ': '').$in{'item_memo'}[$i]."\n";
      $pc{'cashbook'} .= "${name} ::-$in{'item_tanka'}[$i]*$in{'item_num'}[$i]\n";
    }
    elsif($name){
      $pc{'items'} .= "${name}".($in{'item_memo'}[$i] ? ' …… ': '').$in{'item_memo'}[$i]."\n";
      $pc{'cashbook'} .= "${name}\n";
    }
    else {
      $pc{'items'} .= "\n";
      $pc{'cashbook'} .= "\n";
    }
    $i++;
  }
  ## 名誉
  my $i = 0;
  foreach my $name (@{$in{'honorout_item_name'}}){
    $pc{'honorItem'.($i+1)}      = $name;
    $pc{'honorItem'.($i+1).'Pt'} = $in{'honorout_item_point'}[$i];
    $i++;
  }
  $pc{'honorItemsNum'} = $i;
  ## 履歴
  my %bases = ( '1'=>'器用', '2'=>'敏捷', '3'=>'筋力', '4'=>'生命', '5'=>'知力', '6'=>'精神' );
  my $i = 0;
  foreach my $grow (@{$in{'V_SN_his'}}){
    $pc{'history'.($i+1).'Exp'}   = $in{'get_exp_his'}[$i];
    $pc{'history'.($i+1).'Money'} = $in{'get_money_his'}[$i];
    $pc{'history'.($i+1).'Grow'}  = $bases{$grow};
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    $i++;
  }
  $i++;
  $pc{'history'.$i.'Honor'} = $in{'honor_point_sum'};
  $pc{'history'.$i.'Note'} = 'データ形式が異なる為、獲得名誉点はここに纏めて記します。';
  $pc{'historyNum'} = $i;
  ## プロフィール追加
  my $profile;
  $profile .= ":身長|$in{'pc_height'}&lt;br&gt;";
  $profile .= ":体重|$in{'pc_weight'}&lt;br&gt;";
  $profile .= ": 髪 |$in{'color_hair'}&lt;br&gt;";
  $profile .= ": 瞳 |$in{'color_eye'}&lt;br&gt;";
  $profile .= ": 肌 |$in{'color_skin'}&lt;br&gt;";
  $profile .= ":経歴|$in{'keireki'}[0]&lt;br&gt;";
  $profile .= ":    |$in{'keireki'}[1]&lt;br&gt;";
  $profile .= ":    |$in{'keireki'}[2]&lt;br&gt;";
  
  $pc{'freeNote'} = $profile.$in{'pc_making_memo'},
  
  ## 〆
  $pc{'ver'} = 0;
  return %pc;
}
### 旧ゆとシート --------------------------------------------------
sub convert1to2 {
  my %pc = %{$_[0]};
  $pc{'convertSource'} = '旧ゆとシート';
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