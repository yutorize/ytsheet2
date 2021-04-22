use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use Encode qw/encode decode/;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-DX ##################################################################################

### タグ変換 --------------------------------------------------
sub tag_unescape {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  #$text =~ s/\{\{([0-9\+\-\*\/\%\(\) ]+?)\}\}/s_eval($1);/eg;
  
  $text =~ s#(―+)#<span class="d-dash">$1</span>#g;
  
  $text =~ s{[©]}{<i class="s-icon copyright">©</i>}gi;
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/\{\{(.+?)\}\}/<span style="color:transparent">$1<\/span>/gi;  # 透明
  $text =~ s/[|｜]([^|｜]+?)《(.+?)》/<span><ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby><\/span>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/&tag_link_url($2,$1)/egi; # リンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/<a href="?id=$2">$1<\/a>/gi; # シート内リンク
  $text =~ s/(?<!href=")(https?:\/\/[^\s\<]+)/<a href="$1" target="_blank">$1<\/a>/gi; # 自動リンク
  
  $text =~ s/\n/<br>/gi;
  
  return $text;
}
sub tag_unescape_ytc {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/$1/gi; # リンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/$1/gi; # シート内リンク
  
  $text =~ s/\n/<br>/gi;
  return $text;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  $pc{'ver'} =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($pc{'ver'} < 1.13002){
    ($pc{'characterName'},$pc{'characterNameRuby'}) = split(':', $pc{'characterName'});
    ($pc{'aka'},$pc{'akaRuby'}) = split(':', $pc{'aka'});
  }
  $pc{'ver'} = $main::ver;
  return %pc;
}

1;