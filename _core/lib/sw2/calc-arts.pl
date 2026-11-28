################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

require $::core_dir.'/lib/sw2/data-arts.pl';

sub dataCalc {
  my %pc = %{$_[0]};
  if($pc{ver}){
    %pc = upgradeArtsData(\%pc);
  }
  my $records = magicRecordList();
  if(my $formError = $records->normalizeForm(\%pc)){ error($formError); }
  my @magicPrefixes = $records->prefixes(\%pc);
  my $magicNum = @magicPrefixes;
  if($pc{category} eq 'magic'){
    $pc{magicNum} = $magicNum;
  }
  elsif($magicNum == 1 && ($pc{magicLastNumber} // 1) == 1){
    # 他のカテゴリでは、既存の魔法一覧がある場合だけその採番を保持する。
    delete @pc{qw/magicNum magicOrder magicLastNumber/};
  }
  delete $pc{magicPageTitle} if $magicNum == 1;
  my %NL;

  if($pc{category} eq 'magic'){
    $NL{name} = $records->sheetName(\%pc);
    $NL{sub} = $pc{magicClass}.'／'.$pc{magicLevel};
    if($pc{magicMinor}){ $NL{sub} .= '／小魔法'; }
    if($pc{magicClass} =~ /^(?:呪印|貴格|城識)$/) { $NL{summary} = substr($pc{magicEffect}, 0, 35).'..'; }
    else { $NL{summary} = $pc{magicSummary}; }
  }
  elsif($pc{category} eq 'god'){
    $NL{name} = ($pc{godAka} ? "“$pc{godAka}”" : "").$pc{godName};
    $NL{sub} = ($pc{godClass}||'―') . '／' . ($pc{godRank}||'―') . '／' . ($pc{godArea}||'―');
    $NL{summary} = $pc{godDeity};
  }
  elsif($pc{category} eq 'school'){
    $NL{name} = $pc{schoolName};
    $NL{sub} = ($pc{schoolArea}||'―');
    $NL{summary} = $pc{schoolNote};
  }
  elsif($pc{category} eq 'skill'){
    $NL{name} = $pc{skillName};
    $NL{summary} = $pc{skillRankB_summary};
  }
  $pc{artsName} = $NL{name};

  #### カテゴリの全角半角変換 --------------------------------------------------
  $pc{category} =~ tr/ａ-ｚＡ-Ｚ/a-zA-Z/;

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/magicDescription
    godSymbol godDeity godNote godQnA
    schoolNote schoolItemNote schoolArtsNote schoolMagicNote schoolQnA
    skillRankB_effect skillRankA_effect skillRankS_effect skillRankSS_effect
    /,
    ( map { "${_}magicEffect"       } @magicPrefixes ),
    ( map { "godMagic${_}Effect"    } 2,4,7,10,13 ),
    ( map { "schoolArts${_}Effect"  } 1..$pc{schoolArtsNum} ),
    ( map { "schoolMagic${_}Effect" } 1..$pc{schoolMagicNum} ),
    ( map { "skillRank${_}_effect"  } qw/B A S SS/ ),
  );

  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine --------------------------------------------------
  $NL{author} = $pc{author};
  foreach (keys %NL){
    $NL{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  my $magicSubcategories;
  if($pc{category} eq 'magic' && $magicNum > 1){
    ($NL{sub}, $magicSubcategories) = magicListSubcategories(\%pc);
  }
  $NL{name}    = substr($NL{name}   , 0, 108).'..' if length($NL{name}   ) > 108;
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{sub}     = substr($NL{sub}    , 0,  40).'..' if !defined($magicSubcategories) && length($NL{sub}) > 40;
  $NL{summary} = substr($NL{summary}, 0,  35).'..' if length($NL{summary}) >  35;
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$NL{author}<>"
    . "$pc{category}<>$NL{sub}<>$NL{summary}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>";
  if(defined $magicSubcategories){
    my @names;
    if($pc{forbidden} eq '' || $pc{forbidden} eq 'battle'){
      @names = map { recordListText($pc{"${_}magicName"}) } @magicPrefixes;
    }
    $::updatedLine .= joinRecordListValues(deduplicate(@names))."<>$magicSubcategories<>";
  }

  return %pc;
}

1;
