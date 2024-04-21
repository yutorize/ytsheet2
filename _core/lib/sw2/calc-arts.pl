################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

#require $set::data_item;

sub data_calc {
  my %pc = %{$_[0]};
  
  my $name;
  my $sub;
  my $summary;
  if($pc{category} eq 'magic'){
    $name = $pc{magicName};
    $sub = $pc{magicClass}.'／'.$pc{magicLevel};
    if($pc{magicMinor}){ $sub .= '／小魔法'; }
    if($pc{magicClass} =~ /呪印|貴格/) { $summary = substr($pc{magicEffect}, 0, 35).'..'; }
    else { $summary = $pc{magicSummary}; }
  }
  elsif($pc{category} eq 'god'){
    $name = ($pc{godAka} ? "“$pc{godAka}”" : "").$pc{godName};
    $sub = ($pc{godClass}||'―') . '／' . ($pc{godRank}||'―') . '／' . ($pc{godArea}||'―');
    $summary = substr($pc{godDeity}, 0, 35).'..';
  }
  elsif($pc{category} eq 'school'){
    $name = $pc{schoolName};
    $sub = ($pc{schoolArea}||'―');
    $summary = substr($pc{schoolNote}, 0, 35).'..';
  }
  $summary =~ s/\r|\n/ /g;
  $pc{artsName} = $name;

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
  foreach (
    'magicEffect',
    'magicDescription',
    'godSymbol',
    'godDeity',
    'godNote',
    'godMagic2Effect',
    'godMagic4Effect',
    'godMagic7Effect',
    'godMagic10Effect',
    'godMagic13Effect',
    'schoolNote',
    'schoolItemNote',
    'schoolArtsNote',
    'schoolMagicNote',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  foreach my $num (1..$pc{schoolArtsNum}){
    $pc{"schoolArts${num}Effect"} =~ s/\r\n?|\n/<br>/g;
  }
  foreach my $num (1..$pc{schoolMagicNum}){
    $pc{"schoolMagic${num}Effect"} =~ s/\r\n?|\n/<br>/g;
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### newline --------------------------------------------------
  $name =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{id}<>$::file<>".
                "$pc{birthTime}<>$::now<>$name<>$pc{author}<>".
                "$pc{category}<>$sub<>$summary<>".
                "$pc{image}<> $pc{tags} <>$pc{hide}<>";
  
  return %pc;
}

1;