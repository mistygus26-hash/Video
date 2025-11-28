# 🔧 Troubleshooting Guide - Instagram Video Editor Workflow

## Table des matières
- [Erreur: Binary file 'data' not found (Save Audio)](#erreur-binary-file-data-not-found-save-audio)
- [Erreur: Invalid file_id (Telegram Audio)](#erreur-invalid-file_id-telegram-audio)
- [Erreur: Node Cloudinary manquant](#erreur-node-cloudinary-manquant)
- [Erreur: Merge node conflictuel](#erreur-merge-node-conflictuel)
- [Erreur: FFmpeg échoue](#erreur-ffmpeg-échoue)

---

## Erreur: Binary file 'data' not found (Save Audio)

### Symptôme
```json
{
  "errorMessage": "This operation expects the node's input data to contain a binary file 'data', but none was found [item 0]"
}
```
Dans le node "Save Telegram Audio"

### Cause
Lorsque le node `Download Telegram Audio` a l'option `onError: "continueRegularOutput"` activée, il continue l'exécution même en cas d'erreur (file_id invalide, fichier expiré, etc.) mais **sans données binaires**. Le node suivant `Save Telegram Audio` tente alors d'écrire un fichier binaire qui n'existe pas.

### Solution appliquée (v6) - CORRECTIF DÉFINITIF

**Problème racine identifié** : Le node Telegram natif "Get File" avec `onError: continueRegularOutput` ne retourne parfois pas les données binaires correctement. C'est un [problème connu](https://community.n8n.io/t/the-telegram-get-file-module-does-not-return-a-binary-file/88013) dans n8n.

**Solution v6** : Remplacer le node Telegram par une approche **HTTP Request en 2 étapes** qui télécharge le fichier directement depuis l'API Telegram.

#### Nouveau flux de téléchargement audio

```
Has Telegram Audio? (true)
    │
    ▼
Get Audio File Path (HTTP Request)
    │ URL: https://api.telegram.org/bot{TOKEN}/getFile?file_id={audio_file_id}
    │ Retourne: { ok: true, result: { file_path: "..." } }
    │
    ▼
File Path OK? (IF: $json.ok === true)
    │
    ├── true ──▶ Download Audio Binary (HTTP Request)
    │            │ URL: https://api.telegram.org/file/bot{TOKEN}/{file_path}
    │            │ Response Format: File (binary)
    │            │
    │            ▼
    │            Save Telegram Audio ──▶ Normalize
    │
    └── false ──▶ Normalize Telegram Data (skip audio)
```

#### Configuration des nodes

1. **Get Audio File Path** (HTTP Request) :
```json
{
  "url": "https://api.telegram.org/bot{{ $env.TELEGRAM_BOT_TOKEN }}/getFile?file_id={{ $('Parse Telegram Video').first().json.audio_file_id }}",
  "onError": "continueRegularOutput"
}
```

2. **File Path OK?** (IF) :
```json
{
  "conditions": [{ "leftValue": "={{ $json.ok }}", "rightValue": true }]
}
```

3. **Download Audio Binary** (HTTP Request) :
```json
{
  "url": "https://api.telegram.org/file/bot{{ $env.TELEGRAM_BOT_TOKEN }}/{{ $json.result.file_path }}",
  "options": {
    "response": { "response": { "responseFormat": "file" } }
  }
}
```

### Pourquoi cette solution fonctionne

1. **Séparation des étapes** : L'API Telegram nécessite 2 appels séparés (getFile pour le path, puis download)
2. **HTTP Request avec `responseFormat: file`** : Garantit que les données binaires sont correctement capturées
3. **Pas de dépendance au node Telegram natif** : Évite les bugs connus du node Telegram Get File

### Prérequis

**Variable d'environnement requise** :
```env
TELEGRAM_BOT_TOKEN=your_bot_token_here
```

### Références
- [n8n Docs - Telegram File Operations](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.telegram/file-operations/)
- [n8n Community - Telegram Get File does not return binary](https://community.n8n.io/t/the-telegram-get-file-module-does-not-return-a-binary-file/88013)
- [n8n Community - Download video from Telegram](https://community.n8n.io/t/download-a-video-sent-in-a-telegram-chat/49923)
- [Telegram Bot API - getFile](https://core.telegram.org/bots/api#getfile)

---

## Erreur: Invalid file_id (Telegram Audio)

### Symptôme
```json
{
  "errorMessage": "Bad request - please check your parameters",
  "errorDescription": "Bad Request: invalid file_id",
  "httpCode": "400"
}
```

### Cause
Cette erreur survient dans le node "Download Telegram Audio" pour plusieurs raisons :

1. **Aucun audio joint** : Le message Telegram ne contenait pas de fichier audio
2. **file_id expiré** : Les file_id Telegram expirent après un certain temps
3. **Mauvais compte Telegram** : Le credential Telegram utilisé n'est pas le même que celui du trigger
4. **Format non supporté** : Le fichier n'est pas reconnu comme audio (doit être `audio/*` ou `voice`)

### Solution appliquée (v3)

1. **Validation stricte dans Parse Telegram Video** :
```javascript
// Récupérer file_id audio - VALIDATION STRICTE
let audioFileId = null;
let hasValidAudio = false;

if (msg.audio && msg.audio.file_id) {
  audioFileId = msg.audio.file_id;
  hasValidAudio = true;
} else if (msg.voice && msg.voice.file_id) {
  audioFileId = msg.voice.file_id;
  hasValidAudio = true;
} else if (msg.document && msg.document.mime_type &&
           msg.document.mime_type.startsWith('audio/') && msg.document.file_id) {
  audioFileId = msg.document.file_id;
  hasValidAudio = true;
}
```

2. **Double condition dans Has Telegram Audio?** :
   - `has_audio === true` ET
   - `audio_file_id !== ""` (non vide)

3. **Gestion d'erreur** : `onError: "continueRegularOutput"` sur le node Download

4. **Branche false** du IF redirige directement vers "Normalize Telegram Data"

### Références
- [n8n Community - Invalid file_id Error](https://community.n8n.io/t/telegram-node-get-a-file-fails-with-invalid-file-id-error-for-voice-messages/186796)

---

## Erreur: Node Cloudinary manquant

### Symptôme
```
Cannot read property 'secure_url' of undefined
```
Dans le node "1. Initialize Instagram Upload"

### Cause
Le workflow original référençait un node `Upload to Cloudinary` qui n'existait pas.

### Solution
Ajout du node avec configuration :
```json
{
  "name": "Upload to Cloudinary",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.cloudinary.com/v1_1/dxpj6gxjh/video/upload",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpBasicAuth",
    "contentType": "multipart-form-data",
    "bodyParameters": {
      "parameters": [
        {"name": "file", "parameterType": "formBinaryData", "inputDataFieldName": "data"},
        {"name": "upload_preset", "value": "ml_default"},
        {"name": "resource_type", "value": "video"}
      ]
    }
  },
  "credentials": {
    "httpBasicAuth": {"id": "j7EB5n6xLUKbgDAx", "name": "Cloudinary API"}
  }
}
```

---

## Erreur: Merge node conflictuel

### Symptôme
Les données des flux Webhook et Telegram s'écrasent mutuellement.

### Cause
Le Merge node original recevait des données sur le même index depuis plusieurs sources.

### Solution
1. Restructuration avec `mode: "chooseBranch"` et `output: "empty"`
2. Normalisation des données avant le Merge :
   - Flux Webhook → `Finalize Webhook Data` → Merge index 0
   - Flux Telegram → `Normalize Telegram Data` → Merge index 1

---

## Erreur: FFmpeg échoue

### Symptôme
```
SUCCESS: Video ready at... (absent du stdout)
```

### Causes possibles
1. FFmpeg non installé sur le serveur n8n
2. Fichiers vidéo source corrompus ou inexistants
3. Permissions insuffisantes sur `/tmp/n8n/`
4. Format vidéo non supporté

### Solution
Le script FFmpeg inclut maintenant :
- `set -e` pour arrêter en cas d'erreur
- Redirection stderr vers stdout (`2>&1`)
- Echo "SUCCESS" en fin de script pour validation
- Vérification conditionnelle des fichiers (`[ -f "$MUSIC_FILE" ]`)

### Vérification manuelle
```bash
# Sur le serveur n8n
ffmpeg -version
ls -la /tmp/n8n/
```

---

## Configuration requise

### Variables d'environnement n8n
```env
CLOUDINARY_CLOUD_NAME=dxpj6gxjh
CLOUDINARY_UPLOAD_PRESET=ml_default
TELEGRAM_CHAT_ID=8263106324
TELEGRAM_BOT_TOKEN=your_bot_token_here  # REQUIS pour v6!
INSTAGRAM_USER_ID=17841478707012581
```

### Credentials requis
| Nom | Type | ID |
|-----|------|-----|
| Telegram account | telegramApi | K9X5ZxT7qeNTjT7i |
| Facebook Graph account | facebookGraphApi | wH3cFtLfrvMdfMoB |
| Cloudinary API | httpBasicAuth | j7EB5n6xLUKbgDAx |

---

## Changelog des corrections

### v6 (2025-11-28) - SOLUTION DÉFINITIVE
- ✅ **Fix DÉFINITIF**: Remplacement du node Telegram "Get File" par HTTP Request en 2 étapes
- ✅ Nouveau node "Get Audio File Path" : appelle `getFile` API pour obtenir le `file_path`
- ✅ Nouveau node "File Path OK?" : vérifie que l'API a retourné `ok: true`
- ✅ Nouveau node "Download Audio Binary" : télécharge le fichier avec `responseFormat: file`
- ✅ Contourne le bug du node Telegram natif qui ne retourne pas les binary data
- ⚠️ **Prérequis** : Variable d'environnement `TELEGRAM_BOT_TOKEN` requise

### v5 (2025-11-28)
- ❌ Tentative: Node Code "Check & Pass Binary" avec `binary: item.binary`
- ❌ Ne fonctionnait pas car le node Telegram en amont ne retournait jamais de binary

### v4 (2025-11-28)
- ❌ Tentative: Node "Has Binary Data?" IF - ne fonctionnait pas car IF ne transmet pas binary
- ✅ Amélioration: Normalize Telegram Data vérifie si l'audio a été sauvegardé via try/catch

### v3 (2025-11-27)
- ✅ Fix: Invalid file_id pour audio Telegram
- ✅ Ajout: Double validation audio (has_audio + file_id non vide)
- ✅ Ajout: Support des messages vocaux (msg.voice)
- ✅ Amélioration: Branche false du IF audio connectée à Normalize

### v2 (2025-11-27)
- ✅ Ajout: Node Upload to Cloudinary
- ✅ Fix: Credential Cloudinary configuré

### v1 (2025-11-27)
- ✅ Fix: Merge node restructuré
- ✅ Fix: Toutes les références de nodes corrigées
- ✅ Ajout: Gestion d'erreurs (FFmpeg, Rejected, Error Response)
- ✅ Ajout: Normalisation des données (Webhook/Telegram unifié)
