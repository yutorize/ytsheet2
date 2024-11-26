################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{mode};
my $sort = $::in{sort};

#require $set::data_item;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

$INDEX->param(modeItemList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => 'アイテム');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);
$INDEX->param(type => 'i');

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{tag} || $::in{category} || $::in{name} || $::in{author} || $::in{age})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}
my @q_links;
foreach(
  'mode',
  'tag',
  'name',
  'category',
  'author',
  'age',
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
#if($set::simpleindex && $index_mode){ #グループ見出しのみ
#  my @grouplist;
#    push(@grouplist, {
#      "ID" => 'all',
#      "NAME" => 'すべて',
#    });
#  $INDEX->param(ListGroups => \@grouplist);
#}
#else { #通常
  open (my $FH, "<", $set::listfile);
  @list = <$FH>;
  close($FH);
#}
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
  @list = grep { $_ !~ /^(?:[^<]*?<>){13}[^<0]/ } @list;
}

## カテゴリ検索
my @category_query = split('\s', decode('utf8', $::in{category}));
if($::in{category} ne 'all'){
  foreach (@category_query) {
    my $q = $_;
    if($q =~ s/^-//){ @list = grep { $_ !~ /^(?:[^<]*?<>){6}[^<]*?\Q$q\E/ } @list; } #マイナス検索
    else            { @list = grep { $_ =~ /^(?:[^<]*?<>){6}[^<]*?\Q$q\E/ } @list; }
  }
  $INDEX->param(category => "@category_query");
}

## タグ検索
my $tag_query = normalizeHashtags(decode('utf8', $::in{tag}));
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){12}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{name});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## 製作時期検索
my $age_query = decode('utf8', $::in{age});
if($age_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){8}[^<]*?\Q$age_query\E/i } @list; }
$INDEX->param(age => $age_query);

### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @tmp = map { (split /<>/)[4] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'author'){ my @tmp = map { (split /<>/)[5] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3] } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $author, $category, $price, $age, $summary, $type,
    $image, $tag, $hide
  ) = (split /<>/, $_)[0..13];
  
  #カウント
  $count{'すべて'}++;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{'すべて'} > $set::list_maxline && $set::list_maxline) || #TOPページ
    (!$index_mode && $set::pagemax && ($count{'すべて'} < $pagestart || $count{'すべて'} > $pageend)) #それ以外
  ){
    next;
  }
  
  #グループ（分類）
  $category =~ s/[ 　]/<br>/g;

  #価格
  $price = commify $price if $price =~ /\d{4,}/;
  $price =~ s/[+＋\/／]/<wbr>$&<wbr>/g;
  
  #タグ
  my $tags_links;
  foreach(grep $_, split(/ /, $tag)){ $tags_links .= '<a href="./?type=i&tag='.uri_escape_utf8($_).'">'.$_.'</a>'; }

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
    "CATEGORY" => $category,
    "PRICE" => $price,
    "AGE" => $age,
    "SUMMARY" => $summary,
    "MAGIC" => ($type =~ /\[ma\]/ ? "<img class=\"${set::icon_dir}wp_magic.png\">" : ''),
    "TAGS" => $tags_links,
    "DATE" => $updatetime,
    "HIDE" => $hide,
  });
  
  push(@{$grouplist{'すべて'}}, @characters);
}

### 出力用配列 --------------------------------------------------
my @characterlists;
our @categories = (
  ['すべて','']
);
foreach (@categories){
  my $name = $_->[0];
  next if !$count{$name};

  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode){
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
          $navbar .= '<a href="./?type=i'.$q_links.'&page='.$_.'&sort='.$::in{sort}.'">'.$_.'</a> '
        }
        else { $navbar .= '...' }
      }
      $navbar =~ s/\.{3,}/... /g;
    }
    $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  }

  ##
  push(@characterlists, {
    "URL" => uri_escape_utf8($name),
    "NAME" => $name,
    "NUM" => $count{$name},
    "Characters" => [@{$grouplist{$name}}],
    "NAV" => $navbar,
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(ogUrl => self_url());
$INDEX->param(ogDescript => 
  ($name_query  ? "名称「${name_query}」を含む " : '') .
  ($tag_query   ? "タグ「${tag_query}」 " : '') .
  (@category_query ? "カテゴリ「@{category_query}」 " : '') .
  ($age_query      ? "製作時期「${age_query}」 " : '')
);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;