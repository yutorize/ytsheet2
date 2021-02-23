# Docker for ytsheet2

ゆとシート2が動作する環境をローカルに構築するのは大変なので、   
ローカルにゆとシート2を楽に構築する手段を使って開発に集中しましょう。

## 使い方

### 初回起動

このディレクトリで以下のコマンドを実行してください。
色々インストールするので結構時間がかかります。

```bash
$ docker-compose up -d --build
```

終わったら http://localhost:8080/cgi-bin/sw2.5/ or http://localhost:8080/cgi-bin/dx3/ にアクセスしてください。

### 停止

停止させるには以下のコマンドを打ってください。

```bash
$ docker-compose down
```

### 再度起動

再度起動するには以下のコマンドを打ってください。

```bash
$ docker-compose up -d
```

割とすぐ起動します。以下にアクセスして動作を確認しましょう。   
http://localhost:8080/cgi-bin/sw2.5/ or http://localhost:8080/cgi-bin/dx3/

### 開発する

ローカルで直接ゆとシート2のコードを変更すればすぐに反映されます。

## 参考にしたもの

https://github.com/NakanishiTetsuhiro/docker-for-perlcgi の内容をゆとシート向け2に改変して作成しています。

## Q&A

### どうやって docker を導入すればいいの?

#### Windows

https://docs.docker.com/docker-for-windows/install/

#### Mac

https://docs.docker.com/docker-for-mac/install/

### これを使うと何が楽なの?

ローカルにサーバをコマンドを打つだけで作れます。
apache や nginx を設定し、CGI の初期設定を行う必要もありません。
書いた perl や JavaScript のソースコードをローカルで確認できます。
