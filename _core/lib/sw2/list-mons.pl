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
if(!($mode eq 'mylist' || $::in{tag} || $::in{taxa} || $::in{mount} || $::in{name} || $::in{author} || $::in{'lv-max'} || $::in{'lv-min'} || $::in{'parts-max'} || $::in{'parts-min'} || $::in{intellect} || $::in{perception} || $::in{disposition} || $::in{habitat} || $::in{weakness})){
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
  'author',
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
my @list;
#グループ見出しのみ
if($set::simpleindex && $index_mode && $mode ne 'mylist') {
  $INDEX->param(simpleIndex => 1);
}
#通常
else {
  # マイリスト
  if($mode eq 'mylist'){
    $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
    @list = getMylist($LOGIN_ID);
  }
  else {
    open (my $FH, "<", $set::listfile);
    # 管理者orタグ検索（全読込）
    if(($set::masterid && $set::masterid eq $LOGIN_ID) || $::in{tag}){
      @list = <$FH>;
    }
    # 非表示除外
    else {
      @list = grep { !/^(?:[^<]*<>){16}[^<0]/ } <$FH>;
    }
    close($FH);
  }
}
### フィルタ処理 --------------------------------------------------
## 分類検索
my $taxa_query = decode('utf8', $::in{taxa});
if($::in{mount}) {
  if($taxa_query eq 'all'){ $taxa_query = '' }
  @list = grep { /^(?:[^<]*<>){6}騎獣／\Q$taxa_query\E/ } @list;
}
elsif($taxa_query) {
  @list = grep { !/^(?:[^<]*<>){6}騎獣／/ } @list;
  if($taxa_query eq 'その他') {
    @list = grep { /^(?:[^<]*<>){6}その他/ } @list;
  }
  elsif($taxa_query ne 'all') {
    @list = grep { /^(?:[^<]*<>){6}\Q$taxa_query\E</ } @list;
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
if($tag_query) { @list = grep { /^(?:[^<]*<>){15}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{name});
if($name_query) { @list = grep { /^(?:[^<]*<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## 投稿者検索
my $author_query = decode('utf8', $::in{author});
if($author_query) { @list = grep { /^(?:[^<]*<>){5}[^<]*?\Q$author_query\E/i } @list; }
$INDEX->param(author => $author_query);

## 知能検索
my $intellect_query = decode('utf8', $::in{intellect});
if($intellect_query) { @list = grep { /^(?:[^<]*<>){8}\Q$intellect_query\E/ } @list; }
$INDEX->param(intellect => $intellect_query);

## 知覚検索
my $perception_query = decode('utf8', $::in{perception});
if($perception_query) { @list = grep { /^(?:[^<]*<>){9}\Q$perception_query\E/ } @list; }
$INDEX->param(perception => $perception_query);

## 反応検索
my $disposition_query = decode('utf8', $::in{disposition});
if($disposition_query) { @list = grep { /^(?:[^<]*<>){10}\Q$disposition_query\E/ } @list; }
$INDEX->param(disposition => $disposition_query);

## 生息地検索
my $habitat_query = decode('utf8', $::in{habitat});
if($habitat_query) { @list = grep { /^(?:[^<]*<>){18}\Q$habitat_query\E/ } @list; }
$INDEX->param(habitat => $habitat_query);

## 弱点検索
my $weakness_query = decode('utf8', $::in{weakness});
if($weakness_query) { @list = grep { /^(?:[^<]*<>){13}\Q$weakness_query\E/ } @list; }
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
if   ($sort eq 'name')  { my @t = map { (/^(?:[^<]*<>){4}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
elsif($sort eq 'author'){ my @t = map { (/^(?:[^<]*<>){5}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
elsif($sort eq 'date')  { my @t = map { (/^(?:[^<]*<>){3}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
elsif($sort eq 'lv')    { my @t = map { (/^(?:[^<]*<>){7}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$a] <=> $t[$b]} 0 .. $#t]; }
elsif($sort eq 'parts') { my @t = map { (/^(?:[^<]*<>){17}([^<]*)/)[0] } @list; @list = @list[sort {$t[$a] <=> $t[$b]} 0 .. $#t]; }

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
if(($::in{taxa}) && $set::pagemax){
  my $taxa = $::in{mount} ? '騎獣' : $::in{taxa} eq 'all' ? 'すべて' : $taxa_query;
  $count{$taxa} = scalar(@list);
  $pageend = $count{$taxa} if $pageend > $count{$taxa};
  @list = @list[$pagestart-1 .. $pageend-1];
}
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
  
  unless($::in{taxa} && $set::pagemax){
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
  }

  # 適正レベル
  $lv =~ s/^(\d+)-(\d+)$/$1～$2/;

  # 価格
  $price =~ s#^／#―／#;
  $price =~ s#／$#／―#;
  $price = commify($price);

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
    if($taxa_query && $taxa_query ne 'all'){ $urltaxa = uri_escape_utf8($taxa_query); }
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
    "MORE" => (!$navbar && $count{$name} > scalar(@{$grouplist{$name}}) ? 1 : 0),
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
$INDEX->param(gameDir => $set::game);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print outputTemplate($INDEX);

1;