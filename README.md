# docker-gitea

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

## 質問：
- ドメインある
- VPS
- SSHも使う
- 100人くらい
