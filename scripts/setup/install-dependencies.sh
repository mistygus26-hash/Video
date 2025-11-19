#!/bin/bash

###############################################################################
# Video Automation Project - Installation Script
# Description: Installe toutes les dépendances pour VPS Debian 12
# Usage: sudo ./install-dependencies.sh
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check root
[[ $EUID -ne 0 ]] && error "Ce script doit être exécuté en root (sudo)"

log "======================================"
log "Video Automation - Installation"
log "======================================"

# Variables
N8N_DATA_DIR="/home/n8n-data"
PROCESSING_DIR="${N8N_DATA_DIR}/processing"
BROLL_DIR="${N8N_DATA_DIR}/brolls-library"
RAG_DIR="${N8N_DATA_DIR}/rag"

# 1. Mise à jour système
log "Mise à jour du système..."
apt update && apt upgrade -y

# 2. Installation dépendances de base
log "Installation des dépendances de base..."
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ffmpeg \
    docker.io \
    docker-compose \
    nginx \
    certbot \
    python3-certbot-nginx

# 3. Installation Node.js (version 20 LTS)
log "Installation de Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    log "Node.js $(node --version) installé"
else
    log "Node.js déjà installé: $(node --version)"
fi

# 4. Installation n8n globalement
log "Installation de n8n..."
npm install -g n8n
log "n8n $(n8n --version) installé"

# 5. Création structure dossiers
log "Création de la structure de dossiers..."
mkdir -p ${N8N_DATA_DIR}/{processing,brolls-library,logs,workflows}
mkdir -p ${RAG_DIR}/{config,data,embeddings,scripts}

# 6. Installation Faster Whisper
log "Installation de Faster Whisper..."
python3 -m venv /opt/whisper-env
source /opt/whisper-env/bin/activate
pip install --upgrade pip
pip install faster-whisper flask flask-cors

# Création serveur Whisper API
log "Création du serveur Whisper API..."
cat > /opt/whisper-server.py <<'EOFPYTHON'
#!/usr/bin/env python3
from flask import Flask, request, jsonify
from flask_cors import CORS
from faster_whisper import WhisperModel
import tempfile
import os
import logging

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialisation du modèle
MODEL_SIZE = os.getenv('WHISPER_MODEL', 'medium')
model = None

def init_model():
    global model
    if model is None:
        logger.info(f"Loading Whisper model: {MODEL_SIZE}")
        model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
        logger.info("Model loaded successfully")

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "model": MODEL_SIZE})

@app.route('/asr', methods=['POST'])
def transcribe():
    try:
        init_model()
        
        # Récupération du fichier audio
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        audio_file = request.files['file']
        language = request.form.get('language', 'fr')
        
        # Sauvegarde temporaire
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as tmp:
            audio_file.save(tmp.name)
            tmp_path = tmp.name
        
        # Transcription
        logger.info(f"Transcribing: {tmp_path}")
        segments, info = model.transcribe(
            tmp_path,
            language=language,
            word_timestamps=True,
            vad_filter=False
        )
        
        # Formatage résultats
        result = {
            'text': '',
            'segments': [],
            'words': [],
            'language': info.language,
            'language_probability': info.language_probability
        }
        
        for segment in segments:
            result['text'] += segment.text + ' '
            result['segments'].append({
                'id': segment.id,
                'start': segment.start,
                'end': segment.end,
                'text': segment.text
            })
            
            if segment.words:
                for word in segment.words:
                    result['words'].append({
                        'word': word.word,
                        'start': word.start,
                        'end': word.end,
                        'probability': word.probability
                    })
        
        # Cleanup
        os.unlink(tmp_path)
        
        logger.info(f"Transcription completed: {len(result['words'])} words")
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000, threaded=True)
EOFPYTHON

chmod +x /opt/whisper-server.py

# Service systemd pour Whisper
log "Configuration du service Whisper..."
cat > /etc/systemd/system/whisper-api.service <<EOF
[Unit]
Description=Whisper API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt
Environment="WHISPER_MODEL=medium"
ExecStart=/opt/whisper-env/bin/python3 /opt/whisper-server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 7. Installation ChromaDB (RAG)
log "Installation de ChromaDB..."
python3 -m venv ${N8N_DATA_DIR}/rag-env
source ${N8N_DATA_DIR}/rag-env/bin/activate
pip install --upgrade pip
pip install chromadb sentence-transformers numpy

# 8. Permissions
log "Configuration des permissions..."
chown -R 1000:1000 ${N8N_DATA_DIR}
chmod -R 755 ${N8N_DATA_DIR}

# 9. Démarrage services
log "Démarrage des services..."
systemctl daemon-reload
systemctl enable whisper-api
systemctl start whisper-api

# Vérification service Whisper
sleep 3
if systemctl is-active --quiet whisper-api; then
    log "✅ Whisper API démarrée avec succès"
else
    warn "⚠️  Whisper API n'a pas démarré correctement"
    journalctl -u whisper-api -n 20 --no-pager
fi

# 10. Configuration firewall (si ufw installé)
if command -v ufw &> /dev/null; then
    log "Configuration firewall..."
    ufw allow 5678/tcp  # n8n
    ufw allow 9000/tcp  # Whisper API
fi

log "======================================"
log "✅ Installation terminée avec succès!"
log "======================================"
log ""
log "📋 Services disponibles:"
log "   • n8n: http://localhost:5678"
log "   • Whisper API: http://localhost:9000"
log "   • ChromaDB: ${RAG_DIR}/data"
log ""
log "📁 Répertoires:"
log "   • Processing: ${PROCESSING_DIR}"
log "   • B-rolls: ${BROLL_DIR}"
log "   • RAG: ${RAG_DIR}"
log "   • Logs: ${N8N_DATA_DIR}/logs"
log ""
log "🚀 Prochaines étapes:"
log "   1. Configurer MCP servers: ./scripts/setup/setup-mcp-servers.sh"
log "   2. Initialiser RAG: ./scripts/setup/init-rag-database.sh"
log "   3. Copier config/env.example vers .env et configurer"
log "   4. Tester: curl http://localhost:9000/health"
log ""
log "📖 Documentation: docs/"