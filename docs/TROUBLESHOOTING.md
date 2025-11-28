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

### Solution appliquée (v7) - CORRECTIF DÉFINITIF avec CURL

**Problème racine** : Tous les nodes n8n (Telegram, HTTP Request, Read/Write File) ont des problèmes de transmission des données binaires entre eux. Après 6 versions de tentatives, aucune combinaison de nodes n8n ne fonctionne de manière fiable.

**Solution v7** : Utiliser **Execute Command avec curl** pour télécharger le fichier directement sur le disque, contournant complètement les problèmes de binary data des nodes n8n.

#### Nouveau flux de téléchargement audio

```
Has Telegram Audio? (true)
    │
    ▼
Download Audio with Curl (Execute Command)
    │ Script bash qui :
    │ 1. Appelle getFile API pour obtenir file_path
    │ 2. Télécharge le fichier avec curl -o
    │ 3. Vérifie que le fichier existe
    │
    ▼
Audio Download OK? (IF: stdout contains "SUCCESS")
    │
    ├── true/false ──▶ Normalize Telegram Data
```

#### Script bash du node "Download Audio with Curl"

```bash
#!/bin/bash
set -e
BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
FILE_ID="{{ $('Parse Telegram Video').first().json.audio_file_id }}"
OUTPUT_FILE="{{ $('Parse Telegram Video').first().json.temp_dir }}/music.mp3"

# Étape 1: Obtenir le file_path via getFile API
FILE_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getFile?file_id=${FILE_ID}")
FILE_PATH=$(echo "$FILE_INFO" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4)

if [ -z "$FILE_PATH" ]; then
  echo "ERROR: Could not get file_path from Telegram API"
  echo "Response: $FILE_INFO"
  exit 1
fi

# Étape 2: Télécharger le fichier
curl -s -o "$OUTPUT_FILE" "https://api.telegram.org/file/bot${BOT_TOKEN}/${FILE_PATH}"

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "SUCCESS: Audio downloaded to $OUTPUT_FILE"
else
  echo "ERROR: Failed to download audio file"
  exit 1
fi
```

### Pourquoi cette solution fonctionne

1. **Pas de binary data dans n8n** : curl écrit directement sur le disque, pas besoin de passer par les nodes n8n
2. **Tout en une seule commande** : getFile + download dans le même script
3. **Vérification intégrée** : Le script vérifie que le fichier existe et n'est pas vide
4. **Compatible avec les credentials existants** : Utilise `$TELEGRAM_BOT_TOKEN` comme variable d'environnement

### Prérequis

**Variable d'environnement requise dans n8n** :
```env
TELEGRAM_BOT_TOKEN=your_bot_token_here
```

### Références
- [Telegram Bot API - getFile](https://core.telegram.org/bots/api#getfile)
- [n8n Execute Command Node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.executecommand/)

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

### v7 (2025-11-28) - SOLUTION DÉFINITIVE avec CURL
- ✅ **Fix DÉFINITIF** : Utilisation de `curl` via Execute Command au lieu des nodes n8n
- ✅ Nouveau node "Download Audio with Curl" : script bash qui fait tout (getFile + download)
- ✅ Écriture directe sur disque : contourne tous les problèmes de binary data
- ✅ Vérification intégrée : le script vérifie que le fichier existe et n'est pas vide
- ⚠️ **Prérequis** : Variable d'environnement `TELEGRAM_BOT_TOKEN` requise

### v6 (2025-11-28)
- ❌ Tentative: HTTP Request en 2 étapes (getFile + download avec responseFormat: file)
- ❌ Ne fonctionnait pas : les binary data se perdaient toujours entre HTTP Request et Read/Write File

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
