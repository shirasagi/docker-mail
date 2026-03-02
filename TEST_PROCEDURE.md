# メールサーバー動作確認手順 (AlmaLinux 8)

このドキュメントでは、構築した AlmaLinux 8 ベースのメールサーバーコンテナの動作確認手順を記録します。

## 1. コンテナの起動
以下のコマンドでコンテナを起動します。

```bash
docker run -d --name mailserver -p 587:587 -p 143:143 docker-mail-almalinux
```

## 2. メールの送信テスト (SMTP / Postfix)
コンテナ内の `sendmail` コマンドを使用して、仮想メールボックスへの配送をテストします。

```bash
docker exec mailserver /usr/sbin/sendmail -f user1@example.jp user1@example.jp <<EOF
Subject: Test Mail
From: user1@example.jp
To: user1@example.jp

This is a test message.
EOF
```

### 配送結果の確認
コンテナ内のディレクトリ構造を確認します。
```bash
docker exec mailserver ls -R /var/spool/virtual/example.jp/user1/Maildir/new
```

## 3. メールの受信確認 (IMAP / Dovecot)
ホストマシンから `nc` (Netcat) を使用して、IMAP ポート (143) 経由でログインとメールの存在を確認します。

- **ユーザー**: `user1@example.jp`
- **パスワード**: `pass`

```bash
printf "a1 LOGIN user1@example.jp pass
a2 SELECT INBOX
a3 FETCH 1 BODY[TEXT]
a4 LOGOUT
" | nc localhost 143
```

### 期待される応答
- `a1 OK ... Logged in`
- `* 1 EXISTS` (メールが1通存在することを示す)
- `a2 OK [READ-WRITE] Select completed`
