# 🔧 Troubleshooting Guide - Instagram Video Editor Workflow

## Table des matières
- [Erreur: Invalid file_id (Telegram Audio)](#erreur-invalid-file_id-telegram-audio)
- [Erreur: Node Cloudinary manquant](#erreur-node-cloudinary-manquant)
- [Erreur: Merge node conflictuel](#erreur-merge-node-conflictuel)
- [Erreur: FFmpeg échoue](#erreur-ffmpeg-échoue)

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
