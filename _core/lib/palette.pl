################## チャットパレット ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

require $set::lib_palette_sub;

### バックアップ情報読み込み #########################################################################
my $backup = param('backup');

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my $tool = param('tool');
my ($file, $type) = getfile_open($id);

my $data_dir;
   if($type eq 'm'){ $data_dir = $set::mons_dir; }
elsif($type eq 'i'){ $data_dir = $set::item_dir; }
else               { $data_dir = $set::char_dir; }

our %pc = ();

my $IN;
if($backup eq "") {
  open $IN, '<', "${data_dir}${file}/data.cgi" or "";
} else {
  open $IN, '<', "${data_dir}${file}/backup/${backup}.cgi" or "";
}

$_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = tag_unescape($2);/egi while <$IN>;
$pc{'chatPalette'} =~ s/<br>/\n/g;
$pc{'skills'} =~ s/<br>/\n/gi;
$pc{$_} = tag_delete($pc{$_}) foreach keys %pc;
close($IN);

my $preset = $pc{'paletteUseVar'} ? palettePreset($type,$tool) : palettePresetRaw($type,$tool);
if ($pc{'paletteInsertType'} eq 'begin'){ $pc{'chatPalette'} = $pc{'chatPalette'}."\n".$preset; }
elsif($pc{'paletteInsertType'} eq 'end'){ $pc{'chatPalette'} = $preset."\n".$pc{'chatPalette'}; }
else {
  $pc{'chatPalette'} = $preset if !$pc{'chatPalette'};
}


### 出力 #############################################################################################
print "Content-type: text/plain; charset=UTF-8\n\n";
say $pc{'chatPalette'},"\n";
say $_ foreach( $pc{'chatPalettePropertiesAll'} ? paletteProperties($type) : palettePropertiesUsedOnly($type,$pc{'chatPalette'}) );

1;
