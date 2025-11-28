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

### Solution appliquée (v5) - CORRECTIF DÉFINITIF

**Problème v4** : Le node IF ne transmet pas les données binaires automatiquement. Un IF node avec `Object.keys($binary).length > 0` évalue correctement la condition mais **ne passe pas les binary data** au node suivant.

**Solution v5** : Ajouter un **node Code intermédiaire** qui vérifie ET transmet explicitement les données binaires.

1. **Nouveau node "Check & Pass Binary"** (Code node) :
```javascript
// Vérifier si les données binaires existent et les transmettre
const items = $input.all();
const results = [];

for (const item of items) {
  const hasBinary = item.binary && Object.keys(item.binary).length > 0;

  if (hasBinary) {
    // Transmettre les données avec binary intact
    results.push({
      json: { ...item.json, has_binary: true },
      binary: item.binary
    });
  } else {
    // Pas de binary - marquer comme skip
    results.push({
      json: { ...item.json, has_binary: false }
    });
  }
}

return results;
```

2. **Node IF simplifié** qui vérifie `has_binary === true`

3. **Nouveau flux de connexions** :
```
Download Telegram Audio → Check & Pass Binary → Has Binary Data?
                                                  ├── true → Save Telegram Audio → Normalize
                                                  └── false → Normalize Telegram Data
```

### Pourquoi cette solution fonctionne

D'après la [communauté n8n](https://community.n8n.io/t/binary-data-not-passing-through/80088), les données binaires doivent être **explicitement retournées** par les nodes Code :

> "Le secret est de retourner `binary: item.binary` dans l'objet résultat"

Sans cela, le node Code (ou IF) ne transmet que les données JSON et les binary sont perdues.

### Références
- [n8n Community - Binary data not passing through](https://community.n8n.io/t/binary-data-not-passing-through/80088)
- [n8n Community - Binary file issue](https://community.n8n.io/t/the-telegram-get-file-module-does-not-return-a-binary-file/88013)
- [n8n Community - Write Binary File Error](https://community.n8n.io/t/write-binary-file-error-no-binary-data-exists-on-item/26492)

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

### v5 (2025-11-28)
- ✅ Fix DÉFINITIF: Binary file 'data' not found (le IF node ne passait pas les binary)
- ✅ Ajout: Node Code "Check & Pass Binary" qui transmet explicitement `binary: item.binary`
- ✅ Restructuration: Download → Check & Pass Binary → IF → Save/Skip

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
