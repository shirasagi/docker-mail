# パッチ変更点分析ドキュメント

このドキュメントは、CentOS 7 ベースのメールサーバー構築に使用されている各パッチファイルの変更箇所をまとめたものです。AlmaLinux への移行時に、これらの設定をどのように適用すべきかのガイドラインとして使用します。

## 1. Postfix 設定 (assets/postfix/)

### main.cf.patch
Postfix のメイン設定ファイルに対する変更です。
- **ホスト名・ドメイン**: `myhostname = ss001.example.jp`, `mydomain = example.jp` を設定。
- **送信元**: `myorigin = $mydomain` に設定。
- **ネットワークインターフェース**: `inet_interfaces = all` に変更（外部からの接続を許可）。
- **ネットワークスタイル**: `mynetworks_style = subnet` に設定。
- **メールボックス形式**: `home_mailbox = Maildir/` を有効化。
- **ヘッダーチェック**: `header_checks = regexp:/etc/postfix/header_checks` を有効化。
- **仮想メールボックス設定**:
    - `virtual_mailbox_domains = example.jp`
    - `virtual_mailbox_base = /var/spool/virtual`
    - `virtual_mailbox_maps = hash:/etc/postfix/vmailbox`
    - `virtual_uid_maps = static:10000` (mailuser)
    - `virtual_gid_maps = static:10000` (mailuser)
- **SASL認証 (Dovecot連携)**:
    - `smtpd_sasl_auth_enable = yes`
    - `smtpd_sasl_type = dovecot`
    - `smtpd_sasl_path = private/auth`
- **制限設定**: 
    - クライアント制限: `permit_mynetworks, reject_unknown_client, permit`
    - 受信制限: `permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination`

### master.cf.patch
- **Submissionポート (587)**: `submission` サービスを有効化。

### header_checks.patch
- **配送ルール**: 
    - `@example.jp` 宛のメールは許可 (`OK`)。
    - それ以外の全てのメールは `sys@example.jp` へ転送 (`REDIRECT`)。

---

## 2. Dovecot 設定 (assets/dovecot/)

### 10-auth.conf.patch
- **認証セキュリティ**: `disable_plaintext_auth = no`（プレーンテキスト認証を許可）。
- **デフォルト領域**: `auth_default_realm = example.jp`。
- **認証メカニズム**: `plain` に加え `cram-md5` を追加。
- **データベース選択**: `auth-system.conf.ext` (OSユーザー) を無効化し、`auth-passwdfile.conf.ext` を有効化。

### 10-mail.conf.patch
- **メール保存先**: `mail_location = maildir:/var/spool/virtual/%d/%n/Maildir`。
- **プラグイン**: `quota` プラグインをグローバルで有効化。

### 10-master.conf.patch
- **Postfix SASL認証用ソケット**: `/var/spool/postfix/private/auth` を作成。所有者を `postfix` ユーザー/グループに設定し、モード `0666` で開放。

### 10-ssl.conf.patch
- **SSL無効化**: `ssl = no` に設定。

### 20-imap.conf.patch
- **IMAPプラグイン**: `imap_quota` を追加。
- **接続数制限**: 同一IPからの最大接続数を `10` から `100` に緩和。

### 90-quota.conf.patch
- **クォータ制限**: 
    - デフォルト: `10M`
    - ゴミ箱(Trash): `+1M`
- **クォータ方式**: `maildir` 方式を有効化。

### auth-passwdfile.conf.ext.patch
- **デフォルトフィールド**: 仮想ユーザーの `uid`, `gid` を `mailuser` (10000) に固定し、ホームディレクトリを `/var/spool/virtual/%d/%n` に設定。
