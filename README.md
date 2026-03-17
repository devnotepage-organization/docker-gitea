# Docker環境にGiteaを構築する手順

## Docker構成
```java
Internet
  ↓ HTTPS
Nginx (443)
  ↓ http
Gitea (3000)
  ↓
PostgreSQL
```

## 全体構成
- Gitea：アプリ本体
- PostgreSQL：DB
- Nginx：HTTPS終端（Let’s Encrypt）
- データ永続化：volume

## Let’s Encrypt（証明書）
一番ラクなのは certbotコンテナ方式：
```bash
docker run --rm -it \
  -v $(pwd)/nginx/cert:/etc/letsencrypt \
  -v $(pwd)/nginx/conf.d:/etc/nginx/conf.d \
  -p 80:80 \
  certbot/certbot certonly --standalone -d git.example.com
```

## 起動
```bash
docker compose up -d
```

## アクセス
```yaml
https://git.example.com
```
→ 初回セットアップ画面が出る
→ DB設定は自動反映済み

## SSH運用（本番）
Giteaに22番ポートを割り当てる例：
```yaml
ports:
  - "2222:22"
```

clone:
```bash
git clone ssh://git@git.example.com:2222/user/repo.git
```

## 1. VPS準備（必須）
1. VPS取得（例：さくらのVPS、ConoHa、AWS Lightsail、DigitalOcean など）
1. SSH接続確認
1. OS更新
    - `sudo apt update && sudo apt upgrade -y` など
1. Docker / docker compose インストール
    - `sudo apt install docker.io docker-compose -y`（Ubuntu系）

## 2. リポジトリ配置と起動
- `/home/xxx/docker-gitea` にプロジェクト配置
- `docker-compose.yml` はそのまま使える
- 現状の `gitea` サービスは `expose: 3000`（内部接続）
- `nginx` が `80/443` を公開している

### 実行:
- `docker compose up -d`

### 確認:
- `docker compose ps`
- `docker compose logs -f nginx` 等

## 3. ドメイン + DNS 設定
- `git.example.com` という名前は `gitea` 環境変数に埋め込み済み
    - `GITEA__server__ROOT_URL=https://git.example.com/`
    - `GITEA__server__DOMAIN=git.example.com`
- DNS で `A` レコードを VPS のグローバルIPに向ける

## 4. Nginx リバースプロキシ + SSL（Let’s Encrypt）
nginx.conf 例（ `gitea.conf` ）
修正例（未含め）の場合、こんな感じ：

- 80リダイレクト -> 443
- 443は`proxy_pass http://gitea:3000`

```
server {
    listen 80;
    server_name git.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name git.example.com;

    ssl_certificate /etc/letsencrypt/live/git.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/git.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://gitea:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Certbotで証明書発行（ホスト側）
- `sudo apt install certbot`
- `sudo certbot certonly --nginx -d git.example.com` など
- `nginx` を再読み込み: `docker exec <nginxコンテナ> nginx -s reload`

### Certbot自動更新:

- `sudo certbot renew --dry-run`
- `cron / systemd timer` で毎日実行

## 5. ファイアウォール設定
- ufw 例:
    - `sudo ufw allow OpenSSH`
    - `sudo ufw allow 80/tcp`
    - `sudo ufw allow 443/tcp`
    - `sudo ufw enable`

## 6. Gitea設定確認（Web UI）
- `https://git.example.com` でアクセス
- 管理者アカウント作成
- `Site URL`, `SSH/HTTP` などが正しく設定されていること確認

## 7. (追加) 検討すべき運用
- バックアップ
    - DB の `pg_dump`
    - `data` ボリューム
- 監視・ログ
    - `docker compose logs --tail 100 -f gitea nginx`
- セキュリティ
    - Gitea のアップデート
    - PostgreSQLのパスワード

## 今すぐ do すべきコマンド
1. `docker compose up -d`
1. `docker compose logs -f nginx gitea`
1. DNS設定完了後:
    - `sudo certbot certonly --nginx -d git.example.com`
    - `docker exec <nginx> nginx -s reload`
1. `curl -I https://git.example.com`

## 本番で必ずやること
- 管理者ユーザー作成
- 登録制限
- バックアップ設定
- firewalld/ufw
- 自動更新（watchtower or 手動）
- ログローテーション

## 次の一歩
- 外部公開
- VPS

## 質問
- ドメインある
- SSHも使う
- 100人くらい
