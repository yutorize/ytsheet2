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
  ## 旧ゆとシート
  {
    foreach my $url (keys %set::convert_url){
      if($set_url =~ s"^${url}data/(.*?).html"$1"){
        open my $IN, '<', "$set::convert_url{$url}data/${set_url}.cgi" or error '旧ゆとシートのデータが開けませんでした';
        my %pc;
        $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
        close($IN);
        if($pc{'部位数'}){
          return convertMto2(\%pc);
        }
        else { return convert1to2(\%pc); }
      }
    }
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
      error 'コンバート元のゆとシートⅡでエラーがありました。<br>>'.$pc{result};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

sub getItemData {
  my $set_url = shift;
  my $file;
  ## 同じゆとシートⅡ
  my $self = CGI->new()->url;
  if($set_url =~ m"^$self\?id=(.+?)(?:$|&)"){
    my $id = $1;
    my ($file, $type, $author) = getfile_open($id);
    my %pc;
    open my $IN, '<', "$set::lib_type{i}{dataDir}${file}/data.cgi" or return;
    while (<$IN>){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    $pc{convertSource} = '同じゆとシートⅡ';
    return %pc;
  }
  ## 他のゆとシートⅡ
  {
    my $data = urlDataGet($set_url.'&mode=json') or return;
    if($data !~ /^{/){ return }
    $data = escapeThanSign($data);
    my %pc = utf8::is_utf8($data) ? %{ decode_json(encode('utf8', (join '', $data))) } : %{ decode_json(join '', $data) };
    if($pc{result} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    else {
      return;
    }
  }
}

### キャラクター保管所 --------------------------------------------------
sub convertHokanjoToYtsheet {
  my %in = %{$_[0]};

  my %pc = (
    convertSource => 'キャラクター保管所',
    characterName => $in{'pc_name'} || $in{'data_title'},
    tags => convertTags($in{'pc_tags'}),
    race => $in{'shuzoku_name'},
    birth => $in{'umare_name'},
    age => $in{'age'},
    gender => $in{'sex'},
    sin => $in{'V_kegare'},
    money => $in{'money'},
    deposit => $in{'debt'},
    sttBaseTec => $in{'N_waza'}, sttBasePhy => $in{'N_karada'}, sttBaseSpi => $in{'N_kokoro'},
    sttBaseA => $in{'V_NC1'}, sttAddA => ($in{'NP1'}-$in{'N_waza'  }-$in{'V_NC1'}-$in{'NS1'}) || '', 
    sttBaseB => $in{'V_NC2'}, sttAddB => ($in{'NP2'}-$in{'N_waza'  }-$in{'V_NC2'}-$in{'NS2'}) || '',
    sttBaseC => $in{'V_NC3'}, sttAddC => ($in{'NP3'}-$in{'N_karada'}-$in{'V_NC3'}-$in{'NS3'}) || '',
    sttBaseD => $in{'V_NC4'}, sttAddD => ($in{'NP4'}-$in{'N_karada'}-$in{'V_NC4'}-$in{'NS4'}) || '',
    sttBaseE => $in{'V_NC5'}, sttAddE => ($in{'NP5'}-$in{'N_kokoro'}-$in{'V_NC5'}-$in{'NS5'}) || '',
    sttBaseF => $in{'V_NC6'}, sttAddF => ($in{'NP6'}-$in{'N_kokoro'}-$in{'V_NC6'}-$in{'NS6'}) || '',
    lvFig => $in{'V_GLv1'} || '', lvGra => $in{'V_GLv2'} || '', lvFen => $in{'V_GLv3'} || '', lvSho => $in{'V_GLv4'} || '',
    lvSor => $in{'V_GLv5'} || '', lvCon => $in{'V_GLv6'} || '', lvPri => $in{'V_GLv7'} || '',
    lvFai => $in{'V_GLv8'} || '', lvMag => $in{'V_GLv9'} || '', lvDem => $in{'V_GLv17'} || '', lvDru => $in{'V_GLv24'} || '',
    lvSco => $in{'V_GLv10'} || '',lvRan => $in{'V_GLv11'} || '',lvSag => $in{'V_GLv12'} || '',
    lvEnh => $in{'V_GLv13'} || '', lvBar => $in{'V_GLv14'} || '', lvRid => $in{'V_GLv16'} || '',
    lvAlc => $in{'V_GLv15'} || '', lvWar => $in{'V_GLv18'} || '', lvMys => $in{'V_GLv19'} || '', lvPhy => $in{'V_GLv20'} || '',
    lvGri => $in{'V_GLv21'} || '', lvArt => $in{'V_GLv22'} || '', lvAri => $in{'V_GLv23'} || '',
    magicPowerAdd => $in{'arms_maryoku_sum'},
    evasionClass => $in{'kaihi_ginou_name'},
    armourNum => 3,
    armour1Name => $in{'armor_name'},
    armour1Reqd => $in{'armor_hitsukin'},
    armour1Note => $in{'armor_memo'},
    armour1Def => $in{'armor_bougo'} || 0,
    armour1Eva => $in{'armor_kaihi'} || 0,
    armour2Name => $in{'shield_name'},
    armour2Category => '盾',
    armour2Reqd => $in{'shield_hitsukin'},
    armour2Note => $in{'shield_memo'},
    armour2Def => $in{'shield_bougo'} || 0,
    armour2Eva => $in{'shield_kaihi'} || 0,
    armour3Name => $in{'shield2_name'},
    armour3Category => 'その他',
    armour3Name => $in{'shield2_name'},
    armour3Def =>$in{'shield2_bougo'} || 0,
    armour3Eva =>$in{'shield2_kaihi'} || 0,
    armour3Note => $in{'shield2_memo'},
    
    accessoryOtherName    => $in{'acce10_name'}[0], accessoryOtherNote    => $in{'acce10_memo'}[0],
    accessoryOtherOwn     => $in{'acce10_senyou'}[0] eq 1 ? 'HP' : $in{'acce10_senyou'}[0] eq 2 ? 'MP' : '',
    accessoryOtherAdd     => $in{'acce10_name'}[1] ? 1 : 0,
    accessoryOther_Name   => $in{'acce10_name'}[1], accessoryOther_Note   => $in{'acce10_memo'}[1],
    accessoryOther_Own    => $in{'acce10_senyou'}[1] eq 1 ? 'HP' : $in{'acce10_senyou'}[1] eq 2 ? 'MP' : '',
    accessoryOther_Add    => $in{'acce10_name'}[2] ? 1 : 0,
    accessoryOther__Name  => $in{'acce10_name'}[2], accessoryOther__Note  => $in{'acce10_memo'}[2],
    accessoryOther__Own    => $in{'acce10_senyou'}[2] eq 1 ? 'HP' : $in{'acce10_senyou'}[2] eq 2 ? 'MP' : '',
    
    accessoryOther2Name   => $in{'acce10_name'}[3], accessoryOther2Note   => $in{'acce10_memo'}[3],
    accessoryOther2Own    => $in{'acce10_senyou'}[3] eq 1 ? 'HP' : $in{'acce10_senyou'}[3] eq 2 ? 'MP' : '',
    accessoryOther2Add    => $in{'acce10_name'}[4] ? 1 : 0,
    accessoryOther2_Name  => $in{'acce10_name'}[4], accessoryOther2_Note  => $in{'acce10_memo'}[4],
    accessoryOther2_Own   => $in{'acce10_senyou'}[4] eq 1 ? 'HP' : $in{'acce10_senyou'}[4] eq 2 ? 'MP' : '',
    accessoryOther2_Add   => $in{'acce10_name'}[5] ? 1 : 0,
    accessoryOther2__Name => $in{'acce10_name'}[5], accessoryOther2__Note => $in{'acce10_memo'}[5],
    accessoryOther2__Own  => $in{'acce10_senyou'}[5] eq 1 ? 'HP' : $in{'acce10_senyou'}[5] eq 2 ? 'MP' : '',
    
    accessoryOther3Name   => $in{'acce10_name'}[6], accessoryOther3Note   => $in{'acce10_memo'}[6],
    accessoryOther3Own    => $in{'acce10_senyou'}[6] eq 1 ? 'HP' : $in{'acce10_senyou'}[6] eq 2 ? 'MP' : '',
    accessoryOther3Add    => $in{'acce10_name'}[7] ? 1 : 0,
    accessoryOther3_Name  => $in{'acce10_name'}[7], accessoryOther3_Note  => $in{'acce10_memo'}[7],
    accessoryOther3_Own   => $in{'acce10_senyou'}[7] eq 1 ? 'HP' : $in{'acce10_senyou'}[7] eq 2 ? 'MP' : '',
    accessoryOther3_Add   => $in{'acce10_name'}[8] ? 1 : 0,
    accessoryOther3__Name => $in{'acce10_name'}[8], accessoryOther3__Note => $in{'acce10_memo'}[8],
    accessoryOther3__Own  => $in{'acce10_senyou'}[8] eq 1 ? 'HP' : $in{'acce10_senyou'}[8] eq 2 ? 'MP' : '',
    
    accessoryOther4Name   => $in{'acce10_name'}[9], accessoryOther3Note   => $in{'acce10_memo'}[9],
    accessoryOther4Own    => $in{'acce10_senyou'}[9] eq 1 ? 'HP' : $in{'acce10_senyou'}[9] eq 2 ? 'MP' : '',
    accessoryOther4Add    => $in{'acce10_name'}[10] ? 1 : 0,
    accessoryOther4_Name  => $in{'acce10_name'}[10], accessoryOther3_Note  => $in{'acce10_memo'}[10],
    accessoryOther4_Own   => $in{'acce10_senyou'}[10] eq 1 ? 'HP' : $in{'acce10_senyou'}[10] eq 2 ? 'MP' : '',
    accessoryOther4_Add   => $in{'acce10_name'}[11] ? 1 : 0,
    accessoryOther4__Name => $in{'acce10_name'}[11], accessoryOther3__Note => $in{'acce10_memo'}[11],
    accessoryOther4__Own  => $in{'acce10_senyou'}[11] eq 1 ? 'HP' : $in{'acce10_senyou'}[11] eq 2 ? 'MP' : '',
  );
  ## 種族
  if($in{'special_shuzoku_name'}){
    my $parent = $in{'special_shuzoku_name'};
    if   ($parent =~ /第1/){ $pc{race} .= '（ルミエル）'; }
    elsif($parent =~ /第2/){ $pc{race} .= '（イグニス）'; }
    elsif($parent =~ /第3/){ $pc{race} .= '（カルディア）'; }
    elsif($parent =~ s/生まれ$//){
      $pc{race} .= '（'.$parent.'）';
    }
  }
  ## 信仰
  if($in{'priest_sinkou'}){
    require $set::data_faith;
    foreach (@data::gods){
      my $aka = @{$_}[2];
      my $name = @{$_}[3];
      if(
          ($in{'priest_sinkou'} eq "“${aka}”${name}")
        ||($in{'priest_sinkou'} eq "${aka}${name}") 
        ||($aka  && $in{'priest_sinkou'} =~ /(^|[“”"])${aka}([“”"]|$)/)
        ||($name && $in{'priest_sinkou'} eq $name)
      ){
        $pc{faith} = $aka && $name ? "“${aka}”${name}" : $aka ? "“${aka}”" : $name;
        last;
      }
    }
    if(!$pc{faith}){
      $pc{faithOther} = $in{'priest_sinkou'};
      $pc{faith} = 'その他の信仰';
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
  #require $set::data_races;
  #foreach my $lang (@language){
  #  my $next;
  #  foreach my $default (@{$data::race_language{$pc{race}}}){
  #    if(@$lang[0] eq @$default[0]){ $next = 1; last; }
  #  }
  #  next if $next;
  #  $pc{'language'.$i} = @$lang[0];
  #  $pc{'language'.$i.'Talk'} = @$lang[1];
  #  $pc{'language'.$i.'Read'} = @$lang[2];
  #  $i++;
  #}
  $pc{languageNum} = $i;
  $pc{languageAutoOff} = 1;
  
  foreach my $n (1 .. $pc{languageNum}){
    if($pc{race} =~ /人間/ && $pc{"language${n}"} =~ /地方語/){
      $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      last;
    }
  }
  foreach my $n (1 .. $pc{languageNum}){
    if(($pc{lvDem} || $pc{lvGri}) && $pc{"language${n}"} =~ /魔法文明語/){
      $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
    }
    if($pc{lvDem} && $pc{"language${n}"} =~ /魔神語/){
      $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
    }
    if(($pc{lvSor} || $pc{lvCon}) && $pc{"language${n}"} =~ /魔法文明語/){
      $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
    }
    if(($pc{lvMag} || $pc{lvAlc}) && $pc{"language${n}"} =~ /魔動機文明語/){
      $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
    }
    if($pc{lvFai} && $pc{"language${n}"} =~ /妖精語/){
      $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
    }
  }
  my $bard = 0;
  foreach my $n (reverse 1 .. $pc{languageNum}){
    last if $bard >= $pc{lvBar};
    if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Bar'; $bard++; }
  }
  my $sage = 0;
  foreach my $n (reverse 1 .. $pc{languageNum}){
    last if $sage >= $pc{lvSag};
    if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Sag'; $sage++; }
    last if $sage >= $pc{lvSag};
    if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'Sag'; $sage++; }
  }
  foreach my $n (1 .. $pc{languageNum}){
    if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'auto'; }
    if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'auto'; }
  }
  
  ## 戦闘特技
  my %nums = ('1'=>'Ⅰ', '2'=>'Ⅱ', '3'=>'Ⅲ', '4'=>'Ⅳ', '5'=>'Ⅴ');
  my $i = 0;
  foreach my $lv (@{$in{'ST_lv'}}){
    $pc{'combatFeatsLv'.$lv} = $in{'ST_name'}[$i];
    $pc{'combatFeatsLv'.$lv} =~ s|/|／|;
    $pc{'combatFeatsLv'.$lv} =~ s|A|Ａ|;
    $pc{'combatFeatsLv'.$lv} =~ s|S|Ｓ|;
    $pc{'combatFeatsLv'.$lv} =~ s|MP|ＭＰ|;
    if(!$::SW2_0){
      $pc{'combatFeatsLv'.$lv} =~ s/^(精密射撃|魔法誘導)$/ターゲッティング/;
      $pc{'combatFeatsLv'.$lv} =~ s/^クリティカルキャスト$/クリティカルキャストⅠ/;
    }
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
    if($::SW2_0){ $pc{'craftCommand'.($i+1)} =~ s/涛/濤/g; }
    else        { $pc{'craftCommand'.($i+1)} =~ s/濤/涛/g; }
    $pc{'magicGramarye'.($i+1)} =~ s/[=＝]/＝/g;
    foreach(@{$data::class{'グリモワール'}{'magic'}{'data'}}){
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
  $pc{weaponNum} = $i;
  ## 防具
  $pc{defTotal1CheckArmour1} = $pc{defTotal1CheckShield1} = $pc{defTotal1CheckDefOther1} = $pc{defTotal1CheckDefOther2} = $pc{defTotal1CheckDefOther3} = 1;
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
  ## 名誉
  my $i = 0;
  foreach my $name (@{$in{'honorout_item_name'}}){
    $pc{'honorItem'.($i+1)}      = $name;
    $pc{'honorItem'.($i+1).'Pt'} = $in{'honorout_item_point'}[$i];
    $i++;
  }
  $pc{honorItemsNum} = $i;
  ## 履歴
  $pc{history0Exp}   = $in{'create_exp'}+$in{'create_ginou_exp'};
  $pc{history0Honor} = 0;
  $pc{history0Money} = 1200;
  my %bases = ( '1'=>'器用', '2'=>'敏捷', '3'=>'筋力', '4'=>'生命', '5'=>'知力', '6'=>'精神' );
  my $i = 0; my $growcount;
  foreach my $grow (@{$in{'V_SN_his'}}){
    $pc{'history'.($i+1).'Exp'}   = $in{'get_exp_his'}[$i];
    $pc{'history'.($i+1).'Money'} = $in{'get_money_his'}[$i];
    $pc{'history'.($i+1).'Grow'}  = $bases{$grow};
    $pc{'history'.($i+1).'Note'}  = $in{'seicho_memo_his'}[$i];
    $i++;
    $growcount++ if $bases{$grow};
  }
  $i++;
  if(!$growcount){
    $pc{sttPreGrowA} = $in{'NS1'};
    $pc{sttPreGrowB} = $in{'NS2'};
    $pc{sttPreGrowC} = $in{'NS3'};
    $pc{sttPreGrowD} = $in{'NS4'};
    $pc{sttPreGrowE} = $in{'NS5'};
    $pc{sttPreGrowF} = $in{'NS6'};
  }
  $pc{'history'.$i.'Honor'} = $in{'honor_point_sum'};
  $pc{'history'.$i.'Note'} = 'データ形式が異なる為、獲得名誉点はここに纏めて記します。';
  $pc{historyNum} = $i;
  ## プロフィール追加
  my $profile;
  $profile .= ":身長|$in{'pc_height'}\n";
  $profile .= ":体重|$in{'pc_weight'}\n";
  $profile .= ": 髪 |$in{'color_hair'}\n";
  $profile .= ": 瞳 |$in{'color_eye'}\n";
  $profile .= ": 肌 |$in{'color_skin'}\n";
  $profile .= ":経歴|$in{'keireki'}[0]\n";
  $profile .= ":    |$in{'keireki'}[1]\n";
  $profile .= ":    |$in{'keireki'}[2]\n";
  
  $pc{freeNote} = $profile.$in{'pc_making_memo'},
  $pc{freeNoteView} = (unescapeTags unescapeTagsLines $profile).$in{'pc_making_memo'};
  $pc{freeNoteView} =~ s/\r\n?|\n/<br>/g;
  
  ## チャットパレット
  $pc{paletteUseBuff} = 1;
  
  ## 〆
  $pc{ver} = 0;
  return %pc;
}
### 旧ゆとシート --------------------------------------------------
sub convert1to2 {
  my %pc = %{$_[0]};
  $pc{convertSource} = '旧ゆとシート';
  
  $pc{playerName} = $pc{player};
  
  $pc{characterName} = $pc{name};
  $pc{aka} = $pc{title};
  $pc{words} = $pc{word};
  
  $pc{tags} = $pc{tag};
  
  $pc{history0Exp}   = $pc{make_exp};
  $pc{history0Money} = $pc{make_money};
  $pc{history0Honor} = $pc{make_honor};
  $pc{sttPreGrowA} = $pc{make_grow_A};
  $pc{sttPreGrowB} = $pc{make_grow_B};
  $pc{sttPreGrowC} = $pc{make_grow_C};
  $pc{sttPreGrowD} = $pc{make_grow_D};
  $pc{sttPreGrowE} = $pc{make_grow_E};
  $pc{sttPreGrowF} = $pc{make_grow_F};
  
  foreach my $key (keys %data::class){
    my $id = $data::class{$key}{'id'};
    $pc{'lv'.$id} = $pc{'lv_'.lc($id)} || '';
  }
  $pc{lvSeeker} = $pc{lv_seeker};
  $pc{level} = $pc{lv};
  
  foreach my $i (1..10){ $pc{'commonClass'.$i} = $pc{'common'.$i}; }
  
  $pc{race}   = $pc{prof_race};
  $pc{gender} = $pc{prof_sex};
  $pc{age}    = $pc{prof_age};
  $pc{birth}  = $pc{prof_birth};
  $pc{sttBaseTec} = $pc{stt_base_tec};
  $pc{sttBasePhy} = $pc{stt_base_phy};
  $pc{sttBaseSpi} = $pc{stt_base_spi};
  $pc{sttBaseA} = $pc{stt_base_A};
  $pc{sttBaseB} = $pc{stt_base_B};
  $pc{sttBaseC} = $pc{stt_base_C};
  $pc{sttBaseD} = $pc{stt_base_D};
  $pc{sttBaseE} = $pc{stt_base_E};
  $pc{sttBaseF} = $pc{stt_base_F};
  $pc{sttGrowA} = $pc{stt_grow_A};
  $pc{sttGrowB} = $pc{stt_grow_B};
  $pc{sttGrowC} = $pc{stt_grow_C};
  $pc{sttGrowD} = $pc{stt_grow_D};
  $pc{sttGrowE} = $pc{stt_grow_E};
  $pc{sttGrowF} = $pc{stt_grow_F};
  $pc{sttAddA} = s_eval($pc{stt_rein_A});
  $pc{sttAddB} = s_eval($pc{stt_rein_B});
  $pc{sttAddC} = s_eval($pc{stt_rein_C});
  $pc{sttAddD} = s_eval($pc{stt_rein_D});
  $pc{sttAddE} = s_eval($pc{stt_rein_E});
  $pc{sttAddF} = s_eval($pc{stt_rein_F});
  
  $pc{pointbuyType} = '2.0';
  
  $pc{hpAdd} = $pc{stt_rev_hp};
  $pc{mpAdd} = $pc{stt_rev_mp};
  $pc{vitResistAdd} = $pc{stt_rev_resistv};
  $pc{mndResistAdd} = $pc{stt_rev_resistm};
  
  foreach my $lv (1..20){
    $pc{'combatFeatsLv'.$lv} = $pc{'ability_lv'.$lv};
    $pc{'combatFeatsLv'.$lv} =~ s|/|／|;
    $pc{'combatFeatsLv'.$lv} =~ s|A|Ａ|;
    $pc{'combatFeatsLv'.$lv} =~ s|S|Ｓ|;
    $pc{'combatFeatsLv'.$lv} =~ s|MP|ＭＰ|;
    $pc{'combatFeatsLv'.$lv} =~ s|習熟／|習熟Ａ／|;
    $pc{'combatFeatsLv'.$lv} =~ s|習熟Ⅱ|習熟Ｓ|;
    $pc{'combatFeatsLv'.$lv} =~ s/^(全力|必殺|牽制)攻撃$/$1攻撃Ⅰ/;
    $pc{'magicSorcery'.$lv}    = $pc{'transcend_sorcery'.$lv};
    $pc{'magicConjury'.$lv}    = $pc{'transcend_conjury'.$lv};
    $pc{'magicWizardry'.$lv}   = $pc{'transcend_wizardry'.$lv};
    $pc{'magicHolypray'.$lv}   = $pc{'transcend_divinity'.$lv};
    $pc{'magicMagitech'.$lv}   = $pc{'ranscend_magitech'.$lv};
    $pc{'magicDemonology'.$lv} = $pc{'transcend_demonism'.$lv};
    $pc{'magicGramarye'.$lv}   = $pc{'secret'.$lv};
    $pc{'craftEnhance'.$lv}    = $pc{'enhance'.$lv};
    $pc{'craftSong'.$lv}       = $pc{'song'.$lv};
    $pc{'craftRiding'.$lv}     = $pc{'riding'.$lv};
    $pc{'craftAlchemy'.$lv}    = $pc{'alchemy'.$lv};
    $pc{'craftCommand'.$lv}    = $pc{'command'.$lv};
    $pc{'craftDivination'.$lv} = $pc{'divination'.$lv};
    $pc{'craftPotential'.$lv}  = $pc{'potential'.$lv};
    $pc{'craftSeal'.$lv}       = $pc{'seal'.$lv};
    $pc{'craftDignity'.$lv}    = $pc{'dignity'.$lv};
  }
  
  $pc{languageNum} = $pc{lgct};
  foreach my $i (1 .. $pc{languageNum}){
    $pc{"language${i}"}   = $pc{"lang_name$i"};
    $pc{"language${i}Talk"} = $pc{"lang_speak$i"};
    $pc{"language${i}Read"} = $pc{"lang_read$i"};
  }
  
  $pc{honorItemsNum} = $pc{hnct};
  foreach my $i (1 .. $pc{honorItemsNum}){
    $pc{"honorItem${i}"}   = $pc{"honor_name$i"};
    $pc{"honorItem${i}Pt"} = $pc{"honor_num$i"};
  }
  $pc{dishonorItemsNum} = $pc{dhnct};
  foreach my $i (1 .. $pc{dishonorItemsNum}){
    $pc{"dishonorItem${i}"}   = $pc{"dishonor_name$i"};
    $pc{"dishonorItem${i}Pt"} = $pc{"dishonor_num$i"};
  }
  foreach my $i (1..20){
    next if (!$pc{"school$i"});
    my $pt;
    if($pc{"school".$i."_honor"}){ $pt = $pc{"school".$i."_honor"}; }
    elsif($pc{"school$i"} =~ /^ルキスラ/){ $pt = 70 }
    elsif($pc{"school$i"} =~ /^ニルデス/){ $pt = -30 }
    else { $pt = 50; }
    if($pt > 0){
      $pc{honorItemsNum}++;
      $pc{"honorItem".$pc{honorItemsNum}} = '入門：【'.($pc{"school$_"."_name"}||$pc{"school$i"}).'】';
      $pc{"honorItem".$pc{honorItemsNum}.'Pt'} = $pt;
      
      if($pc{school1_expulsion}){
        $pc{dishonorItemsNum}++;
        $pc{"dishonorItem".$pc{dishonorItemsNum}} = '破門：【'.($pc{"school$_"."_name"}||$pc{"school$i"}).'】';
        $pc{"dishonorItem".$pc{dishonorItemsNum}.'Pt'} = $pt;
      }
    }
    elsif($pt < 0){
      $pc{dishonorItemsNum}++;
      $pc{"dishonorItem".$pc{dishonorItemsNum}} = '入門：【'.($pc{"school$_"."_name"}||$pc{"school$i"}).'】';
      $pc{"dishonorItem".$pc{dishonorItemsNum}.'Pt'} = $pt;
    }
    
    foreach(my $n = 1; $n <= $pc{'school'.$i.'_mystery_num'}; $n++){
      if($pc{'school'.$i.'_mystery'.$n}){
        $pc{mysticArtsNum}++;
        $pc{'mysticArts'.$pc{mysticArtsNum}} = $pc{'school'.$i.'_mystery'.$n};
        $pc{'mysticArts'.$pc{mysticArtsNum}.'Pt'} = $pc{'school'.$i.'_mystery'.$n.'_honor'};
      }
    }
    foreach(my $n = 1; $n <= 3; $n++){
      if($pc{'school'.$i.'_weapon'.$n}){
        $pc{honorItemsNum}++;
        $pc{'honorItem'.$pc{honorItemsNum}} = $pc{'school'.$i.'_weapon'.$n};
        $pc{'honorItem'.$pc{honorItemsNum}.'Pt'} = $pc{'school'.$i.'_weapon'.$n.'_honor'};
      }
    }
  }
  
  
  $pc{weaponNum} = $pc{bkct};
  foreach my $i (1 .. $pc{weaponNum}){
    $pc{"weapon${i}Name"}     = $pc{"wpn_name$i"};
    $pc{"weapon${i}Usage"}    = $pc{"wpn_usage$i"};
    $pc{"weapon${i}Reqd"}     = $pc{"wpn_weight$i"};
    $pc{"weapon${i}Acc"}      = s_eval($pc{"wpn_hitrev$i"});
    $pc{"weapon${i}Rate"}     = $pc{"wpn_power$i"};
    $pc{"weapon${i}Crit"}     = $pc{"wpn_crit$i"};
    $pc{"weapon${i}Dmg"}      = s_eval($pc{"wpn_dmgrev$i"});
    $pc{"weapon${i}Own"}      = $pc{"wpn_person$i"};
    $pc{"weapon${i}Category"} = $pc{"wpn_category$i"};
    $pc{"weapon${i}Class"}    = $pc{"wpn_skill$i"};
    $pc{"weapon${i}Note"}     = $pc{"wpn_note$i"};
    
    foreach my $key (keys %data::class){
      my $id = lc($data::class{$key}{'id'});
      $pc{"weapon${i}Class"} =~ s/$id/$key/;
    }
    if($pc{"weapon${i}Class"} =~ s/sho+crs/シューター/){ $pc{"weapon${i}Category"} = 'クロスボウ'; }
    if($pc{"weapon${i}Class"} =~ s/sho+mag/シューター/){ $pc{"weapon${i}Category"} = 'ガン'; }
  }
  
  $pc{evasionClass} = $pc{avoid_skill};
  $pc{armour1Name} = $pc{amr_name};
  $pc{armour1Reqd} = $pc{amr_weight};
  $pc{armour1Eva}  = s_eval($pc{amr_avoid});
  $pc{armour1Def}  = s_eval($pc{amr_defense});
  $pc{armour1Own}  = $pc{amr_person};
  $pc{armour1Note} = $pc{amr_note};
  $pc{shield1Name} = $pc{sld_name};
  $pc{shield1Reqd} = $pc{sld_weight};
  $pc{shield1Eva}  = s_eval($pc{sld_avoid});
  $pc{shield1Def}  = s_eval($pc{sld_defense});
  $pc{shield1Own}  = $pc{sld_person};
  $pc{shield1Note} = $pc{sld_note};
  $pc{defOther1Name} = $pc{def_other_name};
  $pc{defOther1Eva} = s_eval($pc{def_other_avoid});
  $pc{defOther1Def} = s_eval($pc{def_other_defense});
  $pc{defOther1Note} = $pc{def_other_note};
  
  $pc{defTotal1CheckArmour1} = $pc{defTotal1CheckShield1} = $pc{defTotal1CheckDefOther1} = $pc{defTotal1CheckDefOther2} = $pc{defTotal1CheckDefOther3} = 1;
  
  foreach my $i ("Head","Face","Ear","Neck","Back","Waist","Leg","Other","Other2","Other3","Other4") {
    $pc{"accessory${i}Name"} = $pc{"acc_name_".lc($i)};
    $pc{"accessory${i}Add"}  = $pc{"acc_add_".lc($i)};
    $pc{"accessory${i}Own"}  = $pc{"acc_person_".lc($i)};
    $pc{"accessory${i}Note"} = $pc{"acc_note_".lc($i)};
    $pc{"accessory${i}_Name"} = $pc{"acc_name_".lc($i)."+"};
    $pc{"accessory${i}_Own"}  = $pc{"acc_person_".lc($i)."+"};
    $pc{"accessory${i}_Note"} = $pc{"acc_note_".lc($i)."+"};
  }
  $pc{accessoryHandRName} = $pc{acc_name_hand1};
  $pc{accessoryHandRAdd}  = $pc{acc_add_hand1};
  $pc{accessoryHandROwn}  = $pc{acc_person_hand1};
  $pc{accessoryHandRNote} = $pc{acc_note_hand1};
  $pc{accessoryHandR_Name} = $pc{"acc_name_hand1+"};
  $pc{accessoryHandR_Own}  = $pc{"acc_person_hand1+"};
  $pc{accessoryHandR_Note} = $pc{"acc_note_hand1+"};
  $pc{accessoryHandLName} = $pc{acc_name_hand2};
  $pc{accessoryHandLAdd}  = $pc{acc_add_hand2};
  $pc{accessoryHandLOwn}  = $pc{acc_person_hand1};
  $pc{accessoryHandLNote} = $pc{acc_note_hand2};
  $pc{accessoryHandL_Name} = $pc{"acc_name_hand2+"};
  $pc{accessoryHandL_Own}  = $pc{"acc_person_hand2+"};
  $pc{accessoryHandL_Note} = $pc{"acc_note_hand2+"};
  
  
  $pc{fairyContractEarth} = $pc{fairy_class1};
  $pc{fairyContractWater} = $pc{fairy_class2};
  $pc{fairyContractFire}  = $pc{fairy_class3};
  $pc{fairyContractWind}  = $pc{fairy_class4};
  $pc{fairyContractLight} = $pc{fairy_class5};
  $pc{fairyContractDark}  = $pc{fairy_class6};
  
  $pc{historyNum} = $pc{hsct};
  foreach my $i (1 .. $pc{historyNum}){
    $pc{"history${i}Exp"}   = $pc{"hist_exp$i"};
    $pc{"history${i}Money"} = $pc{"hist_money$i"};
    $pc{"history${i}Honor"} = $pc{"hist_honor$i"};
  }
  
  $pc{items} = $pc{text_items};
  $pc{items} .= "\n------------------------------------\n".$pc{text_original} if $pc{text_original};
  $pc{freeNote} = $pc{text_free};
  $pc{freeHistory} = $pc{text_history};
  
  $pc{deposit} = $pc{money_save};
  
  $pc{paletteUseBuff} = 1;

  $pc{ver} = 0;
  return %pc;
}
### 旧ゆとシート --------------------------------------------------
sub convertMto2 {
  my %pc = %{$_[0]};
  $pc{convertSource} = '旧ゆとシートM';
  
  $pc{auther} = $pc{'作成者'};
  
  $pc{characterName} = $pc{'名前'};
  $pc{monsterName} = $pc{'名称'};
  
  $pc{lv} = $pc{'レベル'};
  $pc{taxa} = $pc{'種別'} ==  1 ? '蛮族'
              : $pc{'種別'} ==  2 ? '動物'
              : $pc{'種別'} ==  3 ? '植物'
              : $pc{'種別'} ==  4 ? 'アンデッド'
              : $pc{'種別'} ==  5 ? '魔法生物'
              : $pc{'種別'} ==  6 ? '幻獣'
              : $pc{'種別'} ==  7 ? '妖精'
              : $pc{'種別'} ==  8 ? '魔神'
              : $pc{'種別'} ==  9 ? '人族'
              : $pc{'種別'} == 10 ? '神族'
              : $pc{'種別'} == 11 ? 'その他'
              : '';

  $pc{intellect}   = $pc{'知能'};
  $pc{perception}  = $pc{'知覚'};
  $pc{disposition} = $pc{'反応'};
  $pc{language}    = $pc{'言語'};
  $pc{habitat}     = $pc{'生息地'};
  $pc{reputation}  = $pc{'知名度'};
  $pc{'reputation+'} = $pc{'弱点値'};
  $pc{weakness}    = $pc{'弱点'};
  $pc{initiative}  = $pc{'先制値'};
  $pc{mobility}    = $pc{'移動速度'};
  $pc{vitResist}   = s_eval $pc{'生命抵抗力'};
  $pc{mndResist}   = s_eval $pc{'精神抵抗力'};
  $pc{vitResistFix}= $pc{vitResist}+7;
  $pc{mndResistFix}= $pc{mndResist}+7;
  if($pc{taxa} eq 'アンデッド'){ $pc{sin} = 5; }
  
  $pc{partsNum} = $pc{'部位数'};
  $pc{parts} = $pc{'部位内訳'};
  $pc{coreParts} = $pc{'コア'};
  
  $pc{statusNum} = $pc{stct};
  foreach my $i (1 .. $pc{statusNum}){
    $pc{"status${i}Style"}    = $pc{'方法'.$i};
    $pc{"status${i}Accuracy"} = s_eval $pc{'命中'.$i};
    $pc{"status${i}AccuracyFix"} = $pc{"status${i}Accuracy"}+7;
    $pc{"status${i}Damage"}   = $pc{'打撃'.$i};
    $pc{"status${i}Evasion"}  = s_eval $pc{'回避'.$i};
    $pc{"status${i}EvasionFix"}  = $pc{"status${i}Evasion"}+7;
    $pc{"status${i}Defense"}  = $pc{'防護'.$i};
    $pc{"status${i}Hp"}       = $pc{'ＨＰ'.$i};
    $pc{"status${i}Mp"}       = $pc{'ＭＰ'.$i};
  }
  
  foreach my $i (1 .. $pc{tkct}){
    $pc{skills} .= "●$pc{'特部'.$i}\n";
    $pc{skills} .= "$pc{'能力'.$i}\n\n\n";
  }
  if(!$::SW2_0){
    $pc{skills} =~ s/(^|&lt;br&gt;)([○◯〆☆]*)[▽▼]/$1$2○/gim;
  }
  $pc{skills} =~ s/\n\n$//;
  
  $pc{lootsNum} = $pc{srct};
  foreach my $i (1 .. $pc{lootsNum}){
    $pc{"loots${i}Num"} .= $pc{'剥出目'.$i};
    $pc{"loots${i}Item"} .= $pc{'戦利品'.$i};
  }
  
  $pc{description} = $pc{'解説'};

  $pc{type} = 'm';
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