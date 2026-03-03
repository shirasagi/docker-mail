# メールサーバー動作確認手順 (AlmaLinux 8)

このドキュメントでは、AlmaLinux 8 ベースのメールサーバーコンテナの動作確認手順を説明します。
ホストマシンから SMTP (Postfix) および IMAP (Dovecot) の動作を検証します。

## 1. コンテナのビルドと起動

まず、最新のイメージをビルドしてコンテナを起動します。

```bash
# ビルド
docker build -t shirasagi/mail .

# 起動 (ホストの 10587, 10143 ポートを使用)
docker run --name mail -d -p 10143:143 -p 10587:587 shirasagi/mail
```

## 2. SMTP 送信テスト (Postfix)

ホストマシンから `swaks` を使用して、コンテナ内の Postfix にメールを送信します。

- **送信元/宛先**: `user1@example.jp`
- **サーバー**: `localhost:10587`
- **認証**: パスワード `pass` (PLAIN 認証)

```bash
swaks --to user1@example.jp --from user1@example.jp \
      --server localhost --port 10587 \
      --auth PLAIN --auth-user user1@example.jp --auth-password pass \
      --body "This is a test mail from swaks." \
      --header "Subject: Test Mail from Swaks"
```

### ログによる配送確認
コンテナのログを表示して、Postfix がメールを受理し、正常に Maildir へ配信したことを確認します。

```bash
docker logs mail
```

**期待されるログ出力例:**
```text
postfix/smtpd[...]: connect from unknown[...]
postfix/smtpd[...]: ...: client=unknown[...]
postfix/virtual[...]: ...: to=<user1@example.jp>, relay=virtual, ..., status=sent (delivered to maildir)
```

## 3. メールの受信確認 (Dovecot / IMAP)

### ディレクトリの直接確認
Maildir 内に新しいメールファイルが作成されているか確認します。

```bash
docker exec mail ls -R /var/spool/virtual/example.jp/user1/Maildir/new/
```

### IMAP 経由での確認
ホストマシンから `curl` または `nc` を使用して IMAP 接続をテストします。

**curl を使用する場合:**
```bash
curl -u user1@example.jp:pass imap://localhost:10143/INBOX
```

**nc (Netcat) を使用する場合:**
```bash
printf "A1 LOGIN user1@example.jp pass\nA2 SELECT INBOX\nA3 LOGOUT\n" | nc localhost 10143
```

**期待される応答:**
- `* 1 EXISTS` (メールが届いている場合、通数が表示されます)
- `A1 OK ... Logged in`

## 4. クォータの確認 (任意)

Dovecot のクォータ機能が動作しているか確認します。

```bash
docker exec mail doveadm quota get -u user1@example.jp
```
