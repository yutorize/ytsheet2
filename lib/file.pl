###################### ファイル一覧 ######################
use strict;
use utf8;

package set;

##################################################

  our $data_dir = 'data/'; # キャラクターデータ格納ディレクトリ

  our $passfile = 'data/charpass.cgi'; # パスワード記録ファイル
  our $listfile = 'data/charlist.cgi'; # キャラクター一覧ファイル
  our $userfile = 'data/users.cgi';    # ユーザー一覧ファイル

  our $lib_edit   = 'lib/edit.pl';
  our $lib_save   = 'lib/save.pl';
  our $lib_view   = 'lib/view.pl';
  our $lib_json   = 'lib/json.pl';
  our $lib_list   = 'lib/list.pl';
  
  our $lib_delete = 'lib/delete.pl';
  
  our $lib_form    = 'lib/form.pl';
  our $lib_info    = 'lib/info.pl';
  our $lib_register= 'lib/register.pl';
  our $lib_reminder= 'lib/reminder.pl';
  our $login_users = 'tmp/login_users.cgi';
  
  our $tokenfile  = 'tmp/token.cgi'; 

  our $data_feats = 'lib/data-feats.pl';
  our $data_races = 'lib/data-races.pl';
  our $data_items = 'lib/data-items.pl';
  our $data_faith = 'lib/data-faith.pl';

  our $skin_tmpl  = 'skin/template.html'; # 一覧など
  our $skin_sheet = 'skin/sheet.html';    # キャラクターシート
  
 # 変更する場合は同様の項目をconfig.cgiに追記してください
 # ※アップデート時の上書き防止
 # ※config.cgiのほうが優先されます

1;