###################### ファイル一覧 ######################
use strict;
use utf8;

package set;

##################################################
  our $data_dir   = 'data/';

  our $lib_edit   = 'lib/edit.pl';
  our $lib_save   = 'lib/save.pl';
  our $lib_view   = 'lib/view.pl';
  our $lib_json   = 'lib/json.pl';
  our $lib_list   = 'lib/list.pl';
  
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

  our $skin_sheet = 'skin/sheet.html';
  our $skin_tmpl  = 'skin/template.html';
  

1;