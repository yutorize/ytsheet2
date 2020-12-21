################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_syndrome;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my $conv_url = param('url');
my $file = $main::file;
my $backup = param('backup');
$SHEET->param("backupId" => $backup);

our %pc = ();
if($id){
  my $datafile = $backup ? "${set::char_dir}${file}/backup/${backup}.cgi" : "${set::char_dir}${file}/data.cgi";
  open my $IN, '<', $datafile or error 'キャラクターシートがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  if($backup){
    $pc{'protect'} = protectTypeGet("${set::char_dir}${file}/data.cgi");
  }
}
elsif($conv_url){
  %pc = %::conv_data;
  if(!$pc{'ver'}){
    require $set::lib_calc_char;
    %pc = data_calc(\%pc);
  }
  $SHEET->param("convertMode" => 1);
  $SHEET->param("convertUrl" => $conv_url);
}

$SHEET->param("id" => $id);

### 置換 --------------------------------------------------
foreach (keys %pc) {
  if($_ =~ /^(?:freeNote|freeHistory)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_});
}

### アップデート --------------------------------------------------
if($pc{'ver'}){
  %pc = data_update_chara(\%pc);
}

### テンプレ用に変換 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}

### 出力準備 #########################################################################################
### キャラクター名 --------------------------------------------------
{
  my($name, $ruby) = split(/:/,$pc{'characterName'});
  $SHEET->param("characterName" => "<ruby>$name<rt>$ruby</rt></ruby>") if $ruby;
}
### 二つ名 --------------------------------------------------
{
  my($aka, $ruby) = split(/:/,$pc{'aka'});
  $SHEET->param("aka" => "<ruby>$aka<rt>$ruby</rt></ruby>") if $ruby;
}
### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $id))[0];
  $SHEET->param("playerName" => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{'playerName'}.'</a>');
}
### グループ --------------------------------------------------
if($conv_url){
  $SHEET->param(group => '');
}
else {
  if(!$pc{'group'}) {
    $pc{'group'} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{'group'} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
}

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{'tags'})){
  push(@tags, {
    "URL"  => uri_escape_utf8($_),
    "TEXT" => $_,
  });
}
$SHEET->param(Tags => \@tags);

### セリフ --------------------------------------------------
$pc{'words'} =~ s/^「/<span class="brackets">「<\/span>/g;
$pc{'words'} =~ s/(.+?(?:[，、。？」]|$))/<span>$1<\/span>/g;
$SHEET->param("words" => $pc{'words'});
$SHEET->param("wordsX" => ($pc{'wordsX'} eq '左' ? 'left:0;' : 'right:0;'));
$SHEET->param("wordsY" => ($pc{'wordsY'} eq '下' ? 'bottom:0;' : 'top:0;'));

### ブリード --------------------------------------------------
$SHEET->param("breed" => 
  ($pc{'syndrome3'} ? 'トライ' : $pc{'syndrome2'} ? 'クロス' : $pc{'syndrome1'} ? 'ピュア' : '') . '<span>ブリード</span>'
);

### 能力値 --------------------------------------------------
my %status = (0=>'body', 1=>'sense', 2=>'mind', 3=>'social');
foreach my $num (keys %status){
  my $name = $status{$num};
  my $base = 0;
  $base += $data::syndrome_status{$pc{'syndrome1'}}[$num];
  $base += $pc{'syndrome2'} ? $data::syndrome_status{$pc{'syndrome2'}}[$num] : $base;
  $SHEET->param("sttBase".ucfirst($name) => $base);
}
$SHEET->param("sttWorks".ucfirst($pc{'sttWorks'}) => 1);

### 技能 --------------------------------------------------
foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
  $SHEET->param('skillTotal'.$name => ($pc{'skillAdd'.$name} ? "<span class=\"small\">+$pc{'skillAdd'.$name}=</span>" : '').$pc{'skillTotal'.$name});
}
my @skills;
foreach (1 .. $pc{'skillNum'}){
  push(@skills, {
    "RIDE" => $pc{'skillRide'.$_.'Name'}, "RIDELV" => ($pc{'skillAddRide'.$_}?"<span class=\"small\">+$pc{'skillAddRide'.$_}=</span>":'').$pc{'skillTotalRide'.$_},
    "ART"  => $pc{'skillArt' .$_.'Name'}, "ARTLV"  => ($pc{'skillAddArt'.$_} ?"<span class=\"small\">+$pc{'skillAddArt'.$_}=</span>" :'').$pc{'skillTotalArt'.$_} ,
    "KNOW" => $pc{'skillKnow'.$_.'Name'}, "KNOWLV" => ($pc{'skillAddKnow'.$_}?"<span class=\"small\">+$pc{'skillAddKnow'.$_}=</span>":'').$pc{'skillTotalKnow'.$_},
    "INFO" => $pc{'skillInfo'.$_.'Name'}, "INFOLV" => ($pc{'skillAddInfo'.$_}?"<span class=\"small\">+$pc{'skillAddInfo'.$_}=</span>":'').$pc{'skillTotalInfo'.$_},
  });
}
$SHEET->param(Skills => \@skills);

### ロイス --------------------------------------------------
my @loises;
foreach (1 .. 7){
  my $color;
  if   ($pc{'lois'.$_.'Color'} =~ /^(BK|BLA|黒)/i){ $color = 'hsla(  0,  0%,  0%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(BL|青)/i    ){ $color = 'hsla(220,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(GR|緑)/i    ){ $color = 'hsla(120,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(OR|橙)/i    ){ $color = 'hsla( 30,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(PU|紫)/i    ){ $color = 'hsla(270,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(RE|赤)/i    ){ $color = 'hsla(  0,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(WH|白)/i    ){ $color = 'hsla(  0,  0%,100%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(YE|黄)/i    ){ $color = 'hsla( 60,100%, 50%,0.2)'; }
  $color = $color ? "background-color:${color};" : '';
  push(@loises, {
    "RELATION" => $pc{'lois'.$_.'Relation'},
    "NAME"     => $pc{'lois'.$_.'Name'},
    "POSI"     => $pc{'lois'.$_.'EmoPosi'},
    "NEGA"     => $pc{'lois'.$_.'EmoNega'},
    "P-CHECK"  => $pc{'lois'.$_.'EmoPosiCheck'},
    "N-CHECK"  => $pc{'lois'.$_.'EmoNegaCheck'},
    "COLOR"    => $pc{'lois'.$_.'Color'},
    "COLOR-BG" => $color,
    "NOTE"     => $pc{'lois'.$_.'Note'},
    "STATE"    => $pc{'lois'.$_.'State'},
  });
}
$SHEET->param(Loises => \@loises);
$SHEET->param(Skills => \@skills);

### メモリー --------------------------------------------------
my @memories;
foreach (1 .. 3){
  next if !$pc{'memory'.$_.'Gain'};
  push(@memories, {
    "RELATION" => $pc{'memory'.$_.'Relation'},
    "NAME"     => $pc{'memory'.$_.'Name'},
    "EMOTION"  => $pc{'memory'.$_.'Emo'},
    "NOTE"     => $pc{'memory'.$_.'Note'},
    "STATE"    => $pc{'memory'.$_.'State'},
  });
}
$SHEET->param(Memories => \@memories);

### エフェクト --------------------------------------------------
my @effects;
foreach (1 .. $pc{'effectNum'}){
  next if(
    !$pc{'effect'.$_.'Name'}  && !$pc{'effect'.$_.'Lv'}       && !$pc{'effect'.$_.'Timing'} &&
    !$pc{'effect'.$_.'Skill'} && !$pc{'effect'.$_.'Dfclty'}   && !$pc{'effect'.$_.'Target'} && 
    !$pc{'effect'.$_.'Range'} && !$pc{'effect'.$_.'Encroach'} && !$pc{'effect'.$_.'Restrict'} &&
    !$pc{'effect'.$_.'Note'}  && !$pc{'effect'.$_.'Exp'}
  );
  push(@effects, {
    "TYPE"     => $pc{'effect'.$_.'Type'},
    "NAME"     => textShrink(13,15,17,21,$pc{'effect'.$_.'Name'}),
    "LV"       => $pc{'effect'.$_.'Lv'},
    "TIMING"   => textTiming($pc{'effect'.$_.'Timing'}),
    "SKILL"    => textSkill($pc{'effect'.$_.'Skill'}),
    "DFCLTY"   => textShrink(3,4,4,4,$pc{'effect'.$_.'Dfclty'}),
    "TARGET"   => textShrink(6,7,8,8,$pc{'effect'.$_.'Target'}),
    "RANGE"    => $pc{'effect'.$_.'Range'},
    "ENCROACH" => textShrink(3,4,4,4,$pc{'effect'.$_.'Encroach'}),
    "RESTRICT" => $pc{'effect'.$_.'Restrict'},
    "NOTE"     => $pc{'effect'.$_.'Note'},
    "EXP"      => ($pc{'effect'.$_.'Exp'} > 0 ? '+' : '').$pc{'effect'.$_.'Exp'},
  });
}
$SHEET->param(Effects => \@effects);
sub textTiming {
  my $text = shift;
  $text =~ s#[／\/]#<hr class="dotted">#g;
  $text =~ s#(オート|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  return $text;
}
sub textSkill {
  my $text = shift;
  $text =~ s#(〈.*?〉|【.*?】)#<span>$1</span>#g;
  $text =~ s#(シンドローム)#<span class="thin">$1</span>#g;
  return $text;
}
sub textShrink {
  my $thin    = shift;
  my $thiner  = shift;
  my $thinest = shift;
  my $small   = shift;
  my $text = shift;
  my $check = $text;
  $check =~ s|<rp>(.+?)</rp>||g;
  $check =~ s|<rt>(.+?)</rt>||g;
  $check =~ s|<.+?>||g;
  if(length($check) >= $small) {
    return '<span class="thinest small">'.$text.'</span>';
  }
  if(length($check) >= $thinest) {
    return '<span class="thinest">'.$text.'</span>';
  }
  elsif(length($check) >= $thiner) {
    return '<span class="thiner">'.$text.'</span>';
  }
  elsif(length($check) >= $thin) {
    return '<span class="thin">'.$text.'</span>';
  }
  return $text;
}

### コンボ --------------------------------------------------
my @combos;
foreach (1 .. $pc{'comboNum'}){
  next if(
    !$pc{'combo'.$_.'Name'}  && !$pc{'combo'.$_.'Combo'}    && !$pc{'combo'.$_.'Timing'} &&
    !$pc{'combo'.$_.'Skill'} && !$pc{'combo'.$_.'Dfclty'}   && !$pc{'combo'.$_.'Target'} && 
    !$pc{'combo'.$_.'Range'} && !$pc{'combo'.$_.'Encroach'} && !$pc{'combo'.$_.'Note'} && 
    !$pc{'combo'.$_.'Dice1'} && !$pc{'combo'.$_.'Crit1'} && !$pc{'combo'.$_.'Atk1'} && !$pc{'combo'.$_.'Fixed1'}
  );
  push(@combos, {
    "NAME"     => textShrink(15,17,19,23,$pc{'combo'.$_.'Name'}),
    "COMBO"    => textCombo($pc{'combo'.$_.'Combo'}),
    "TIMING"   => textTiming($pc{'combo'.$_.'Timing'}),
    "SKILL"    => textSkill($pc{'combo'.$_.'Skill'}),
    "DFCLTY"   => textShrink(3,4,4,4,$pc{'combo'.$_.'Dfclty'}),
    "TARGET"   => textShrink(6,7,8,8,$pc{'combo'.$_.'Target'}),
    "RANGE"    => $pc{'combo'.$_.'Range'},
    "ENCROACH" => textShrink(3,4,4,4,$pc{'combo'.$_.'Encroach'}),
    "NOTE"     => $pc{'combo'.$_.'Note'},
    "CONDITION1" => $pc{'combo'.$_.'Condition1'},
    "DICE1"      => $pc{'combo'.$_.'Dice1'},
    "CRIT1"      => $pc{'combo'.$_.'Crit1'},
    "ATK1"       => $pc{'combo'.$_.'Atk1'},
    "FIXED1"     => $pc{'combo'.$_.'Fixed1'},
    "CONDITION2" => $pc{'combo'.$_.'Condition2'},
    "DICE2"      => $pc{'combo'.$_.'Dice2'},
    "CRIT2"      => $pc{'combo'.$_.'Crit2'},
    "ATK2"       => $pc{'combo'.$_.'Atk2'},
    "FIXED2"     => $pc{'combo'.$_.'Fixed2'},
    "CONDITION3" => $pc{'combo'.$_.'Condition3'},
    "DICE3"      => $pc{'combo'.$_.'Dice3'},
    "CRIT3"      => $pc{'combo'.$_.'Crit3'},
    "ATK3"       => $pc{'combo'.$_.'Atk3'},
    "FIXED3"     => $pc{'combo'.$_.'Fixed3'},
    "CONDITION4" => $pc{'combo'.$_.'Condition4'},
    "DICE4"      => $pc{'combo'.$_.'Dice4'},
    "CRIT4"      => $pc{'combo'.$_.'Crit4'},
    "ATK4"       => $pc{'combo'.$_.'Atk4'},
    "FIXED4"     => $pc{'combo'.$_.'Fixed4'},
  });
}
$SHEET->param(Combos => \@combos);
sub textCombo {
  my $text = shift;
  if($text =~ /《.*?》/){
    $text =~ s#(《.*?》)#<span>$1</span>#g
  }
  elsif($text){
    my @array = split(/[+＋]/, $text);
    $text = '<span>'.join('</span>+<span>',@array).'</span>';
  }
  
  return $text;
}

### 武器 --------------------------------------------------
my @weapons;
foreach (1 .. $pc{'weaponNum'}){
  next if(
    !$pc{'weapon'.$_.'Name'}  && !$pc{'weapon'.$_.'Stock'} && !$pc{'weapon'.$_.'Exp'} &&
    !$pc{'weapon'.$_.'Skill'} && !$pc{'weapon'.$_.'Acc'}   && !$pc{'weapon'.$_.'Atk'} &&
    !$pc{'weapon'.$_.'Guard'} && !$pc{'weapon'.$_.'Range'} && !$pc{'weapon'.$_.'Note'} 
  );
  push(@weapons, {
    "NAME"     => textShrink(12,13,14,15,$pc{'weapon'.$_.'Name'}),
    "STOCK"    => $pc{'weapon'.$_.'Stock'},
    "EXP"      => $pc{'weapon'.$_.'Exp'},
    "TYPE"     => textType($pc{'weapon'.$_.'Type'}),
    "SKILL"    => textSkill(textShrink(4,5,6,7,$pc{'weapon'.$_.'Skill'})),
    "ACC"      => $pc{'weapon'.$_.'Acc'},
    "ATK"      => $pc{'weapon'.$_.'Atk'},
    "GUARD"    => $pc{'weapon'.$_.'Guard'},
    "RANGE"    => $pc{'weapon'.$_.'Range'},
    "NOTE"     => $pc{'weapon'.$_.'Note'},
  });
}
$SHEET->param(Weapons => \@weapons);
sub textType {
  my $text = shift;
  my @texts = split(/[／\/]/, $text);
  foreach (@texts){ textShrink(5,6,7,8,$_) }
  return join('<hr class="dotted">', @texts);
}

### 防具 --------------------------------------------------
my @armors;
foreach (1 .. $pc{'armorNum'}){
  next if(
    !$pc{'armor'.$_.'Name'}  && !$pc{'armor'.$_.'Stock'} && !$pc{'armor'.$_.'Exp'} && !$pc{'armor'.$_.'Initiative'} &&
    !$pc{'armor'.$_.'Dodge'} && !$pc{'armor'.$_.'Armor'} && !$pc{'armor'.$_.'Note'} 
  );
  push(@armors, {
    "NAME"       => textShrink(12,13,14,15,$pc{'armor'.$_.'Name'}),
    "STOCK"      => $pc{'armor'.$_.'Stock'},
    "EXP"        => $pc{'armor'.$_.'Exp'},
    "TYPE"       => textShrink(5,6,7,8,$pc{'armor'.$_.'Type'}),
    "INITIATIVE" => $pc{'armor'.$_.'Initiative'},
    "DODGE"      => $pc{'armor'.$_.'Dodge'},
    "ARMOR"      => $pc{'armor'.$_.'Armor'},
    "NOTE"       => $pc{'armor'.$_.'Note'},
  });
}
$SHEET->param(Armors => \@armors);

### ヴィークル --------------------------------------------------
my @vehicles;
foreach (1 .. $pc{'vehicleNum'}){
  next if(
    !$pc{'vehicle'.$_.'Name'}  && !$pc{'vehicle'.$_.'Stock'} && !$pc{'vehicle'.$_.'Exp'} &&
    !$pc{'vehicle'.$_.'Skill'} && !$pc{'vehicle'.$_.'Atk'}   && !$pc{'vehicle'.$_.'Initiative'} &&
    !$pc{'vehicle'.$_.'Armor'} && !$pc{'vehicle'.$_.'Dash'}  && !$pc{'vehicle'.$_.'Note'}
  );
  push(@vehicles, {
    "NAME"       => textShrink(12,13,14,15,$pc{'vehicle'.$_.'Name'}),
    "STOCK"      => $pc{'vehicle'.$_.'Stock'},
    "EXP"        => $pc{'vehicle'.$_.'Exp'},
    "TYPE"       => textType($pc{'vehicle'.$_.'Type'}),
    "SKILL"      => textSkill(textShrink(4,5,6,7,$pc{'vehicle'.$_.'Skill'})),
    "INITIATIVE" => $pc{'vehicle'.$_.'Initiative'},
    "ATK"        => $pc{'vehicle'.$_.'Atk'},
    "ARMOR"      => $pc{'vehicle'.$_.'Armor'},
    "DASH"       => $pc{'vehicle'.$_.'Dash'},
    "NOTE"       => $pc{'vehicle'.$_.'Note'},
  });
}
$SHEET->param(Vehicles => \@vehicles);

### アイテム --------------------------------------------------
my @items;
foreach (1 .. $pc{'itemNum'}){
  next if(
    !$pc{'item'.$_.'Name'}  && !$pc{'item'.$_.'Stock'} && !$pc{'item'.$_.'Exp'} &&
    !$pc{'item'.$_.'Skill'} && !$pc{'item'.$_.'Note'}
  );
  push(@items, {
    "NAME"  => textShrink(12,13,14,15,$pc{'item'.$_.'Name'}),
    "STOCK" => $pc{'item'.$_.'Stock'},
    "EXP"   => $pc{'item'.$_.'Exp'},
    "TYPE"  => textShrink(5,6,7,8,$pc{'item'.$_.'Type'}),
    "SKILL" => textSkill(textShrink(4,5,6,7,$pc{'item'.$_.'Skill'})),
    "NOTE"  => $pc{'item'.$_.'Note'},
  });
}
$SHEET->param(Items => \@items);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{'history0Title'} = 'キャラクター作成';
foreach (0 .. $pc{'historyNum'}){
  #next if !$pc{'history'.$_.'Title'};
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ s/[\-\/]//g;
    $pc{'history'.$_.'Date'} = "<a href=\"$set::log_dir$date$room.html\">$pc{'history'.$_.'Date'}<\/a>";
  }
  if ($set::sessionlist && $pc{'history'.$_.'Title'} =~ s/^#([0-9]+)//){
    $pc{'history'.$_.'Title'} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{'history'.$_.'Title'}<\/a>";
  }
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  push(@history, {
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "EXP"    => $pc{'history'.$_.'Exp'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);


### カラーカスタム --------------------------------------------------
$SHEET->param(colorBaseBgS => $pc{colorBaseBgS} * 0.7);
$SHEET->param(colorBaseBgL => 100 - $pc{colorBaseBgS} / 6);
$SHEET->param(colorBaseBgD => 15);


### バックアップ --------------------------------------------------
opendir(my $DIR,"${set::char_dir}${file}/backup");
my @backlist = readdir($DIR);
closedir($DIR);
my @backup;
foreach (reverse sort @backlist) {
  if ($_ =~ s/\.cgi//) {
    my $url = $_;
    $_ =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})$/$1 $2\:$3/;
    push(@backup, {
      "NOW"  => ($url eq param('backup') ? 1 : 0),
      "URL"  => $url,
      "DATE" => $_,
    });
  }
}
$SHEET->param(Backup => \@backup);

### パスワード要求 --------------------------------------------------
$SHEET->param(ReqdPassword => (!$pc{'protect'} || $pc{'protect'} eq 'password' ? 1 : 0) );

### フェロー --------------------------------------------------
$SHEET->param(FellowMode => param('f'));

### タイトル --------------------------------------------------
$SHEET->param(characterNameTitle => tag_delete( name_plain($pc{'characterName'}) ));
$SHEET->param(title => $set::title);

### 種族名 --------------------------------------------------
$pc{'race'} =~ s/［.*］//g;
$SHEET->param("race" => $pc{'race'});

### 画像 --------------------------------------------------
my $imgsrc;
if($pc{'convertSource'} eq 'キャラクターシート倉庫'){
  ($imgsrc = $conv_url) =~ s/edit\.html/image/; 
  require LWP::UserAgent;
  my $code = LWP::UserAgent->new->simple_request(HTTP::Request->new(GET => $imgsrc))->code == 200;
  $SHEET->param("image" => $code);
}
elsif($pc{'convertSource'} eq '別のゆとシートⅡ') {
  $imgsrc = tag_delete $pc{'imageURL'};
}
else {
  $imgsrc = "${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}";
}
$SHEET->param("imageSrc" => $imgsrc);

if($pc{'imageFit'} =~ /^(percent|percentX)$/){
  $SHEET->param("imageFit" => $pc{'imagePercent'}.'%');
}
elsif($pc{'imageFit'} eq 'percentY'){
  $SHEET->param("imageFit" => 'auto '.$pc{'imagePercent'}.'%');
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url()."?=id".$id);
if($pc{'image'}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => "性別:$pc{'gender'}　年齢:$pc{'age'}　ワークス:$pc{'works'}　シンドローム:$pc{'syndrome1'} $pc{'syndrome2'} $pc{'syndrome3'}");

### バージョン等 --------------------------------------------------
$SHEET->param("ver" => $::ver);
$SHEET->param("coreDir" => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;