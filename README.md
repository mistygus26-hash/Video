# 🎬 Video Automation Project

Projet d'automatisation de production vidéo utilisant n8n, FFmpeg, Whisper et Claude Desktop via MCP, déployé sur VPS Debian.

## 🎯 Objectifs

- **Automatiser** la production de vidéos short-form (TikTok, Instagram Reels, YouTube Shorts)
- **Réduire** les coûts de 95% vs monteur vidéo traditionnel
- **Scalabilité** : traiter 100+ vidéos/mois en mode autonome
- **Qualité** : sous-titres IA, B-rolls intelligents, audio optimisé

## 🏗️ Architectures Disponibles

### 1️⃣ Workflow Submagic (Managed)
- **Coût** : 1,12€/vidéo
- **Setup** : 15-30 min
- **Qualité** : ⭐⭐⭐⭐⭐
- **Use case** : Clients premium, production rapide

### 2️⃣ Workflow Open-Source Hybrid (Recommandé)
- **Coût** : 0,17€/vidéo
- **Setup** : 2-4 heures
- **Qualité** : ⭐⭐⭐⭐
- **Use case** : Production volume, contrôle total

## 🖥️ Spécifications VPS

Basé sur infrastructure VPS Debian :
- **OS** : Debian 12 (Bookworm)
- **RAM** : 8GB recommandé
- **CPU** : 4 vCores minimum
- **Storage** : 50GB SSD
- **Services** : n8n, Docker, FFmpeg, Whisper local, ChromaDB

## 🚀 Installation Rapide

```bash
# 1. Clone du repository
git clone https://github.com/mistygus26-hash/Video.git
cd Video

# 2. Installation dépendances
chmod +x scripts/setup/install-dependencies.sh
sudo ./scripts/setup/install-dependencies.sh

# 3. Configuration MCP servers
chmod +x scripts/setup/setup-mcp-servers.sh
./scripts/setup/setup-mcp-servers.sh

# 4. Initialisation RAG
chmod +x scripts/setup/init-rag-database.sh
./scripts/setup/init-rag-database.sh

# 5. Configuration environnement
cp config/env.example .env
# Éditer .env avec vos clés API

# 6. Lancement stack Docker
cd docker
docker-compose up -d
```

## 🔌 Intégration MCP (Claude Desktop)

Ce projet utilise **3 serveurs MCP** :

1. **video-processing-mcp** : Outils FFmpeg, Whisper, analyse
2. **rag-knowledge-mcp** : Base connaissances vidéos, templates
3. **github-mcp** : Gestion repository (déjà configuré)

### Configuration Claude Desktop

Ajouter dans `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) ou `%APPDATA%\Claude\claude_desktop_config.json` (Windows) :

```json
{
  "mcpServers": {
    "video-processing": {
      "command": "node",
      "args": ["/chemin/vers/Video/mcp-servers/video-processing/server.js"],
      "env": {
        "FFMPEG_PATH": "/usr/bin/ffmpeg",
        "WHISPER_API": "http://localhost:9000",
        "CLAUDE_API_KEY": "${CLAUDE_API_KEY}"
      }
    },
    "rag-knowledge": {
      "command": "node",
      "args": ["/chemin/vers/Video/mcp-servers/rag-knowledge/server.js"],
      "env": {
        "CHROMADB_HOST": "localhost",
        "CHROMADB_PORT": "8000"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

## 📚 Documentation

- [Analyse Submagic](docs/analyse-submagic.md) - Étude complète de la solution Submagic
- [Stack Open-Source](docs/analyse-open-source.md) - Architecture technique alternative
- [Comparaison Coûts](docs/comparaison-couts.md) - Tableaux ROI détaillés
- [Architecture Technique](docs/architecture-technique.md) - Schémas et flux

## 🔄 Workflows Disponibles

### Submagic
- [Basic Automation](workflows/submagic/workflow-submagic-basic.json) - Workflow simple
- [Advanced Multi-Platform](workflows/submagic/workflow-submagic-advanced.json) - Publication multi-réseaux

### Open-Source
- [FFmpeg + Whisper](workflows/open-source/workflow-ffmpeg-whisper.json) - Stack de base
- [Production Ready](workflows/open-source/workflow-production-ready.json) - Workflow complet entreprise

### Hybrid
- [Optimal Cost/Quality](workflows/hybrid/workflow-hybrid-optimal.json) - Meilleur compromis

## 🧪 Tests

```bash
# Tester workflow Submagic
./tests/test-workflow-submagic.sh

# Tester workflow open-source
./tests/test-workflow-opensource.sh
```

## 💰 Coûts Estimés

| Configuration | Coût/vidéo | Coût/mois (40 vidéos) | Économie vs Monteur |
|---------------|------------|----------------------|-------------------|
| Monteur vidéo | 42,50€ | 1.700€ | - |
| Submagic Pro | 1,12€ | 44,62€ | 97% |
| Open-Source Hybrid | 0,17€ | 16,81€ | 99% |

## 🛠️ Stack Technique

- **Orchestration** : n8n (self-hosted)
- **Montage vidéo** : FFmpeg
- **Transcription** : Whisper (Faster Whisper)
- **Analyse IA** : Claude Sonnet 4.5 via MCP
- **Base de connaissances** : ChromaDB (RAG)
- **Containerisation** : Docker
- **VPS** : Debian 12

## 📈 Roadmap

- [x] Workflow Submagic basique
- [x] Workflow open-source FFmpeg + Whisper
- [x] Intégration MCP Claude Desktop
- [x] Système RAG pour B-rolls
- [ ] Dashboard monitoring vidéos
- [ ] API REST publique
- [ ] Support multi-langues avancé
- [ ] Templates miniatures YouTube (Thumbmagic equivalent)

## 🤝 Contribution

Ce projet est créé pour AurastackAI. Pour suggestions :
- Issues GitHub
- Telegram : @mistygus26

## 📄 License

MIT License - voir [LICENSE](LICENSE)

## 🙏 Remerciements

- n8n community pour les templates
- FFmpeg pour l'outil extraordinaire
- OpenAI pour Whisper
- Anthropic pour Claude & MCP

---

**Auteur** : AurastackAI  
**Version** : 1.0.0  
**Dernière mise à jour** : 15 novembre 2025