#!/bin/bash

# 🧪 Test Script - Instagram Video Editor Workflow
# Ce script teste le workflow n8n étape par étape

set -e

echo "🚀 Test du workflow Instagram Video Editor & Publisher"
echo "======================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-http://localhost:5678}"
WEBHOOK_PATH="/webhook/video-edit"

# ===== ÉTAPE 1 : Vérification FFmpeg =====
echo "📹 Étape 1/5 : Vérification FFmpeg..."
if command -v ffmpeg &> /dev/null; then
    FFMPEG_VERSION=$(ffmpeg -version | head -n1)
    echo -e "${GREEN}✓${NC} FFmpeg installé : $FFMPEG_VERSION"
else
    echo -e "${RED}✗${NC} FFmpeg non installé"
    echo "   Installer avec : sudo apt install ffmpeg -y"
    exit 1
fi
echo ""

# ===== ÉTAPE 2 : Vérification n8n =====
echo "🔌 Étape 2/5 : Vérification n8n..."
if curl -s -o /dev/null -w "%{http_code}" "${N8N_WEBHOOK_URL}" | grep -q "200\|401"; then
    echo -e "${GREEN}✓${NC} n8n accessible sur ${N8N_WEBHOOK_URL}"
else
    echo -e "${RED}✗${NC} n8n non accessible sur ${N8N_WEBHOOK_URL}"
    echo "   Vérifier que n8n est démarré"
    exit 1
fi
echo ""

# ===== ÉTAPE 3 : Vérification variables d'environnement =====
echo "🔑 Étape 3/5 : Vérification credentials..."
MISSING_VARS=()

if [ -z "$INSTAGRAM_USER_ID" ]; then
    MISSING_VARS+=("INSTAGRAM_USER_ID")
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
    MISSING_VARS+=("TELEGRAM_CHAT_ID")
fi

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Variables d'environnement configurées"
else
    echo -e "${YELLOW}⚠${NC} Variables manquantes : ${MISSING_VARS[*]}"
    echo "   Définir dans n8n Settings → Variables"
fi
echo ""

# ===== ÉTAPE 4 : Test FFmpeg local =====
echo "🎬 Étape 4/5 : Test FFmpeg (assemblage vidéo)..."

# Créer dossier temporaire
TEST_DIR="/tmp/n8n-test-$(date +%s)"
mkdir -p "$TEST_DIR"

# Générer 2 vidéos de test (3 secondes chacune)
echo "   Génération vidéos de test..."
ffmpeg -f lavfi -i color=c=blue:s=1080x1920:d=3 -f lavfi -i "sine=frequency=440:duration=3" \
    -vcodec libx264 -pix_fmt yuv420p -y "$TEST_DIR/clip_0.mp4" &> /dev/null

ffmpeg -f lavfi -i color=c=red:s=1080x1920:d=3 -f lavfi -i "sine=frequency=880:duration=3" \
    -vcodec libx264 -pix_fmt yuv420p -y "$TEST_DIR/clip_1.mp4" &> /dev/null

# Créer fichier concat
cat > "$TEST_DIR/concat.txt" <<EOF
file '$TEST_DIR/clip_0.mp4'
file '$TEST_DIR/clip_1.mp4'
EOF

# Assembler
echo "   Assemblage des clips..."
ffmpeg -f concat -safe 0 -i "$TEST_DIR/concat.txt" -c copy "$TEST_DIR/merged.mp4" &> /dev/null

# Ajouter texte
echo "   Ajout overlay texte..."
ffmpeg -i "$TEST_DIR/merged.mp4" \
    -vf "drawtext=text='Test n8n':fontcolor=white:fontsize=64:box=1:boxcolor=black@0.6:boxborderw=10:x=(w-text_w)/2:y=h-th-80" \
    -codec:a copy "$TEST_DIR/final.mp4" &> /dev/null

if [ -f "$TEST_DIR/final.mp4" ]; then
    FILE_SIZE=$(du -h "$TEST_DIR/final.mp4" | cut -f1)
    echo -e "${GREEN}✓${NC} FFmpeg test OK - Vidéo finale : $FILE_SIZE"
else
    echo -e "${RED}✗${NC} Échec test FFmpeg"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"
echo ""

# ===== ÉTAPE 5 : Test webhook n8n =====
echo "🌐 Étape 5/5 : Test webhook n8n..."
echo "   Préparation payload..."

# Créer payload JSON
cat > /tmp/test-payload.json <<EOF
{
  "video_urls": [
    "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_1mb.mp4"
  ],
  "text": "Test automatique n8n 🤖",
  "caption": "Vidéo de test workflow n8n",
  "music_url": ""
}
EOF

echo "   Envoi au webhook..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${N8N_WEBHOOK_URL}${WEBHOOK_PATH}" \
    -H "Content-Type: application/json" \
    -d @/tmp/test-payload.json)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✓${NC} Webhook activé (HTTP $HTTP_CODE)"
    echo "   Réponse : $BODY"
    echo ""
    echo -e "${YELLOW}⚠${NC} Vérifier Telegram pour l'approbation manuelle"
else
    echo -e "${RED}✗${NC} Webhook error (HTTP $HTTP_CODE)"
    echo "   Body : $BODY"
    echo ""
    echo "   Causes possibles :"
    echo "   - Workflow non activé dans n8n"
    echo "   - Webhook path incorrect"
    echo "   - Credentials manquants"
fi

# Cleanup
rm -f /tmp/test-payload.json

echo ""
echo "======================================================="
echo "✅ Tests terminés !"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Vérifier le message Telegram d'approbation"
echo "   2. Répondre /approve dans le bot Telegram"
echo "   3. Vérifier la publication Instagram"
echo ""
echo "🐛 Debug :"
echo "   - Logs n8n : docker logs n8n"
echo "   - Workflow : ${N8N_WEBHOOK_URL}/workflow/{ID}"
echo ""
