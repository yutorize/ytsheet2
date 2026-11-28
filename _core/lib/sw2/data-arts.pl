use strict;
use utf8;

package data::arts;

# 編集・移行・表示で共有する、項目名とレイアウトの対応。
my %fields = (
  Magisphere     => { label => 'マギスフィア', class => 'sphere', list => 'list-sphere' },
  Type           => { label => '対応', class => 'type', list => 'list-type' },
  Premise        => { label => '前提', class => 'premise', list => 'list-premise' },
  Cost           => { label => '消費', class => 'cost', list => 'list-cost' },
  Target         => { label => '対象', class => 'target', list => 'list-target' },
  Range          => { label => '射程／形状', class => 'range', list => 'list-magic-range-form' },
  Duration       => { label => '時間', class => 'duration', list => 'list-duration' },
  SongSing       => { label => '歌唱', class => 'sing', list => 'list-song-sing' },
  SongPet        => { label => 'ペット', class => 'pet', list => 'list-song-pet' },
  Condition      => { label => '条件', class => 'condition', list => 'list-song-condition' },
  SongBasePoint  => { label => '基礎楽素', class => 'basepoint', list => 'list-songpoint' },
  SongSetPoint   => { label => '巧奏値', class => 'setpoint', list => 'list-song-set-point' },
  SongAddPoint   => { label => '追加楽素', class => 'addpoint', list => 'list-songpoint' },
  ApplyPart      => { label => '適用部位', class => 'part', list => 'list-part' },
  ApplyHumanForm => { label => '人間形態時', class => 'human-form', list => 'list-human-form' },
  Rank           => { label => 'ランク', class => 'rank' },
  CommandCost    => { label => '陣気コスト', class => 'ccost' },
  CommandCharge  => { label => '陣気蓄積', class => 'ccharge' },
  Resist         => { label => '抵抗', class => 'resist', list => 'list-resist' },
  Element        => { label => '属性', class => 'element', list => 'list-element' },
);
my @default = qw/Cost Target Range Duration Resist Element/;
my %presets = (
  '練技' => [qw/Duration/],
  '呪歌' => [qw/SongSing SongPet Condition SongBasePoint SongSetPoint SongAddPoint Resist Element/],
  '終律' => [qw/Cost Resist Element/],
  '騎芸' => [qw/Premise Type ApplyPart/],
  '賦術' => [qw/Cost Target Range Duration Resist/],
  '相域' => [qw/Cost Duration Element/],
  '鼓咆' => [qw/Type Rank CommandCost CommandCharge/],
  '陣率' => [qw/Premise Condition CommandCost/],
  '魔装' => [qw/Premise ApplyPart ApplyHumanForm/],
  '操気' => [qw/Cost Premise Target Range Duration Resist/],
  '城識' => [],
  '占瞳' => [qw/Type Target Range Duration/],
  '呪印' => [qw/Type Premise/],
  '貴格' => [qw/Type Target Premise/],
  '魔動機術' => [qw/Magisphere Cost Target Range Duration Resist Element/],
);
my %labels = (
  '呪歌' => { Condition => '効果発生条件' },
  '相域' => { Duration => '効果の時間' },
  '鼓咆' => { Type => '鼓咆の系統' },
  '陣率' => { Condition => '使用条件' },
  '占瞳' => { Type => 'タイプなど' },
  '呪印' => { Premise => '前提ＡＣ' },
  '貴格' => { Type => '形態' },
);
my %layouts = (
  '練技' => 'enhance', '呪歌' => 'song', '終律' => 'finale', '騎芸' => 'riding',
  '相域' => 'geomancy', '鼓咆' => 'command', '陣率' => 'lead', '占瞳' => 'divination',
  '魔装' => 'potential', '操気' => 'psychokinesis', '呪印' => 'seal', '貴格' => 'dignity',
  '城識' => 'palacesense',
);
my %aliases = map { $fields{$_}{label} => $_ } keys %fields;
foreach my $overrides (values %labels){ $aliases{$overrides->{$_}} = $_ foreach keys %$overrides; }
$aliases{'系統'} = 'Type';
$aliases{'射程/形状'} = 'Range';
$aliases{'前提AC'} = 'Premise';

sub schema { return { fields => \%fields, presets => \%presets, labels => \%labels, aliases => \%aliases, default => \@default }; }
sub baseClass { return ($_[0] // '') =~ s/ \(小魔法\)$//r; }
sub label {
  my ($id,$class) = @_;
  my $overrides = $labels{baseClass($class)} // {};
  return $overrides->{$id} // $fields{$id}{label};
}
sub layout { return $layouts{baseClass($_[0])} // ''; }
sub fieldId { return $aliases{$_[0] // ''}; }
sub fieldDefinition { return $fields{$_[0]}; }
sub preset {
  my ($class,$passive) = @_;
  $class = baseClass($class);
  return [qw/Cost Premise/] if $class eq '操気' && $passive;
  return $presets{$class} // \@default;
}

sub classOptions {
  require $set::data_class;
  my (@magic,@craft);
  foreach (@data::class_names){
    if($_ eq 'フェアリーテイマー'){
      push @magic, 'LABEL=妖精魔法', '基本妖精魔法',
        '属性妖精魔法(土)', '属性妖精魔法(水・氷)', '属性妖精魔法(炎)', '属性妖精魔法(風)',
        '属性妖精魔法(光)', '属性妖精魔法(闇)', '特殊妖精魔法', 'GROUPCLOSE';
    }
    elsif($_ eq 'コンジャラー'){ push @magic, $data::class{$_}{magic}{jName}, '深智魔法'; }
    elsif($_ eq 'バード'){ push @craft, $data::class{$_}{craft}{jName}, '終律'; }
    elsif($_ eq 'ウォーリーダー'){ push @craft, '鼓咆','陣率'; }
    elsif($data::class{$_}{magic}){ push @magic, $data::class{$_}{magic}{jName}; }
    elsif($data::class{$_}{craft}){ push @craft, $data::class{$_}{craft}{jName}; }
  }
  my %seen;
  return grep { !$seen{$_}++ } (@magic,@craft);
}

sub legacyValue {
  my ($pc,$prefix,$id,$class) = @_;
  my $value = $pc->{"$prefix$id"} // '';
  if($id eq 'Range'){
    my $form = $pc->{"${prefix}Form"} // '';
    return ($value ne '' || $form ne '') ? "$value／$form" : '';
  }
  if($id eq 'SongSing'){ return $value ? '必要' : 'なし'; }
  if($id eq 'SongPet'){
    return $value || join('、', map { $_->[1] } grep { $pc->{"${prefix}SongPet".$_->[0]} }
      ['Bird','小鳥'], ['Frog','蛙'], ['Bug','虫']);
  }
  if($id eq 'Type' && baseClass($class) eq '騎芸'){
    return $value || join('、', map { $_->[1] } grep { $pc->{"${prefix}MountType".$_->[0]} }
      ['Animal','動物'], ['Cryptid','幻獣'], ['Machine','魔動機']);
  }
  if($id eq 'ApplyHumanForm'){ return $value eq 'available' ? '有効' : $value eq 'unavailable' ? '無効' : '―'; }
  return $value;
}

sub upgradePrefix {
  my ($pc,$prefix,$classPrefix) = @_;
  $classPrefix //= $prefix;
  my $class = $pc->{"${classPrefix}Class"} // '';
  my $customKey = "${classPrefix}DataCustom";
  if(!exists $pc->{$customKey}){
    my %known = map { $_ => 1 } classOptions();
    $pc->{$customKey} = ($class ne '' && !$known{baseClass($class)}) ? 1 : 0;
  }
  # 0行の自由記入データも、移行済みとして扱う。
  return if exists $pc->{"${prefix}DataNum"};
  my $ids = preset($class,$pc->{"${prefix}ActionTypePassive"});
  my $num = 0;
  foreach my $id (@$ids){
    my $value = legacyValue($pc,$prefix,$id,$class);
    # 旧画面で非表示だった空の属性は、自由記入の項目として新設しない。
    next if $id eq 'Element' && $pc->{$customKey} && $value eq ''
      && baseClass($class) !~ /^(?:呪歌|終律|相域)$/;
    $num++;
    $pc->{"${prefix}Data${num}Label"} = label($id,$class);
    $pc->{"${prefix}Data${num}Value"} = $value;
  }
  $pc->{"${prefix}DataNum"} = $num;
}
sub rows {
  my ($pc,$prefix,$classPrefix) = @_;
  upgradePrefix($pc,$prefix,$classPrefix);
  return [map { +{ Label => $pc->{"${prefix}Data${_}Label"} // '', Value => $pc->{"${prefix}Data${_}Value"} // '' } }
    1..($pc->{"${prefix}DataNum"} || 0)];
}
sub upgrade {
  my ($pc) = @_;
  upgradePrefix($pc,'magic');
  upgradePrefix($pc,"schoolMagic$_") foreach 1..($pc->{schoolMagicNum} || 0);
  return $pc;
}
sub clearLegacy {
  my ($pc) = @_;
  my @suffixes = (keys %fields, qw/Form SongPetBird SongPetFrog SongPetBug MountTypeAnimal MountTypeCryptid MountTypeMachine/);
  foreach my $prefix ('magic',map { "schoolMagic$_" } 1..($pc->{schoolMagicNum} || 0)){
    delete $pc->{"$prefix$_"} foreach @suffixes;
  }
}

1;
