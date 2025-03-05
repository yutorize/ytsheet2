################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{mode};
my $sort = $::in{sort};

require $set::data_mons;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

$INDEX->param(modeMonsList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => '魔物');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);
$INDEX->param(type => 'm');

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{tag} || $::in{taxa} || $::in{mount} || $::in{name} || $::in{'lv-max'} || $::in{'lv-min'} || $::in{'parts-max'} || $::in{'parts-min'} || $::in{intellect} || $::in{perception} || $::in{disposition} || $::in{habitat} || $::in{weakness})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}
if(!$::in{taxa} && $mode ne 'mylist'){ $INDEX->param(modeTaxaAll => 1); }
my @q_links;
foreach(
  'mode',
  'tag',
  #'taxa',
  'mount',
  'name',
  'lv-min',
  'lv-max',
  'parts-min',
  'parts-max',
  'intellect',
  'perception',
  'disposition',
  'habitat',
  'weakness',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = @q_links ? '&'.join('&', @q_links) : '';

### ファイル読み込み --------------------------------------------------
## マイリスト取得
my @mylist;
if($mode eq 'mylist'){
  $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
  open (my $FH, "<", $set::passfile);
  while(my $line = <$FH>){
    if($line =~ /^(.+?)<>\[$LOGIN_ID\]</){ push(@mylist, $1) }
  }
  close($FH);
}

## リスト取得
my @list;
if($set::simpleindex && $index_mode && $mode ne 'mylist') { #グループ見出しのみ
  $INDEX->param(simpleIndex => 1);
}
else { #通常
  open (my $FH, "<", $set::listfile);
  @list = <$FH>;
  close($FH);
}
### フィルタ処理 --------------------------------------------------
## マイリスト
if($mode eq 'mylist'){
  my $regex = join('|', @mylist);
  @list = grep { $_ =~ /^(?:$regex)\</ } @list;
}
## 非表示除外
elsif (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !$::in{tag}
){
  @list = grep { !(split(/<>/))[16] } @list;
}

## 分類検索
my $taxa_query = decode('utf8', $::in{taxa});
if($::in{mount}) {
  if($taxa_query eq 'all'){ $taxa_query = '' }
  @list = grep { $_ =~ /^(?:[^<]*?<>){6}騎獣／\Q$taxa_query\E/ } @list;
}
elsif($taxa_query) {
  @list = grep { $_ !~ /^(?:[^<]*?<>){6}騎獣／/ } @list;
  if($taxa_query eq 'その他') {
    @list = grep { $_ =~ /^(?:[^<]*?<>){6}その他/ } @list;
  }
  elsif($taxa_query ne 'all') {
    @list = grep { $_ =~ /^(?:[^<]*?<>){6}\Q$taxa_query\E</ } @list;
  }
}
if($::in{mount}){ $INDEX->param(group => '騎獣'.($taxa_query?"／$taxa_query":'')      ); }
else            { $INDEX->param(group => $taxa_query eq 'all' ? 'すべて' : $taxa_query); }
$INDEX->param(mount => $::in{mount} ? 'checked' : '');
my @taxalist;
foreach (sort { $a->[1] cmp $b->[1] } @data::taxa){
  push(@taxalist, {
    "ID"   => @$_[0],
    "NAME" => @$_[0],
    "SELECTED" => $taxa_query eq @$_[0] ? 'selected' : '',
  });
}
$INDEX->param(Taxa => \@taxalist);

## タグ検索
my $tag_query = normalizeHashtags(decode('utf8', $::in{tag}));
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){15}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{name});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## 知能検索
my $intellect_query = decode('utf8', $::in{intellect});
if($intellect_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){8}\Q$intellect_query\E/ } @list; }
$INDEX->param(intellect => $intellect_query);

## 知覚検索
my $perception_query = decode('utf8', $::in{perception});
if($perception_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){9}\Q$perception_query\E/ } @list; }
$INDEX->param(perception => $perception_query);

## 反応検索
my $disposition_query = decode('utf8', $::in{disposition});
if($disposition_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){10}\Q$disposition_query\E/ } @list; }
$INDEX->param(disposition => $disposition_query);

## 生息地検索
my $habitat_query = decode('utf8', $::in{habitat});
if($habitat_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){18}\Q$habitat_query\E/ } @list; }
$INDEX->param(habitat => $habitat_query);

## 弱点検索
my $weakness_query = decode('utf8', $::in{weakness});
if($weakness_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){13}\Q$weakness_query\E/ } @list; }
$INDEX->param(weakness => $weakness_query);

## レベル検索
my $lv_min_query = $::in{'lv-min'};
my $lv_max_query = $::in{'lv-max'};
if($lv_min_query) { @list = grep { (split(/<>/))[7] >= $lv_min_query } @list; }
if($lv_max_query) { @list = grep { lvMaxCheck((split(/<>/))[7]) <= $lv_max_query } @list; }
$INDEX->param(lvMin => $lv_min_query);
$INDEX->param(lvMax => $lv_max_query);
my $lv_query;
if   ($lv_min_query eq $lv_max_query){ $lv_query = $lv_min_query; }
elsif($lv_min_query || $lv_max_query){ $lv_query = $lv_min_query.'～'.$lv_max_query; }
$INDEX->param(level => $lv_query);

## 部位数検索
my $parts_min_query = $::in{'parts-min'};
my $parts_max_query = $::in{'parts-max'};
if($parts_min_query) { @list = grep { (split(/<>/))[17] >= $parts_min_query } @list; }
if($parts_max_query) { @list = grep { (split(/<>/))[17] <= $parts_max_query } @list; }
$INDEX->param(partsMin => $parts_min_query);
$INDEX->param(partsMax => $parts_max_query);
my $parts_query;
if   ($parts_min_query eq $parts_max_query){ $parts_query = $parts_min_query; }
elsif($parts_min_query || $parts_max_query){ $parts_query = $parts_min_query.'～'.$lv_max_query; }
$INDEX->param(parts => $parts_query);
sub lvMaxCheck {
  my ($min, $max) = split(/-/, shift);
  return $max || $min;
}

### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @tmp = map { (split /<>/)[4] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'author'){ my @tmp = map { (split /<>/)[5] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3] } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'lv')    { my @tmp = map { (split /<>/)[7] } @list; @list = @list[sort {$tmp[$a] <=> $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'parts') { my @tmp = map { (split /<>/)[17] } @list; @list = @list[sort {$tmp[$a] <=> $tmp[$b]} 0 .. $#tmp]; }
# unless($index_mode && $set::list_maxline){
#   my @tmp = map { (split /<>/)[7] } @list; @list = @list[sort {$tmp[$a] <=> $tmp[$b]} 0 .. $#tmp];
# }

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $author, $taxa, $lv,
    $intellect, $perception, $disposition, $sin, $initiative, $weakness,
    $image, $tags, $hide, $parts, $habitat, $price
  ) = (split /<>/, $_)[0..19];
  
  #グループ
  my $taxa_full = $taxa =~ s/^その他://r;
  $taxa_full = "<span class=\"small\">$taxa_full</span>" if length($taxa_full) >= 6;
  if($taxa =~ /^騎獣／/){ $taxa = '騎獣'; }
  else {
    if (!$taxa){ $taxa = '未分類' }
    elsif($taxa =~ /^その他/){ $taxa = 'その他' }

    if($taxa_query eq 'all'){
      $taxa = 'すべて';
    }
    elsif (!$index_mode){
      $taxa = $taxa_query || 'すべて';
    }
  }
  
  #カウント
  $count{$taxa}++;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{$taxa} > $set::list_maxline && $set::list_maxline) || #TOPページ
    ( !$::in{taxa} && !$::in{tag} && $mode ne 'mylist' && $count{$taxa} > $set::list_maxline && $set::list_maxline) || #検索結果（分類指定なし／マイリストでもなし）
    (!$index_mode && $set::pagemax && ($count{$taxa} < $pagestart || $count{$taxa} > $pageend)) #それ以外
  ){
    next;
  }

  # 価格
  $price =~ s#^／#―／#;
  $price =~ s#／$#／―#;

  #タグ
  my $tags_links;
  foreach(grep $_, split(/ /, $tags)){ $tags_links .= '<a href="./?type=m&tag='.uri_escape_utf8($_).'">'.$_.'</a>'; }
  
  #更新日時
  my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
  $year += 1900; $mon++;
  $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
  
  #出力用配列へ
  my @characters;
  push(@characters, {
    "ID" => $id,
    "NAME" => $name,
    "AUTHOR" => $author,
    "TAXA" => $taxa_full,
    "LV" => $lv,
    "PARTS" => $parts,
    "DISPOSITION" => $disposition,
    "HABITAT" => $habitat,
    "PRICE" => $price,
    "TAGS" => $tags_links,
    "DATE" => $updatetime,
    "HIDE" => $hide,
  });
  
  push(@{$grouplist{$taxa}}, @characters);
}

### 出力用配列 --------------------------------------------------
my @characterlists; 
@data::taxa = sort{$a->[1] <=> $b->[1]} @data::taxa;
my @taxa = $index_mode || ($taxa_query && $taxa_query ne 'all') ? @data::taxa : ['すべて','',];
foreach (@taxa,['騎獣', 'XX' , '']){
  my $name = $_->[0];
  next if !$count{$name};

  my $urltaxa;
  if($name eq '騎獣'){
    if($taxa_query && $taxa_query ne 'all'){ $urltaxa = uri_escape_utf8($name); }
    else { $urltaxa = 'all'; }
    if(!$::in{mount}){ $urltaxa .= '&mount=1' }
  }
  elsif($name eq 'すべて'){
    $urltaxa = 'all';
  }
  else {
    $urltaxa = uri_escape_utf8($name);
  }
  
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && ($::in{taxa} || $mode eq 'mylist')){
    my $lastpage = ceil($count{$name} / $set::pagemax);
    if($lastpage > 1){
      foreach(1 .. $lastpage){
        if($_ == $page){
          $navbar .= '<b>'.$_.'</b> ';
        }
        elsif(
          ($_ <= $page + 4 && $_ >= $page - 4) ||
          $_ == 1 ||
          $_ == $lastpage
        ){
          $navbar .= '<a href="./?type=m&taxa='.$urltaxa.$q_links.'&page='.$_.'&sort='.$::in{sort}.'">'.$_.'</a> '
        }
        else { $navbar .= '...' }
      }
      $navbar =~ s/\.{3,}/... /g;
    }
    $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  }

  my $text;
  if($name eq 'すべて'){ $text = '騎獣以外のすべての魔物' }
  if($name eq '騎獣'){
    if($taxa_query){ $text = "／$taxa_query" }
    else { $text = 'すべての騎獣' }
  }

  ##
  push(@characterlists, {
    "URL" => 'taxa='.$urltaxa,
    "NAME" => "$name <small>$text</small>",
    "NUM" => $count{$name},
    "MOUNT" => ($name eq '騎獣' ? 1 : 0),
    "Characters" => ($grouplist{$name} ? [@{$grouplist{$name}}] : []),
    "NAV" => $navbar,
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(ogUrl => self_url());
$INDEX->param(ogDescript => 
  ($taxa_query ? "分類「${taxa_query}」" : '') .
  ($name_query ? "名称「${name_query}」を含む " : '') .
  ($tag_query  ? "タグ「${tag_query}」 " : '') .
  ($lv_query          ? "レベル「${lv_query}」 " : '') .
  ($parts_query       ? "部位数「${parts_query}」 " : '') .
  ($intellect_query   ? "知能「${intellect_query}」 " : '') .
  ($perception_query  ? "知覚「${perception_query}」 " : '') .
  ($disposition_query ? "反応「${disposition_query}」 " : '') .
  ($habitat_query     ? "生息地「${habitat_query}」 " : '') .
  ($weakness_query    ? "弱点「${weakness_query}」 " : '')
);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;