################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{mode};
my $sort = $::in{sort};

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/ms", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$INDEX->param(modeList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => '都民');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{tag} || $::in{group} || $::in{name} || $::in{player} || $::in{lvmin} || $::in{lvmax} || $::in{taxa} || $::in{home} || $::in{origin} || $::in{clan} || $::in{address} || $::in{image})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
  $INDEX->param(simpleList => 1) if $set::simplelist;
}
my @q_links;
foreach(
  'mode',
  'tag',
  #'group',
  'name',
  'player',
  'lvmin',
  'lvmax',
  'taxa',
  'home',
  'origin',
  'clan',
  'address',
  'image',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = @q_links ? '&'.join('&', @q_links) : '';

### ファイル読み込み --------------------------------------------------
my @list;
#グループ見出しのみ
if($set::simpleindex && $index_mode) {
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
      @list = grep { !/^(?:[^<]*<>){9}[^<0]/ } <$FH>;
    }
    close($FH);
  }
}
### 検索処理 --------------------------------------------------
## グループ検索
my $group_query = $::in{group};
my %groups = groupArrayToHash();
$groups{all}{name} = 'すべて' if $::in{group} eq 'all';
$INDEX->param(Groups => groupArrayToList $group_query);

if($group_query && $::in{group} ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { /^(?:[^<]*<>){6}(\Q$group_query\E)?</ } @list; }
  else { @list = grep { /^(?:[^<]*<>){6}\Q$group_query\E</ } @list; }
}
$INDEX->param(group => $groups{$group_query}{name});

## タグ検索
my $tag_query = normalizeHashtags(decode('utf8', $::in{tag}));
if($tag_query) { @list = grep { /^(?:[^<]*<>){8}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = lc decode('utf8', $::in{name});
if($name_query) { @list = grep { /^(?:[^<]*<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## PL名検索
my $pl_query = decode('utf8', $::in{player});
if($pl_query) { @list = grep { /^(?:[^<]*<>){5}[^<]*?\Q$pl_query\E/i } @list; }
$INDEX->param(player => $pl_query);

## 強度検索
my $lv_min_query = $::in{'lv-min'};
my $lv_max_query = $::in{'lv-max'};
if($lv_min_query) { @list = grep { (/^(?:[^<]*<>){11}([^<]*)/)[0] >= $lv_min_query } @list; }
if($lv_max_query) { @list = grep { (/^(?:[^<]*<>){11}([^<]*)/)[0] <= $lv_max_query } @list; }
$INDEX->param(lvMin => $lv_min_query);
$INDEX->param(lvMax => $lv_max_query);
my $lv_query;
if   ($lv_min_query eq $lv_max_query){ $lv_query = $lv_min_query; }
elsif($lv_min_query || $lv_max_query){ $lv_query = $lv_min_query.'～'.$lv_max_query; }
$INDEX->param(lv => $lv_query);

## 分類検索
my $taxa_query = decode('utf8', $::in{taxa});
if($taxa_query) { @list = grep { /^(?:[^<]*<>){13}[^<]*?\Q$taxa_query\E/ } @list; }
$INDEX->param(taxa => $taxa_query);

## 所属検索
my $clan_query = decode('utf8', $::in{clan});
if($clan_query) { @list = grep { /^(?:[^<]*<>){17}[^<]*?\Q$clan_query\E/ } @list; }
$INDEX->param(clan => $clan_query);

## 画像フィルタ
if($::in{image} == 1) {
  @list = grep { /^(?:[^<]*<>){7}[^<0]/ } @list;
  $INDEX->param(image => 1);
}
elsif($::in{image} eq 'N') {
  @list = grep { !/^(?:[^<]*<>){7}[^<0]/ } @list;
  $INDEX->param(image => 0);
}
### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @t = map { sortName($_)                         } @list; @list = @list[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
elsif($sort eq 'pl')    { my @t = map { (/^(?:[^<]*<>){5}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
elsif($sort eq 'date')  { my @t = map { (/^(?:[^<]*<>){3}([^<]*)/)[0]  } @list; @list = @list[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }

sub sortName { $_[0] =~ /^(?:[^<]*<>){4}(?:“\s*(.*?)”)?\s*(.*?)</; return $2 || $1; }

### リストを回す --------------------------------------------------
my %count = ( PC => {}, PL => {} );
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
if($::in{group} && $set::pagemax){
  $count{PC}{$::in{group}} = scalar(@list);
  $count{PL}{$::in{group}} = {};
  if($set::playerlist){
    $count{PL}{$::in{group}}{ (/^(?:[^<]*<>){5}([^<]*)/)[0] }++ foreach @list;
  }
  $pageend = $count{PC}{$::in{group}} if $pageend > $count{PC}{$::in{group}};
  @list = @list[$pagestart-1 .. $pageend-1];
}
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group, #0-6
    $image, $tags, $hide, $session, #7-10
    $level, $endurance, #11-12
    $taxa, $home, $origin, $background, #13-16
    $clan, $clanEmotion, $address, #17-19
  ) = (split /<>/, $_)[0..19];
  
  #グループ
  $group = $set::group_default if (!$group || !$groups{$group});
  $group = 'all' if $::in{group} eq 'all';
  
  unless($::in{group} && $set::pagemax){
    #カウント
    $count{PC}{$group}++;
    $count{PL}{$group}{$player}++;

    #表示域以外は弾く
    if (
      ( $index_mode && $count{PC}{$group} > $set::list_maxline && $set::list_maxline) || #TOPページ
      (!$index_mode && $set::pagemax && ($count{PC}{$group} < $pagestart || $count{PC}{$group} > $pageend)) #それ以外
    ){
      next;
    }
  }
  
  #名前
  $name =~ s/^“(.*)”(.*)/<span>“$1”<\/span><span>$2<\/span>/;
  
  ## シンプルリスト
  if($index_mode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID => $id,
      NAME => $name,
      PLAYER => $player,
      GROUP => $group,
      LEVEL => $level,
      HIDE => $hide,
    });
    push(@{$grouplist{$group}}, @characters);
  }
  ## 通常リスト
  else {

    #タグ
    my $tags_links;
    foreach(grep $_, split(/ /, $tags)){ $tags_links .= '<a href="./?tag='.uri_escape_utf8($_).'">'.$_.'</a>'; }
    
    #最終参加セッション
    if($session){ $tags_links .= '<span class="session">'.$session.'</span>' }
    
    #更新日時
    my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
    $year += 1900; $mon++;
    $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
    
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID => $id,
      NAME => $name,
      PLAYER => $player,
      GROUP => $group,
      LEVEL => $level,
      TAXA => $taxa,
      HOME => $home,
      ORIGIN => $origin,
      CLAN => $clan,
      ADDRESS => $address,
      TAGS => $tags_links,
      DATE => $updatetime,
      HIDE => $hide,
    });
    push(@{$grouplist{$group}}, @characters);
  }
}

### 出力用配列 --------------------------------------------------
my @characterlists;
foreach my $id (sort {$groups{$a}{sort} <=> $groups{$b}{sort}} keys %grouplist){
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && ($::in{group} || $mode eq 'mylist')){
    my $lastpage = ceil($count{PC}{$id} / $set::pagemax);
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
          $navbar .= '<a href="./?group='.$id.$q_links.'&page='.$_.'&sort='.$::in{sort}.'">'.$_.'</a> '
        }
        else { $navbar .= '...' }
      }
      $navbar =~ s/\.{3,}/... /g;
    }
    $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  }
  
  ##
  push(@characterlists, {
    "ID" => $id,
    "NAME" => $groups{$id}{name},
    "TEXT" => $groups{$id}{text},
    "NUM-PC" => $count{PC}{$id},
    "NUM-PL" => $count{PL}{$id},
    "Characters" => [@{$grouplist{$id}}],
    "NAV" => $navbar,
    "MORE" => (!$navbar && $count{PC}{$id} > scalar(@{$grouplist{$id}}) ? 1 : 0),
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(ogUrl => self_url());
$INDEX->param(ogDescript => 
  ($name_query ? "名前「${name_query}」を含む " : '') .
  ($pl_query   ? "ＰＬ名「${pl_query}」を含む " : '') .
  ($tag_query  ? "タグ「${tag_query}」 " : '')
);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);
$INDEX->param(gameDir => $set::game);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print outputTemplate($INDEX);

1;