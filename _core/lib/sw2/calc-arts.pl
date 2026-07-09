################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

#require $set::data_item;

sub dataCalc {
  my %pc = %{$_[0]};
  my %NL;

  if($pc{category} eq 'magic'){
    $NL{name} = $pc{magicName};
    $NL{sub} = $pc{magicClass}.'／'.$pc{magicLevel};
    if($pc{magicMinor}){ $NL{sub} .= '／小魔法'; }
    if($pc{magicClass} =~ /呪印|貴格/) { $NL{summary} = substr($pc{magicEffect}, 0, 35).'..'; }
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

  $pc{magicSongPet} = join('、',
      grep $_, ($pc{magicSongPetBird}?'小鳥':undef) ,($pc{magicSongPetFrog}?'蛙':undef),($pc{magicSongPetBug}?'虫':undef)
    );
  if($pc{magicClass} eq '騎芸'){
    $pc{magicType} = join('、',
        grep $_, ($pc{magicMountTypeAnimal}?'動物':undef) ,($pc{magicMountTypeCryptid}?'幻獣':undef),($pc{magicMountTypeMachine}?'魔動機':undef)
      );
  }
  #### カテゴリの全角半角変換 --------------------------------------------------
  $pc{category} =~ tr/ａ-ｚＡ-Ｚ/a-zA-Z/;

  #### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/magicEffect magicDescription
    godSymbol godDeity godNote godQnA
    schoolNote schoolItemNote schoolArtsNote schoolMagicNote schoolQnA
    skillRankB_effect skillRankA_effect skillRankS_effect skillRankSS_effect
    /,
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
  $NL{name}    = substr($NL{name}   , 0, 108).'..' if length($NL{name}   ) > 108;
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{sub}     = substr($NL{sub}    , 0,  40).'..' if length($NL{sub}    ) >  40;
  $NL{summary} = substr($NL{summary}, 0,  35).'..' if length($NL{summary}) >  35;
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$NL{author}<>"
    . "$pc{category}<>$NL{sub}<>$NL{summary}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>";

  return %pc;
}

1;
