################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

our $LOGIN_ID = check;

our $file;
my $type;
my $author;
our %conv_data = ();

$::in{log} ||= $::in{backup};

if($::in{id}){
  ($file, $type, $author) = findSheet($::in{id});
}
elsif($::in{url}){
  eval { require $set::lib_convert; };
  %conv_data = importSheetData($::in{url});
  $type = $conv_data{type};
}

changeFileByType($type);


### 各システム別処理 --------------------------------------------------
require $set::lib_view_char;

### ベース処理 --------------------------------------------------
our $selectedLogName;
sub setupViewBase {
  my (%ARGS) = @_;

  my %pc = loadSheetData();
  my $SHEET = setupViewTemplate(
    generateType      => $ARGS{generateType},
    defaultPieceImage => $ARGS{defaultPieceImage},
  );
  ## データアップデート
  if($pc{ver} && $ARGS{updateSub} && ref $ARGS{updateSub} eq 'CODE'){
    %pc = $ARGS{updateSub}->(\%pc);
  }
  ## データマスク
  if($pc{forbidden} && !$pc{yourAuthor}){
    my @keepKeys = ('playerName','author','protect','forbidden','convertSource');
    push(@keepKeys, @{ $ARGS{maskSkipKeys} }) if $ARGS{maskSkipKeys};
    my %keep;
    $keep{$_} = $pc{$_} foreach(@keepKeys);
    if($keep{forbidden} eq 'all'){ %pc = (); }
    maskPcData(\%pc, $keep{forbidden});
    $pc{$_} = $keep{$_} foreach(@keepKeys);
    $pc{forbiddenMode} = 1;
  }
  ## 名前処理
  if(my $callback = $ARGS{nameSub}){
    $callback->(\%pc);
  }
  elsif($ARGS{nameKeys}){
    foreach my $key (@{ $ARGS{nameKeys} }){
      if(defined $pc{$key} && $pc{$key} ne ''){
        $pc{encodedNameLetter} .= $pc{$key}.$pc{"${key}Ruby"};
        $pc{titleName} = $pc{$key} if !$pc{titleName};
      }
    }
  }
  else {
    $pc{titleName} = $pc{characterName} || ($pc{aka} ? qq|“$pc{aka}”| : '');
    $pc{encodedNameLetter} = "$pc{characterName}$pc{characterNameRuby}";
    $pc{encodedNameLetter} .= qq|“$pc{aka}$pc{akaRuby}”| if $pc{aka};
  }
  # ゆとシ内リンクタグ用
  $SHEET->param(rawName => $pc{titleName});
  # タイトルバー
  if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
    $SHEET->param(titleName => '非公開データ');
  }
  else {
    $SHEET->param(titleName =>
      (removeTags removeRuby unescapeTags $pc{titleName})
      . ($::in{log} ? " 【". ($selectedLogName || $pc{updateTime}) ."】" : '')
    );
  }
  delete $pc{titleName};
  # フォント変更対象文字列
  {
    my $letters = removeTags unescapeTags $pc{encodedNameLetter};
    my %seen;
    $letters =~ s/(.)/$seen{$1}++ ? '' : $1/ge; #重複文字削除
    $SHEET->param(encodedNameLetter => uri_escape_utf8 $letters);
  }
  delete $pc{encodedNameLetter};

  ## タグ置換前にやっておきたいその他の処理
  if(my $callback = $ARGS{beforeUnescape}){
    $callback->(\%pc, $SHEET, \%ARGS);
  }
  ## タグ置換
  if($pc{ver}){
    normalizeViewTags(\%pc,
      skipKeys      => $ARGS{unescapeSkipKeys},
      skipRe        => $ARGS{unescapeSkipRe},
      multilineKeys => $ARGS{unescapeLinesKeys},
      multilineRe   => $ARGS{unescapeLinesRe},
      forbiddenMode => $ARGS{forbiddenNoise},
    );
  }
  elsif(my $conv = $ARGS{convertViewMap}){ #ゆとシ以外からのコンバート
    foreach my $key (@{$conv}){
      my $in = $key.'View';
      $pc{$key} = $pc{$in} if defined $pc{$in} && $pc{$in} ne '';
    }
  }

  ## シートカラー
  setColors(\%pc, '');
  ## フォント
  setFont(\%pc, '');

  ## %pc => $SHEET
  while (my ($key, $value) = each(%pc)){
    $SHEET->param($key => $value);
  }

  ## ID / URL
  $SHEET->param(id => $::in{id});
  if($::in{url}){
    $SHEET->param(convertMode => 1);
    $SHEET->param(convertUrl => $::in{url});
  }
  $SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
  ## タグ
  {
    my @tags;
    push(@tags, { URL => uri_escape_utf8($_), TEXT => $_ }) foreach(split(/ /, $pc{tags}));
    $SHEET->param(Tags => \@tags);
  }
  ## 名前出力
  unless($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
    foreach my $key (@{ $ARGS{nameKeys} || [qw/characterName aka/] }){
      $SHEET->param($key => renderCharacterName( $pc{$key},$pc{"${key}Ruby"} ));
    }
  }
  ## プレイヤー名 
  if($set::playerlist && $set::id_type){
    my $plId = (split(/-/, $::in{id}))[0];
    $SHEET->param(playerName => qq|<a href="$set::playerlist?id=$plId">$pc{playerName}</a>|);
  }
  ## グループ
  if($::in{url}){
    $SHEET->param(group => '');
  }
  else {
    if(!$pc{group}) {
      $pc{group} = $set::group_default;
      $SHEET->param(group => $set::group_default);
    }
    foreach (@set::groups){
      if($pc{group} eq @$_[0]){
        $SHEET->param(groupName => @$_[2]);
        last;
      }
    }
  }
  ## セリフ
  if($pc{words}){
    my ($words, $x, $y) = renderWords($pc{words},$pc{wordsX},$pc{wordsY});
    $SHEET->param(words => $words);
    $SHEET->param(wordsX => $x);
    $SHEET->param(wordsY => $y);
  }

  ## バックアップ
  if($::in{id}){
    ($selectedLogName, my $list) = getLogList($set::char_dir, $main::file);
    $SHEET->param(LogList => $list);
    $SHEET->param(selectedLogName => $selectedLogName);
    if($pc{yourAuthor} || $pc{protect} eq 'password'){
      $SHEET->param(viewLogNaming => 1);
    }
  }
  ## robots
  if($pc{hide} || $main::login_error || ($::in{log} && !$selectedLogName)){
    $SHEET->param(noindex => 1);
  }
  
  ## パートナーの名前
  foreach my $num (1 .. $ARGS{partnerMax}){
    next unless $pc{"partner${num}Name"};
    $SHEET->param("partner${num}Name" => renderCharacterName( $pc{"partner${num}Name"},$pc{"partner${num}NameRuby"} ));
    $SHEET->param("p${num}_encodedNameLetter" => uri_escape_utf8 removeTags $pc{"partner${num}Name"}.$pc{"partner${num}NameRuby"});
  }

  return \%pc, $SHEET;
}
sub normalizeViewTags {
  my ($pc, %OPT) = @_;
  my %skip      = map { $_ => 1 } @{ $OPT{skipKeys}      // [] };
  my %multiline = map { $_ => 1 } @{ $OPT{multilineKeys} // [] };
  $skip{tags} = 1; # タグは置換しない

  foreach my $key (keys %{$pc}) {
    next if $skip{$key};
    next if ($OPT{skipRe} && $key =~ $OPT{skipRe});
    next if $key =~ /URL$/i; # URLは置換しない
    next if $key =~ /^image/; # 画像関連は置換しない

    if($multiline{$key} || ($OPT{multilineRe} && $key =~ $OPT{multilineRe})){
      $pc->{$key} = unescapeTagsLines($pc->{$key});
      $pc->{$key} =~ s{^(?:</p>)?<h2>(.*?)</h2>}{$pc->{"head_$key"} = $1; ''}e;
    }
    $pc->{$key} = unescapeTags($pc->{$key});

    if($OPT{forbiddenMode} && $pc->{forbiddenMode}){
      $pc->{$key} = noiseTextTag $pc->{$key};
    }
  }
}
### パートナーデータ共通処理 --------------------------------------------
sub setupPartnerDataCommon {
  my ($pc, %OPT) = @_;
  require $set::lib_convert if !$::in{url};
  return if $::in{log};

  foreach my $num (1 .. $OPT{max}){
    my $urlKey  = "partner${num}Url";
    my $autoKey = "partner${num}Auto";
    next if !$pc->{$urlKey} || !$pc->{$autoKey};
    my %pr = loadPartnerData($pc->{$urlKey});
    next if !$pr{convertSource};

    if($pr{ver} && $OPT{updateSub} && ref $OPT{updateSub} eq 'CODE'){
      %pr = $OPT{updateSub}->(\%pr);
    }
    $pc->{"p${num}_".$_} = $pr{$_} foreach keys %pr;

    if($OPT{onPartner} && ref $OPT{onPartner} eq 'CODE'){
      $OPT{onPartner}->($pc, \%pr, $num);
    }
    if($pr{forbidden} && $OPT{onForbidden} && ref $OPT{onForbidden} eq 'CODE'){
      $OPT{onForbidden}->($pc, \%pr, $num);
    }
  }
  foreach my $num (1 .. $OPT{max}){
    next if !$pc->{"p${num}_imageURL"};
    $pc->{"p${num}_imageSrc"} = $pc->{"p${num}_imageURL"};
    $pc->{images} .= "'p${num}': \"".($pc->{modeDownload} ? urlToBase64($pc->{"p${num}_imagePath"}) : $pc->{"p${num}_imageURL"})."\", ";
    if($pc->{"p${num}_imageFit"} eq 'percentY'){
      $pc->{"p${num}_imageFit"} = 'auto '.$pc->{"p${num}_imagePercent"}.'%';
    }
    elsif($pc->{"p${num}_imageFit"} =~ /^percentX?$/){
      $pc->{"p${num}_imageFit"} = $pc->{"p${num}_imagePercent"}.'%';
    }
    if($pc->{"p${num}_imageCopyrightURL"}){
      $pc->{"p${num}_imageCopyright"} = "<a href=\"$pc->{\"p${num}_imageCopyrightURL\"}\" target=\"_blank\">".($pc->{"p${num}_imageCopyright"}||$pc->{"p${num}_imageCopyrightURL"})."</a>";
    }
  }
  foreach my $num (1 .. $OPT{max}){
    setColors($pc, "p${num}_");
    setFont($pc, "p${num}_");
  }
}

### データ取得 --------------------------------------------------
sub loadSheetData {
  my %pc;
  my $datadir = $set::char_dir;
  ## データ読み込み
  if($::in{id}){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or viewNotFound($datadir);
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=") == 0){
          if (index($_, "=$::in{log}=") == 0){ $hit = 1; next; }
          if ($hit){ last; }
        }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value if $value ne '';
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("404:過去ログ（$::in{log}）が見つかりません。"); }

    if($::in{log}){
      # 閲覧制限は最新のものを適用
      ($pc{protect}, $pc{forbidden},$pc{hide}) = getProtectType("${datadir}${file}/data.cgi");
    }
  }
  ## データ読み込み：コンバート
  elsif($::in{url}){
    %pc = %conv_data;
    $pc{hide} = 1;
    if(!$conv_data{ver}){
      require $set::lib_calc_char;
      %pc = data_calc(\%pc);
    }
  }

  ##
  if(!$::in{checkView} && (
    ($pc{protect} eq 'none') || 
    ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
  )){
    $pc{yourAuthor} = 1;
  }
  if(!$pc{protect} || $pc{protect} eq 'password'){
    $pc{reqdPassword} = 1;
  }

  if($::in{mode} eq 'download'){
    $pc{modeDownload} = 1;
  }
  
  ## キャラクター画像
  if($pc{image}){
    if($pc{convertSource}) {
      $pc{imageSrc} = $pc{imageURL};
    }
    else {
      $pc{imageSrc}    =     "./?id=$::in{id}&mode=image&cache=$pc{imageUpdate}";
      $pc{imageURL}    = url()."?id=$::in{id}&mode=image&cache=$pc{imageUpdate}";
      $pc{imageOgpURL} = url()."?id=$::in{id}&mode=ogp-image&cache=$pc{imageUpdate}";
    }
    $pc{images} = "'1': \"".($pc{modeDownload} ? urlToBase64("${datadir}${file}/image.$pc{image}") : $pc{imageSrc})."\", ";
    
    if($pc{imageFit} eq 'percentY'){
      $pc{imageFit} = 'auto '.$pc{imagePercent}.'%';
    }
    elsif($pc{imageFit} =~ /^percentX?$/){
      $pc{imageFit} = $pc{imagePercent}.'%';
    }
    
    ## 権利表記
    if($pc{imageCopyrightURL}){
      $pc{imageCopyright} = "<a href=\"$pc{imageCopyrightURL}\" target=\"_blank\">".(unescapeTags($pc{imageCopyright})||$pc{imageCopyrightURL})."</a>";
    }
    else { $pc{imageCopyright} = unescapeTags($pc{imageCopyright}) }
  }

  ## 

  return %pc;
}

sub viewNotFound { #v1.14/v1.20のコンバート処理
  my $dir = shift;
  if(!$::in{log} && $file =~ /^(.+)\/(.+?)$/){
    my $user = $1;
    my $file = $2;
    if(-d "${dir}${file}"){
      if(!-d "${dir}${user}"){ mkdir "${dir}${user}" or error("500:データディレクトリの作成に失敗しました。"); }
      rename("${dir}${file}", "${dir}${user}/${file}");
      print "Location:./?id=$::in{id}\n\n";
      exit;
    }
  }
  # 削除済みシートの確認
  if(open (my $LIST, '<', $set::data_dir.'/deleted.cgi')){
    while(my $line = <$LIST>){
      if(index($line, "$::in{id}<") == 0){ error('410:削除されたシートです。'); }
    }
    close($LIST);
  }

  error('404:シートが見つかりませんでした。');
}

### テンプレート操作 --------------------------------------------------
my $template;
sub setupViewTemplate {
  my (%args) = @_;

  $template = HTML::Template->new(
    filename  => $set::skin_sheet,
    utf8 => 1,
    path => ['./', $::core_dir."/skin/$set::game", $::core_dir."/skin/_common", $::core_dir],
    search_path_on_include => 1,
    die_on_bad_params => 0,
    die_on_missing_include => 0,
    case_sensitive => 1,
    global_vars => 1,
    loop_context_vars => 1,
  );

  $template->param(title => $set::title);
  $template->param(ver => $::ver);
  $template->param(coreDir => $::core_dir);
  $template->param(gameDir => $set::game);
  
  $template->param(mode => $::in{mode});

  $template->param(sheetType => (exists $set::lib_type{$type}) ? $set::lib_type{$type}{sheetType} : 'chara' );
  $template->param(generateType => $args{generateType} // '');
  $template->param(defaultImage => $args{defaultPieceImage} // qq|$::core_dir/skin/$set::game/img/default_pc.png|);

  $template->param(logId => $::in{log});

  $template->param(canonicalURL => url(-full => 1, -query => 0) . "?id=$::in{id}");

  $template->param(LOGIN_ID => $LOGIN_ID);

  return $template;
}
## 最終アウトプット
sub printFinalizedView {
  $template->param(error => $main::login_error);

  print "Content-Type: text/html; charset=utf-8\n\n";
  if($::pc{modeDownload}){
    if($::pc{forbidden} && $::pc{yourAuthor}){ $template->param(forbidden => ''); }
    print downloadModeSheetConvert outputTemplate($template);
  }
  else {
    print outputTemplate($template);
  }
}

### メニュー --------------------------------------------------
sub setSheetMenu {
  return if $::pc{modeDownload};

  my @menu = ();
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './'.($type ? "?type=$type" : '') });
  push(@menu, @_);
  if($::in{url}){ # コンバートビュー
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($::in{log}){ # 過去ログ
      unless($::pc{forbiddenMode}){
        push(@menu, { TEXT => '出力' , TYPE => "onclick", VALUE => "downloadListOn()" });
      }
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()' });
      if($::pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()" }); }
      else                   { push(@menu, { TEXT => '復元', TYPE => "href" , VALUE => "./?mode=edit&id=$::in{id}&log=$::in{log}" });
      }
    }
    else { #通常
      unless($::pc{forbiddenMode}){
        if($template->param('generateType')){
          push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()" });
        }
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()" });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()" });
      }
      if($::pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()" }); }
      else                   { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}" }); }
    }
  }

  $template->param(Menu => createSheetMenu(@menu));
}

sub createSheetMenu {
  my @menu = @_;
  foreach my $line (@menu){
    if (length($line->{TEXT}) >= 4){ $line->{TEXT} = "<span>$line->{TEXT}</span>" }
  }
  return \@menu;
}

### バックアップ一覧 --------------------------------------------------
sub getLogList {
  my $dir  = shift;
  my $file = shift;
  open(my $FH,"${dir}${file}/log-list.cgi") || checkLogFile("${dir}${file}",'view');
  my @lines = reverse <$FH>;
  close($FH);
  my @logs; my $selectedname;
  foreach (@lines){
    chomp;
    my ($date, $epoc, $name) = split('<>', $_, 3);
    
    my ($selected, $query, $text);
    if($date eq 'latest'){
      $selected = (!$::in{log} ? 1 : 0);
      $text     = ($name ? "<b>$name</b>":'') . '最新: ' .epocToDate($epoc);
    }
    else {
      (my $dateview = $date) =~ s/(\d{4}-\d{2}-\d{2})-(\d{2})-(\d{2})/$1 $2:$3/g;
      $selected = ($date eq $::in{log} ? 1 : 0);
      $query    = "&log=$date";
      $text     = ($name ? "<b>$name</b>":'') .epocToDate($epoc);
    }
    push(@logs, { "SELECTED"  => ($selected ? 'selected' : ''), "URL"  => $query, "DATE" => $text });
    if($selected){ $selectedname = $name }
  }
  return $selectedname, \@logs;
}
### カラー出力 --------------------------------------------------
sub setColors {
  my ($pc, $type) = @_;
  setDefaultColors($pc, $type);
  $pc->{$type.'colorBaseBgS'} = $pc->{$type.'colorBaseBgS'} * 0.7;
  $pc->{$type.'colorBaseBgL'} = 100 - $pc->{$type.'colorBaseBgS'} / 6;
  $pc->{$type.'colorBaseBgD'} = 15;
}
### フォント出力 --------------------------------------------------
sub setFont {
  my ($pc, $type) = @_;
  if($pc->{$type.'nameFont'}){
    foreach (@set::googlefonts){
      if($_->[0] eq $pc->{$type.'nameFont'}){
        $pc->{$type.'nameFontUrl'} = $pc->{$type.'nameFont'} =~ s/ /+/gr;
        if($_->[1] =~ /^[0-9]+$/){ $pc->{$type.'nameFontUrl'} .= ":wght@".$_->[1] }
        $pc->{$type.'nameFontWeight'} = $_->[1];
        last;
      }
    }
  }
}
### 伏せ文字 --------------------------------------------------
sub noiseText {
  my $min = shift;
  my $max = shift || $min;
  my $length = $min + (int rand($max - $min + 1));
  my @seed = split(//, '██████████▇▆▅▄▃▂▚▞▙▛▜▟');
  my $text;
  foreach (1 .. $length) {
    $text .= @seed[int rand(scalar @seed)];
  }
  return $text;
}
sub noiseTextTag {
  my $text = shift;
  $text =~ s/<br>/\n/g;
  $text =~ s/^[█▇▆▅▄▃▂▚▞▙▛▜▟\n\s]+$/<span class="censored">$&<\/span>/s;
  $text =~ s/\n/<br>/g;
  return $text;
}
sub isNoiseText {
  my $text = shift;
  return $text =~ /^[█▇▆▅▄▃▂▚▞▙▛▜▟\n\s]+$/ ? 1 : undef;
}
### キャラクター名 --------------------------------------------------
sub renderCharacterName {
  my $name = shift;
  my $ruby = shift;
  $name = insertWbr($name);
  if($name ne '' && $ruby ne '') {
    return "<ruby><rp>｜</rp>${name}<rp>《</rp><rt>${ruby}</rt><rp>》</rp></ruby>"
  }
  return $name;
}
### <wbr>挿入 --------------------------------------------------
sub insertWbr { #固有名詞向け
  my $name = shift;
  $name =~ s#[･・＝／”＞]#$&<wbr>#g;
  $name =~ s#[+＋*＊@＠“＜]#<wbr>$&#g;
  return $name;
}
#sub insertWbrLineBreak { #強引に禁則処理する
#  my $text = shift;
#  $text =~ s#((?:\G|>)[^<]*?)([+\-*/]?[0-9a-zA-Z]+)#$1<wbr>$2#g;
#  $text =~ s#((?:\G|>)[^<]*?)([^0-9a-zA-Z\s][,.、。)）\]］}｝、〕〉》」』】〙〗〟’”｠»ゝゞーァィゥェォッャュョヮヵヶぁぃぅぇぉっゃゅょゎゕゖㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇷ゚ㇺㇻㇼㇽㇾㇿ々〻～!！?？･・:;]{1,3})#$1<span class="nowrap">$2</span>#g;
#  return $text;
#}
### セリフ --------------------------------------------------
sub renderWords {
  my ($words, $x, $y) = @_;
  $words =~ s/<br>/\n/g;
  $words =~ s/“/〝/g;
  $words =~ s/”/〟/g;
  $words =~ s/^([「『（〝])/<span class="brackets">$1<\/span>/gm;
  $words =~ s/(.+?(?:[，、。？」』）〟]|$))/<span>$1<\/span>/g;
  $words =~ s/\n<span>　/\n<span>/g;
  $words =~ s/\n/<br>/g;
  $x = $x eq '左' ? 'left:0;' : 'right:0;';
  $y = $y eq '下' ? 'bottom:0;' : 'top:0;';
  return $words, $x, $y;
}
### セッション履歴 --------------------------------------------------
# 数字列を成形する
sub formatHistoryFigures {
  my $text = shift;
  $text =~ s/[0-9]+/commify($&);/ge;
  $text =~ s#[0-9,]+#<span class="number">$&</span><wbr>#g;
  return $text;
}
### ダウンロード用 --------------------------------------------------
sub downloadModeSheetConvert {
  my $sheet = shift;
  $sheet =~ s#<link rel="stylesheet" data-dl href="(.+?)(\?.+?)?">#"<style>\n".styleToHtml($1)."\n</style>"#gie;
  $sheet =~ s#<script data-dl src="(.+?)(\?.+?)?"></script>#"<script>\n".styleToHtml($1)."\n</script>"#gie;
  return $sheet;
}
sub styleToHtml {
  my $output;
  open(my $FH, '<', $_[0]);
  $output .= $_ foreach <$FH>;
  close($FH);
  
  (my $dir = $_[0]) =~ s#/[^/]+?$##;
  $output =~ s/url\((.+?\.png|jpg|gif|webp)\)/"url(".urlToBase64("$dir\/$1").")"/gie;
  return "$output";
}
use MIME::Base64;
sub urlToBase64 {
  my $url = shift;
  my $ext = shift;
  $url =~ s#\?.*?$##;
  if(!$ext){
    ($ext = $url) =~ s/^.+\.(png|jpg|gif|webp)$/$1/;
    if ($ext eq "jpg") { $ext ="jpeg"; }
  }
  open(my $IMG, '<', "$url");
  binmode $IMG;
  my $binary; my $buffer;
  while(read($IMG, $buffer, 2048)) { $binary .= $buffer }
  close($IMG);
  my $base64 = encode_base64($binary, '');
  return "data:image/$ext;base64,$base64";
}

1;
