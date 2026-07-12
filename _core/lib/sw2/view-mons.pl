################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'SwordWorld2Enemy',
  defaultPieceImage => $::core_dir.'/skin/sw2/img/default_enemy.png',
  unescapeLinesKeys => [qw/skills description/],
  nameKeys => [qw/characterName monsterName/],
  nameSub  => \&setupMonsterName,
);
our %pc = %{ $pcRef };
$SHEET->param(modeZero => $::SW2_0 ? 1 : 0);

sub setupMonsterName {
  my ($pc) = @_;
  $pc->{titleName} = 
    $pc->{characterName} && $pc->{monsterName}
    ? "$pc->{characterName}（$pc->{monsterName}）"
    : $pc->{characterName} || $pc->{monsterName};
  $pc->{encodedNameLetter} = $pc->{titleName}.'【】';
}

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{monsterName} = noiseText(6,14);
    $pc->{tags} = '';
    
    $pc->{description} = '';
    foreach(1..int(rand 3)+1){
      $pc->{description} .= '　'.noiseText(18,40)."<br>";
    }
  }
  
  $pc->{lv}   = noiseText(1);
  $pc->{taxa} = noiseText(2,5);
  $pc->{intellect}   = noiseText(3);
  $pc->{perception}  = noiseText(3);
  $pc->{disposition} = noiseText(3);
  $pc->{sin}         = noiseText(1);
  $pc->{language}    = noiseText(4,18);
  $pc->{habitat}     = noiseText(3,8);
  $pc->{reputation}  = noiseText(2);
  $pc->{'reputation+'} = noiseText(2);
  $pc->{weakness}    = noiseText(6,10);
  $pc->{initiative}  = noiseText(2);
  $pc->{mobility}    = noiseText(2,6);
  $pc->{statusNum} = int(rand 3)+1;
  $pc->{partsNum}  = noiseText(2);
  $pc->{parts}     = noiseText(3,9);
  $pc->{coreParts} = noiseText(2,5);
  
  foreach(1..$pc->{statusNum}){
    $pc->{'status'.$_.'Style'} = noiseText(3,10);
    $pc->{'status'.$_.'Accuracy'}    = noiseText(1,2);
    $pc->{'status'.$_.'AccuracyFix'} = noiseText(2);
    $pc->{'status'.$_.'Damage'}      = noiseText(4);
    $pc->{'status'.$_.'Evasion'}     = noiseText(1,2);
    $pc->{'status'.$_.'EvasionFix'}  = noiseText(2);
    $pc->{'status'.$_.'Defense'}     = noiseText(2);
    $pc->{'status'.$_.'Hp'}          = noiseText(2,3);
    $pc->{'status'.$_.'Mp'}          = noiseText(2,3);
  }
  $pc->{skills} = '';
  foreach(1..int(rand 4)+1){
    $pc->{skills} .= noiseText(6,18)."<br>";
    $pc->{skills} .= '　'.noiseText(18,40)."<br>";
    $pc->{skills} .= '　'.noiseText(18,40)."<br>" if(int rand 2);
    $pc->{skills} .= "<br>";
  }
}

### 価格 --------------------------------------------------
{
  my $price;

  my @prices = (
      ['購入', $pc{price}],
      ['レンタル', $pc{priceRental}],
      ['部位再生', $pc{priceRegenerate}],
  );

  foreach (@prices) {
    (my $term, my $value) = @{$_};
    my $annotation = $value =~ s/([(（].+?[）)])$// ? $1 : '';
    my $unit = $value =~ /\d$/ ? 'G' : '';

    $value = commify($value);
    $unit = "<small>$unit</small>" if $unit ne '';
    $annotation = "<small>$annotation</small>" if $annotation ne '';

    $price .= "<dt>$term</dt><dd>$value$unit$annotation</dd>" if $value;
  }

  if(!$price){ $price = '―' }
  $SHEET->param(price => "<dl class=\"price\">$price</dl>");
}
### 適正レベル --------------------------------------------------
my $appLv = $pc{lvMin}.($pc{lvMax} != $pc{lvMin} ? "～$pc{lvMax}":'');
{
  $SHEET->param(appLv => $appLv);
}
### 穢れ --------------------------------------------------
unless(
  ($pc{taxa} eq 'アンデッド' && ($pc{sin} == 5 || $pc{sin} eq '')) ||
  ($pc{taxa} ne '蛮族'       && ($pc{sin} == 0 || $pc{sin} eq ''))
){
  $SHEET->param(displaySin => 1);
}
### ステータス --------------------------------------------------
if($pc{vitResist} ne ''){ $SHEET->param(vitResist => $pc{vitResist}.(!$pc{statusTextInput}?' ('.$pc{vitResistFix}.')':'')) }
if($pc{mndResist} ne ''){ $SHEET->param(mndResist => $pc{mndResist}.(!$pc{statusTextInput}?' ('.$pc{mndResistFix}.')':'')) }

my @status_tbody;
my @status_row;
foreach (1 .. $pc{statusNum}){
  if ($pc{'status'.$_.'Accuracy'} ne ''){ $pc{'status'.$_.'Accuracy'} = $pc{'status'.$_.'Accuracy'}.(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'AccuracyFix'}.')':'') }
  if ($pc{'status'.$_.'Evasion'}  ne ''){ $pc{'status'.$_.'Evasion'}  = $pc{'status'.$_.'Evasion'} .(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'EvasionFix'}.')' :'') }

  $pc{'status'.$_.'Damage'} = '―' if $pc{'status'.$_.'Damage'} eq '2d+' && ($pc{'status'.$_.'Accuracy'} eq '' || $pc{'status'.$_.'Accuracy'} eq '―');
  
  push(@status_row, {
    LV       => $pc{lvMin},
    STYLE    => ($pc{'status'.$_.'Style'} =~ s#[(（].+[）)]#<span class="part">$&</span>#r),
    ACCURACY => $pc{'status'.$_.'Accuracy'} // '―',
    DAMAGE   => $pc{'status'.$_.'Damage'  } // '―',
    EVASION  => $pc{'status'.$_.'Evasion' } // '―',
    DEFENSE  => $pc{'status'.$_.'Defense' } // '―',
    HP       => $pc{'status'.$_.'Hp'      } // '―',
    MP       => $pc{'status'.$_.'Mp'      } // '―',
    VIT      => $pc{'status'.$_.'Vit'     } // '―',
    MND      => $pc{'status'.$_.'Mnd'     } // '―',
  } );
}
push(@status_tbody, { "ROW" => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $pc{lvMin} == $pc{lv};
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  my @status_row;
  foreach (1 .. $pc{statusNum}){
    my $num = "$_-$lv";

    $pc{'status'.$num.'Damage'} = '―' if $pc{'status'.$num.'Damage'} eq '2d+' && ($pc{'status'.$num.'Accuracy'} eq '' || $pc{'status'.$num.'Accuracy'} eq '―');

    push(@status_row, {
      LV       => $lv+$pc{lvMin}-1,
      STYLE    => ($pc{'status'.$_.'Style'} =~ s#[(（].+[）)]#<span class="part">$&</span>#r),
      ACCURACY => $pc{'status'.$num.'Accuracy'} // '―',
      DAMAGE   => $pc{'status'.$num.'Damage'  } // '―',
      EVASION  => $pc{'status'.$num.'Evasion' } // '―',
      DEFENSE  => $pc{'status'.$num.'Defense' } // '―',
      HP       => $pc{'status'.$num.'Hp'      } // '―',
      MP       => $pc{'status'.$num.'Mp'      } // '―',
      VIT      => $pc{'status'.$num.'Vit'     } // '―',
      MND      => $pc{'status'.$num.'Mnd'     } // '―',
    } );
  }
  push(@status_tbody, { ROW => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $lv+$pc{lvMin}-1 == $pc{lv};
}
$SHEET->param(Status => \@status_tbody);

### 部位 --------------------------------------------------
$SHEET->param(partsOn => 1) if ($pc{partsNum} > 1 || $pc{parts} || $pc{coreParts});
$SHEET->param(parts => $pc{parts} =~ s#([^／]+)#<span>$1</span>#gr);

### 特殊能力 --------------------------------------------------
$pc{skills} =~ s/<br>/\n/gi;
$pc{skills} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{skills} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
$pc{skills} = checkSkillName($pc{skills});
$pc{skills} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
$pc{skills} =~ s/\n+<\/p>/<\/p>/gi;
$pc{skills} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{skills} = "<p>$pc{skills}</p>";
$pc{skills} =~ s#(</p>|</details>)\n#$1#gi;
$pc{skills} =~ s/<p><\/p>//gi;
$pc{skills} =~ s/\n/<br>/gi;
$SHEET->param(skills => $pc{skills});

#if($pc{description} =~ s/#login-only//i){
#  $pc{description} .= '<span class="login-only">［ログイン限定公開］</span>';
#  $pc{forbidden} = 'all' if !$::LOGIN_ID;
#}

### 戦利品 --------------------------------------------------
my @loots;
foreach (1 .. $pc{lootsNum}){
  next if !$pc{'loots'.$_.'Num'} && !$pc{'loots'.$_.'Item'};
  push(@loots, {
    NUM  => $pc{'loots'.$_.'Num'},
    ITEM => $pc{'loots'.$_.'Item'},
  } );
}
$SHEET->param(Loots => \@loots);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags(
  ($pc{mount} && $pc{lv} eq '' ? "適正レベル:$appLv" : "レベル:$pc{lv}").
  "　分類:$pc{taxa}".
  ($pc{partsNum} > 1 ? "　部位数:$pc{partsNum}" : '').
  (!$pc{mount} ? "　知名度:$pc{reputation}／$pc{'reputation+'}" : '')
));

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
