use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
no warnings 'once';
binmode Test::More->builder->output, ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';
binmode Test::More->builder->todo_output, ':encoding(UTF-8)';

our $core_dir = "$FindBin::Bin/../_core";
require "$core_dir/lib/sw2/data-arts.pl";

for my $system ('sw2','sw2.0'){
  local $set::data_class = "$core_dir/lib/$system/data-class.pl";
  subtest $system => sub {
    my $pc = {
      magicClass => '呪歌', magicSongSing => 1,
      magicSongPetBird => 1, magicSongPetBug => 1,
      magicCondition => '⤴♡', magicSongBasePoint => '⤵', magicSongSetPoint => 13,
      magicSongAddPoint => '♡', magicResist => '消滅', magicElement => '精神効果',
      schoolMagicNum => 2,
      schoolMagic1Class => '騎芸', schoolMagic1MountTypeAnimal => 1, schoolMagic1MountTypeMachine => 1,
      schoolMagic1Premise => '前提', schoolMagic1ApplyPart => 'すべて',
      schoolMagic2Class => '魔動機術', schoolMagic2Magisphere => '小', schoolMagic2Cost => 'MP5',
      schoolMagic2Range => '2(30m)', schoolMagic2Form => '射撃',
    };
    data::arts::upgrade($pc);
    is($pc->{magicDataNum},8,'呪歌の8項目を移行');
    is($pc->{magicDataCustom},0,'既定系統のラベルは固定');
    my %song = map { $_->{Label} => $_->{Value} } @{ data::arts::rows($pc,'magic') };
    is($song{歌唱},'必要','歌唱チェックを移行');
    is($song{ペット},'小鳥、虫','複数のペットを保持');
    is($song{効果発生条件},'⤴♡','条件のラベルと値を保持');
    is($song{基礎楽素},'⤵','基礎楽素を移行');
    is($song{巧奏値},13,'巧奏値を移行');
    is($song{追加楽素},'♡','追加楽素を移行');
    my %mount = map { $_->{Label} => $_->{Value} } @{ data::arts::rows($pc,'schoolMagic1') };
    is($mount{対応},'動物、魔動機','騎芸の対応を移行');
    my %spell = map { $_->{Label} => $_->{Value} } @{ data::arts::rows($pc,'schoolMagic2') };
    is($spell{マギスフィア},'小','マギスフィアを移行');
    is($spell{'射程／形状'},'2(30m)／射撃','射程と形状を一つの値に移行');
    data::arts::clearLegacy($pc);
    ok(!exists $pc->{magicSongPetBird} && !exists $pc->{schoolMagic2Range},'新形式の保存で個別項目を残さない');
    is($pc->{schoolMagic2Data2Value},'MP5','個別項目を除去しても新形式の値は保持');

    my $zero = { magicClass => '呪歌', magicDataCustom => 1, magicDataNum => 0 };
    data::arts::upgrade($zero);
    is_deeply(data::arts::rows($zero,'magic'),[],'自由記入の0行を維持');
    is($zero->{magicDataCustom},1,'既定名を自由記入しても自由記入モードを維持');
    my @labels_before = sort keys %{ data::arts::schema()->{labels} };
    my $custom = { magicClass => '独自系統', magicCost => 'HP3' };
    data::arts::upgrade($custom);
    is($custom->{magicDataCustom},1,'未知の系統を自由記入に移行');
    is($custom->{magicData1Value},'HP3','自由記入の既存値も保持');
    is_deeply([sort keys %{ data::arts::schema()->{labels} }],\@labels_before,'自由記入の系統名で共有の定義を変更しない');
    for my $prefix ('magic','schoolMagic1'){
      for my $element (undef,'','炎','0'){
        my $legacy = { "${prefix}Class" => '独自系統' };
        $legacy->{"${prefix}Element"} = $element if defined $element;
        data::arts::upgradePrefix($legacy,$prefix);
        my @elements = grep { $_->{Label} eq '属性' } @{ data::arts::rows($legacy,$prefix) };
        my $has_element = defined($element) && $element ne '';
        is(scalar @elements,$has_element ? 1 : 0,"$prefix: 旧形式の未指定・空欄の属性を新設しない");
        is($legacy->{"${prefix}DataNum"},$has_element ? 6 : 5,"$prefix: 移行後の行数が一致");
        is($elements[0]{Value},$element,"$prefix: 指定済みの属性を保持") if $has_element;
      }
      my $explicit = { "${prefix}Class" => '独自系統', "${prefix}DataCustom" => 1,
        "${prefix}DataNum" => 1, "${prefix}Data1Label" => '属性', "${prefix}Data1Value" => '' };
      data::arts::upgradePrefix($explicit,$prefix);
      is_deeply(data::arts::rows($explicit,$prefix),[{ Label => '属性', Value => '' }],"$prefix: 新形式で明示した空の属性は保持");
      for my $class ('呪歌','終律','相域'){
        my $legacy = { "${prefix}Class" => $class, "${prefix}DataCustom" => 1 };
        data::arts::upgradePrefix($legacy,$prefix);
        my @elements = grep { $_->{Label} eq '属性' } @{ data::arts::rows($legacy,$prefix) };
        is(scalar @elements,1,"$prefix: $class の既存の空属性表示を維持");
      }
    }

    my $existing = { magicClass => '真語魔法', magicDataNum => 2,
      magicData1Label => '独自項目', magicData1Value => '独自値',
      magicData2Label => '消費', magicData2Value => 'HP2' };
    data::arts::upgrade($existing);
    is($existing->{magicData1Label},'独自項目','移行済みのラベルを上書きしない');
    is($existing->{magicData2Value},'HP2','移行済みの値を上書きしない');
    is(data::arts::fieldDefinition(data::arts::fieldId('鼓咆の系統'))->{class},'type','項目名から既存CSSクラスを取得');
    is(data::arts::fieldId('前提AC'),'Premise','項目名の別表記に対応');
    is(data::arts::fieldId('独自項目'),undef,'独自名をCSSクラスとして使用しない');
    is_deeply(data::arts::preset('操気',1),['Cost','Premise'],'常時操気の項目を限定');
    is(data::arts::layout('呪歌'),'song','呪歌の既存レイアウトを使用');
    is(data::arts::layout('神聖魔法 (小魔法)'),'', '小魔法表記を系統名から除去');
  };
}
done_testing;
