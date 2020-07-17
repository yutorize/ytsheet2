# 外部サービスからログインする設定

エンドユーザが外部のサービスを利用してゆとシートにログイン・利用することを可能にする設定が可能です。
現時点では外部のサービスとして Google および Discord を利用することが可能です。

外部サービスを利用してのログインを利用するとエンドユーザはゆとシートにログインするための ID・パスワードを管理する必要がなくなります。
ただし、この機能を使う場合、通常の方法でのアカウント作成・ログインはできません。
そのため、利用する外部サービスのアカウントを持っていないエンドユーザはゆとシートにログインすることができなくなります。

## 基本的な設定手順

`config.cgi` を編集し、末尾に以下の6つの変数を追加することで設定が可能です。

```perl
  our $oauth_service = "利用する外部サービスの名称";
  our $oauth_login_url = "利用する外部サービスの確認画面の URL";
  our $oauth_client_id = "利用する外部サービスから払い出される Client ID";
  our $oauth_secret_id = "利用する外部サービスから払い出される Secret ID";
  our $oauth_redirect_url = "ゆとシートの oauth.cgi の URL";
  our $oauth_scope = "利用するサービスのどの情報へのアクセスを許可するか";
```

どの外部サービスを利用するとしても原則として Client ID 等を払い出した上でそれを config.cgi に記載する、という手順を踏みます。

また、どの外部サービスを利用するとしても `$oauth_redirect_url` の値は変わりません。
ゆとシートの URL が `http://my-ytsheet-sample.example.com/ytsheet2/sw2.5/` なのであれば
末尾に `oauth.cgi` を付け、`http://my-ytsheet-sample.example.com/ytsheet2_sw2.5/sw2.5/oauth.cgi` としてください。


## Google でログインする場合の設定手順

### Client ID 等の払い出し

Google APIs の OAuch 2.0 クライアント ID を作成・取得します。

[Google Developers Console](https://console.developers.google.com/) にアクセスし、
プロジェクトを新規作成します。

#### OAuth 同意画面の作成

新規作成できたら「OAuth 同意画面」を編集し、いくつかの設定を行います。以下のように設定すると良いでしょう。

* アプリケーション名は設置するゆとシート2につける名前を記載してください
* Google API のスコープには email と profile を最低限設定してください
* 承認済みドメインにはゆとシートを設置したサーバのドメイン名を設定してください。例えば `my-ytsheet.sakura.ne.jp` 等になるでしょう
* アプリケーションホームページリンクには設置したゆとシートの URL を設定してください
* アプリケーションプライバシーポリシーリンクにはあなたのサイトの利用規約へのリンクを設定してください。なければアプリケーションホームページリンクと同じ値を入力しておきましょう
* アプリケーション利用規約にもアプリケーションプライバシーポリシーリンクと同じ値を入力しておきましょう

「OAuth 同意画面」の設定が終わったら「認証情報」から OAuth2.0 クライアント ID を作成します。

#### OAuth クライアント ID の作成

「認証情報」の画面を開き、画面上部の「認証情報を作成」から「OAuth クライアント ID」を選択します。
アプリケーションの種類を問われるので「ウェブアプリケーション」を選択してください。さらに以下のように情報を入力します。

* 名前には先の OAuth 同意画面で設定したアプリケーション名と同じものを入れてください
* 承認済みの JavaScript 生成元にはゆとシートの URL のドメイン部分までを入れてください。例えば `http://my-ytsheet-sample.example.com` です
* 承認済みのリダイレクト URI にはゆとシートの URL の末尾に `oauth.cgi` を追加したものを入れてください。例えば `http://my-ytsheet-sample.example.com/ytsheet2_sw2.5/oauth.cgi` です

これらを入力し「作成」をクリックすると「クライアント ID」と「クライアントシークレット」が表示されますので、これを控えてください。

### 確認画面 URL の生成

[確認画面 URL の生成ツール](http://shunshun94.web.fc2.com/util/OAuthUrl.html)等を使ってログイン用の URL を生成してください。

この際、スコープは `https://www.googleapis.com/auth/userinfo.profile+email` としてください。

### config.cgi の設定

以下のように `config.cgi` に追記してください。

```perl
  our $oauth_service = "Google";
  our $oauth_login_url = "前のステップで生成した確認画面の URL";
  our $oauth_client_id = "OAuth クライアント ID 取得のステップで入手したクライアント ID";
  our $oauth_secret_id = "OAuth クライアント ID 取得のステップで入手したクライアントシークレット";
  our $oauth_redirect_url = "ゆとシートの oauth.cgi の URL";
  our $oauth_scope = "https://www.googleapis.com/auth/userinfo.profile+email";
```

この config.cgi をゆとシートに配置することで Google でのログインが可能となります。

## Discord でログインする場合の設定手順

### Client ID 等の払い出し

[Discord Developer Portal](https://discord.com/developers/applications) の「New Application」からアプリケーションを新規作成してください。

新規作成後、画面右側のメニュー、「General Information」からCLIENT ID および CLIENT SECRET が取得できます。
これを取得し、控えておきます。

### リダイレクト先を設定する

次に画面左側のメニューより「OAuth2」を選択してください。これによって開く画面上で OAuth2 の設定をしていきます。
「Redirects」にゆとシートの URL の末尾に `oauth.cgi` を追加したものを入れてください。例えば `http://my-ytsheet-sample.example.com/ytsheet2/sw2.5/oauth.cgi` です。

追加したら画面下部の「Save Changes」を押して保存してください。

### 確認画面 URL の作成

続けて「OAuth2」から確認画面の URL を生成できます。画面下の方、「OAuth2 URL Generator」から以下を設定し、画面下部の「Copy」をクリックすることで確認画面 URL を取得できます。

* SELECT REDIRECT URL は前のステップで設定したリダイレクト先を選択してください
* SCOPES は「identify」「email」「guilds」を選択してください

確認画面の URL を取得したら控えておいてください。

### config.cgi の設定

以下のように `config.cgi` に追記してください。

```perl
  our $oauth_service = "Discord";
  our $oauth_login_url = "前のステップで生成した確認画面の URL";
  our $oauth_client_id = "General Information で取得した CLIENT ID";
  our $oauth_secret_id = "General Information で取得した CLIENT SECRET";
  our $oauth_redirect_url = "ゆとシートの oauth.cgi の URL";
  our $oauth_scope = "identify+guilds+email";
```

この config.cgi をゆとシートに配置することで Discord でのログインが可能となります。

## Discord の特定サーバに加入している人のみ利用可能にする 

自分のコミュニティの人のみに利用させるために、 Discord の特定サーバに加入していなければゆとシートにデータを追加できないようにすることができます。

Discord でログインするように設定した上でさらに `config.cgi` に次のように追記してください。

```perl
  our $user_reqd = 1;
  our @oauth_discord_login_servers = ("サーバーのID");
```

`$user_reqd` を1にすることでログインしていなければデータの編集・追加ができないようになります。

`@oauth_discord_login_servers` にサーバのIDを挿入することで、そのサーバに所属しているメンバーのみにログインを許可することができます。
さらに、以下のようにカンマで区切ることで複数のサーバのいずれかのメンバーならログインを許可する、というように設定することができます。

```perl
  our $user_reqd = 1;
  our @oauth_discord_login_servers = ("463088353794064384", "302452071993442307");
```

