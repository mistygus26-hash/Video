# 📖 Instagram Video Editor & Publisher - Guide d'installation

## 🎯 Workflow Fusionné Production-Ready

Ce workflow combine :
- ✅ **Workflow #3328** (n8n.io) - FFmpeg natif pour montage vidéo
- ✅ **Workflow #5457** (n8n.io) - Instagram Graph API pour publication
- ✅ Architecture modulaire et testée en production

---

## 📋 Prérequis

### 1. Infrastructure
- ✅ VPS Debian/Ubuntu avec n8n self-hosted
- ✅ FFmpeg installé (`apt install ffmpeg`)
- ✅ Node.js 18+ 
- ✅ Min 2GB RAM, 20GB disk

### 2. Comptes & API
- ✅ Facebook Business Manager
- ✅ Instagram Business Account
- ✅ Telegram Bot (pour approbation manuelle)
- ✅ Domaine avec HTTPS (pour webhooks)

---

## 🚀 Installation Rapide

### Étape 1 : Importer le workflow dans n8n

```bash
# Télécharger le workflow depuis GitHub
curl -O https://raw.githubusercontent.com/mistygus26-hash/Video/main/workflows/instagram-production/workflow-instagram-ffmpeg-fusion.json

# Ou cloner le repo complet
git clone https://github.com/mistygus26-hash/Video.git
cd Video/workflows/instagram-production/
```

**Dans n8n UI** :
1. Cliquer sur `...` (menu) → `Import from File`
2. Sélectionner `workflow-instagram-ffmpeg-fusion.json`
3. Le workflow apparaît dans votre canvas

---

### Étape 2 : Configurer les credentials

#### A) Facebook Graph API

1. **Créer une App Facebook** :
   - Aller sur https://developers.facebook.com/apps
   - `Create App` → Type : `Business` → Nom : "n8n Instagram Automation"

2. **Ajouter Instagram Basic Display** :
   - Dashboard → `Add Product` → `Instagram Graph API`
   - Permissions requises : `instagram_basic`, `instagram_content_publish`, `pages_read_engagement`

3. **Générer Access Token** :
   ```bash
   # Obtenir User Access Token (court terme)
   https://www.facebook.com/v22.0/dialog/oauth?
     client_id={app-id}&
     redirect_uri={redirect-uri}&
     scope=instagram_basic,instagram_content_publish,pages_read_engagement
   
   # Échanger contre Long-Lived Token (60 jours)
   curl -X GET "https://graph.facebook.com/v22.0/oauth/access_token?
     grant_type=fb_exchange_token&
     client_id={app-id}&
     client_secret={app-secret}&
     fb_exchange_token={short-lived-token}"
   ```

4. **Dans n8n** :
   - `Credentials` → `Add` → `Facebook Graph API`
   - Coller le Long-Lived Access Token
   - Sauvegarder sous le nom : `facebook_graph`

#### B) Telegram Bot

1. **Créer un Bot** :
   ```
   1. Ouvrir Telegram → Rechercher @BotFather
   2. Envoyer /newbot
   3. Nom : "n8n Video Approval Bot"
   4. Username : "mon_n8n_video_bot"
   5. Copier le TOKEN reçu
   ```

2. **Obtenir votre Chat ID** :
   ```bash
   # Envoyer un message à votre bot, puis :
   curl https://api.telegram.org/bot{TOKEN}/getUpdates
   # Copier "chat":{"id": 123456789}
   ```

3. **Dans n8n** :
   - `Credentials` → `Add` → `Telegram API`
   - Token : coller le bot token
   - Sauvegarder sous le nom : `telegram_bot`

---

### Étape 3 : Configurer les variables d'environnement

**Dans n8n** (Settings → Variables) ou `.env` :

```bash
# Instagram
INSTAGRAM_USER_ID=17841401234567890  # Votre Instagram Business Account ID
N8N_WEBHOOK_URL=https://votre-domaine.com  # URL publique n8n

# Telegram
TELEGRAM_CHAT_ID=123456789  # Votre Chat ID

# Optionnel - Pour upload direct via webhook
VIDEO_WEBHOOK_PATH=/webhook/video-edit
```

**Trouver votre Instagram User ID** :
```bash
# Méthode 1 : Via Graph API Explorer
https://developers.facebook.com/tools/explorer/
# Query : me/accounts → Sélectionner Page → business_discovery.username({instagram_username})

# Méthode 2 : Via curl
curl -X GET "https://graph.facebook.com/v22.0/me/accounts?access_token={TOKEN}"
# Puis : curl "https://graph.facebook.com/v22.0/{PAGE_ID}?fields=instagram_business_account&access_token={TOKEN}"
```

---

### Étape 4 : Activer le workflow

1. Dans n8n, ouvrir le workflow importé
2. Vérifier que tous les nodes ont leurs credentials configurés :
   - ✅ `Telegram Bot API` → credential `telegram_bot`
   - ✅ `Facebook Graph API` → credential `facebook_graph`
3. Cliquer sur `Activate` (switch en haut à droite)

---

## 🧪 Test du workflow

### Test manuel via webhook

```bash
# Créer un fichier test.json
cat > test.json <<EOF
{
  "video_urls": [
    "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
    "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4"
  ],
  "text": "Test vidéo n8n 🎬",
  "music_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  "caption": "Vidéo automatisée avec n8n + FFmpeg 🚀 #automation #n8n"
}
EOF

# Envoyer au webhook
curl -X POST https://votre-domaine.com/webhook/video-edit \
  -H "Content-Type: application/json" \
  -d @test.json
```

**Vérifications** :
1. ✅ n8n télécharge les vidéos
2. ✅ FFmpeg les assemble
3. ✅ Texte overlay ajouté
4. ✅ Musique mixée
5. ✅ Message Telegram reçu avec preview
6. ✅ Répondre `/approve` dans Telegram
7. ✅ Vidéo publiée sur Instagram

---

## 🛠️ Troubleshooting

### Erreur : "FFmpeg not found"
```bash
# Installer FFmpeg sur VPS
sudo apt update && sudo apt install ffmpeg -y

# Vérifier installation
ffmpeg -version
```

### Erreur : "Instagram upload failed"
```bash
# Vérifier permissions App Facebook
# Aller sur : https://developers.facebook.com/apps/{APP_ID}/instagram-basic-display/
# S'assurer que : instagram_content_publish est ACTIVÉ

# Tester token manuellement
curl -X POST "https://graph.facebook.com/v22.0/{INSTAGRAM_USER_ID}/media?access_token={TOKEN}"
```

### Erreur : "Telegram bot not responding"
```bash
# Tester bot
curl https://api.telegram.org/bot{TOKEN}/getMe

# Vérifier webhook n8n
# Node "Wait for Approval" doit avoir un webhook ID unique
```

### Vidéo trop grande pour Instagram
```bash
# Instagram limite : 100MB, durée max 60 secondes
# Modifier node FFmpeg:
# Augmenter compression : -crf 23 → -crf 28
# Réduire bitrate audio : -b:a 128k → -b:a 96k
```

---

## 📊 Architecture du workflow

```
Webhook → Download Clips → FFmpeg Concat → Add Text → Mix Audio
    ↓
Convert to Instagram Format (9:16, H.265)
    ↓
Telegram Approval (Wait 5min) → [Approve/Reject]
    ↓
Initialize Instagram Upload (Graph API)
    ↓
Publish to Instagram
    ↓
Cleanup Temp Files → Success Notification
```

---

## 🎨 Personnalisation

### Modifier le texte overlay (style, position)
**Node : `FFmpeg: Process Video`**
```bash
# Ligne drawtext :
drawtext=text='$TEXT':fontcolor=white:fontsize=64:box=1:boxcolor=black@0.6:boxborderw=10:x=(w-text_w)/2:y=h-th-80

# Options disponibles :
# fontcolor= → couleur texte (white, red, #FF0000)
# fontsize= → taille (32, 48, 64, 96)
# boxcolor= → couleur fond (black@0.6 = noir 60% opacité)
# x= → position horizontale ((w-text_w)/2 = centré)
# y= → position verticale (h-th-80 = 80px du bas)
```

### Ajouter Facebook en plus d'Instagram
**Dupliquer node `2. Publish to Instagram`** :
```json
{
  "method": "POST",
  "url": "https://graph.facebook.com/v22.0/{PAGE_ID}/videos",
  "queryParameters": {
    "parameters": [
      {
        "name": "description",
        "value": "{{ $('Set Project Variables').first().json.caption }}"
      }
    ]
  }
}
```

---

## 📚 Ressources

- 📖 [Workflow #3328 (FFmpeg source)](https://n8n.io/workflows/3328)
- 📖 [Workflow #5457 (Instagram API source)](https://n8n.io/workflows/5457)
- 📖 [Facebook Graph API Docs](https://developers.facebook.com/docs/instagram-api/)
- 📖 [FFmpeg Documentation](https://ffmpeg.org/documentation.html)

---

## ✅ Checklist finale

- [ ] FFmpeg installé sur VPS
- [ ] Workflow importé dans n8n
- [ ] Credentials Facebook Graph API configurés
- [ ] Credentials Telegram configurés
- [ ] Variables d'environnement définies (INSTAGRAM_USER_ID, TELEGRAM_CHAT_ID)
- [ ] Workflow activé
- [ ] Test webhook réussi
- [ ] Approbation Telegram fonctionne
- [ ] Publication Instagram OK

---

**Workflow créé par fusion des templates n8n.io #3328 (FFmpeg) + #5457 (Instagram Graph API)**
**Auteur** : AurastackAI | **License** : MIT