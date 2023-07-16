use strict;
use utf8;
use LWP::UserAgent;
use JSON::PP;

my $browser = LWP::UserAgent->new;
my $json = JSON::PP->new;

my %token_url_list = (
  'Discord' => 'https://discord.com/api/oauth2/token',
  'Google' => 'https://accounts.google.com/o/oauth2/token'
);
my %client_name_list = (
  'Discord' => 'DiscordBot (ytsheet, 6)',
  'Google' => 'Google API Request (ytsheet)'
);


sub getAccessToken {  
  my $code = $_[0];
  my $token_url = $token_url_list{$set::oauth_service};

  my $token_request = HTTP::Request->new(POST => $token_url);
  $token_request->content_type('application/x-www-form-urlencoded');
  $token_request->header("User-Agent" => $client_name_list{$set::oauth_service});
  my $body = "redirect_uri=$set::oauth_redirect_url&scope=$set::oauth_scope&client_id=$set::oauth_client_id&client_secret=$set::oauth_secret_id&grant_type=authorization_code&code=$code";
  $token_request->content($body);
  my $token_response = $browser->request($token_request);
  my @rawLog = decode_json $token_response->content;
  my $token = $rawLog[0]->{'access_token'};
  return $token;
}

sub getUserInfo {
  my $token = $_[0];
  if ( $set::oauth_service eq 'Discord' ) {
    my $id_request = HTTP::Request->new(GET => 'https://discord.com/api/users/@me');
    $id_request->content_type('application/x-www-form-urlencoded');
    $id_request->header("User-Agent" => $client_name_list{$set::oauth_service});
    $id_request->header("Authorization" => "Bearer $token");
    my $id_response = $browser->request($id_request);
    my $rawJson = $id_response->content;
    my @rawLog = decode_json $rawJson;
    my $id = @rawLog[0]->{'id'};
    my $name = @rawLog[0]->{'username'};
    my $mail = @rawLog[0]->{'email'};
    return ($id, $name, $mail);
	}
  if ( $set::oauth_service eq 'Google' ) {
    my $id_request = HTTP::Request->new(GET => 'https://www.googleapis.com/oauth2/v1/userinfo');
    $id_request->content_type('application/x-www-form-urlencoded');
    $id_request->header("User-Agent" => $client_name_list{$set::oauth_service});
    $id_request->header("Authorization" => "Bearer $token");
    my $id_response = $browser->request($id_request);
    my $rawJson = $id_response->content;
    my @rawLog = decode_json $rawJson;
    my $id = @rawLog[0]->{'id'};
    my $name = @rawLog[0]->{'name'};
    my $mail = @rawLog[0]->{'email'};
    return ($id, $name, $mail);
	}
}

sub isDiscordServerIncluded {
  my ($token, @list) = @_;
  my $server_request = HTTP::Request->new(GET => 'https://discord.com/api/users/@me/guilds');
  $server_request->content_type('application/x-www-form-urlencoded');
  $server_request->header("User-Agent" => $client_name_list{$set::oauth_service});
  $server_request->header("Authorization" => "Bearer $token");
  my $server_response = $browser->request($server_request);
  my $rawServerList = $server_response->content;
  my $parsedServerList = decode_json $rawServerList;
  foreach my $serverInfo (@$parsedServerList) {
    foreach my $serverId (@list) {
      if( $serverInfo->{'id'} eq $serverId ) {
        return 1;
      }
    }  
  }
  return 0;
}

sub isIdExist {
	my $id = $_[0];
  open (my $FH, '<', $set::userfile);
  my $isUsed = 0;
  while (<$FH>){ 
    if ($_ =~ /^$id<>/){ $isUsed = 1; }
  }
  close ($FH);
  return $isUsed;
}

sub registerUser {
  my $id = @_[0];
  my $name = @_[1];
  my $mail = @_[2];
  my $password = "";
  my @salt = ('0'..'9','A'..'Z','a'..'z','.','/');
  1 while (length($password .= $salt[rand(@salt)] ) < 12);
  sysopen (my $FH, $set::userfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
    # print $FH "$id<>".&e_crypt($password)."<>".Encode::decode('utf8', $name)."<>$mail<>".time."<>\n";
    print $FH "$id<>".&e_crypt($password)."<>$name<>$mail<>".time."<>\n";
  close ($FH);

  if($set::player_dir){
    if (!-d $set::player_dir.$id){ mkdir $set::player_dir.$id; }
    sysopen (my $FH, $set::player_dir.$id.'/data.cgi', O_WRONLY | O_APPEND | O_CREAT, 0666);
      print $FH "id<>$id\n";
      print $FH "name<>$name\n";
    close ($FH);
  }
}

sub generateToken {
  my $s;
  my @salt = ('0'..'9','A'..'Z','a'..'z','.','/');
  1 while (length($s .= $salt[rand(@salt)] ) < 12);
  return $s;
}

sub registerToken {
  my $id = $_[0];
  my $key = $_[1];
  sysopen (my $FH, $set::login_users, O_RDWR | O_CREAT, 0666);
    flock($FH, 2);
    my @list = <$FH>;
    seek($FH, 0, 0);
    foreach (@list){
      my @line = (split/<>/, $_);
      if (time - $line[2] < 60*60*24*365){
        print $FH $_;
      }
    }
    print $FH "$id<>$key<>".time."<>\n";
    truncate($FH, tell($FH));
  close ($FH);
  return &cookie_set($set::cookie,$id,$key,'+365d');	
}


1;