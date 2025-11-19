# Comparaison Détaillée des Coûts

## Coût par Vidéo (60 secondes)

| Solution | Coût unitaire | Breakdown |
|----------|---------------|-----------|
| **Monteur vidéo freelance** | 42,50€ | 25-60€ selon expérience |
| **Submagic Starter** | 1,27€ | 19€/mois ÷ 15 vidéos |
| **Submagic Pro** | 0,97€ | 39€/mois ÷ 40 vidéos |
| **Submagic Business** | 0,69€ | 69€/mois ÷ 100 vidéos |
| **Open-Source (100% local)** | 0,11€ | VPS 11,24€/mois ÷ 100 vidéos |
| **Hybrid (local + APIs)** | 0,17€ | VPS + Whisper API + Claude |

## Coût Total Mensuel (40 vidéos/mois)

### Configuration Submagic

| Composant | Coût |
|-----------|------|
| Submagic Pro | 39,00€ |
| VPS n8n (OVH 4GB) | 5,62€ |
| **Total** | **44,62€** |
| **Par vidéo** | **1,12€** |

### Configuration Open-Source Hybrid

| Composant | Coût |
|-----------|------|
| VPS (OVH 8GB) | 11,24€ |
| Whisper API | 0,23€ (40 × 0,006€) |
| Claude API | 2,00€ (40 × 0,05€) |
| ElevenLabs (optionnel) | 22,00€ |
| **Total sans voix** | **13,47€** |
| **Total avec voix** | **35,47€** |
| **Par vidéo** | **0,17-0,89€** |

## Économies Annuelles

**Client TPE/PME : 12 vidéos/mois**

| Solution | Coût annuel | Économie vs Monteur |
|----------|-------------|---------------------|
| Monteur freelance | 6.120€ | - |
| Submagic Pro | 535€ | 5.585€ (91%) |
| Open-Source Hybrid | 162€ | 5.958€ (97%) |

**ROI Submagic** : Atteint en 1,8 mois  
**ROI Open-Source** : Atteint en 24 mois (après amortissement développement)

## Coûts Cachés à Considérer

### Submagic
- ✅ **Aucun coût caché**
- ✅ Updates incluses
- ✅ Support inclus
- ⚠️ Augmentation prix possible

### Open-Source
- ⚠️ **Temps développement** : 25-35h (1.250€)
- ⚠️ **Maintenance** : 2-3h/mois (100-150€/mois si valorisé)
- ⚠️ **Infrastructure** : Backups, monitoring
- ⚠️ **Mises à jour** : FFmpeg, Whisper, dépendances

## Coût par Fonctionnalité

| Fonctionnalité | Submagic (inclus) | Open-Source (coût dev) |
|----------------|-------------------|------------------------|
| Sous-titres auto | ✅ | 4h (200€) |
| Zooms dynamiques | ✅ | 3h (150€) |
| Transitions | ✅ | 3h (150€) |
| B-rolls intelligents | ✅ | 12h (600€) + API Claude |
| Clean audio | ✅ | 2h (100€) |
| Templates viral | ✅ | 8h (400€) |
| **Total développement** | **0€** | **1.600€** |

## Seuils de Rentabilité

### Submagic devient rentable si :
- Production > 1 vidéo/semaine
- Besoin qualité immédiate
- Pas de compétences techniques
- Temps = argent

### Open-Source devient rentable si :
- Production > 50 vidéos/mois
- Compétences techniques disponibles
- Vision long terme (3+ ans)
- Besoin contrôle total

## Scénarios par Volume

### Faible volume (5 vidéos/mois)

| Solution | Coût/mois | Coût/vidéo |
|----------|-----------|------------|
| Monteur | 212€ | 42,50€ |
| Submagic Starter | 19€ | 3,80€ |
| Open-Source | 11,24€ | 2,25€ |

**Recommandation** : Submagic Starter

### Volume moyen (40 vidéos/mois)

| Solution | Coût/mois | Coût/vidéo |
|----------|-----------|------------|
| Monteur | 1.700€ | 42,50€ |
| Submagic Pro | 44,62€ | 1,12€ |
| Open-Source | 16,81€ | 0,42€ |

**Recommandation** : Submagic Pro (court terme) → Open-Source (long terme)

### Gros volume (200 vidéos/mois)

| Solution | Coût/mois | Coût/vidéo |
|----------|-----------|------------|
| Monteur | 8.500€ | 42,50€ |
| Submagic API | ~350€ | ~1,75€ |
| Open-Source | 20,00€ | 0,10€ |

**Recommandation** : Open-Source (ROI immédiat)

## Coûts Infrastructure Détaillés

### VPS Options

| Provider | Plan | RAM | CPU | Prix/mois |
|----------|------|-----|-----|-----------|
| OVH | VPS-1 | 4GB | 2vCore | 5,62€ |
| OVH | VPS-2 | 8GB | 4vCore | 11,24€ |
| Hostinger | 4GB | 4GB | 2vCore | 5,00€ |
| Hostinger | 8GB | 8GB | 4vCore | 12,00€ |
| Contabo | 8GB | 8GB | 4vCore | 6,99€ |

**Recommandation** : OVH VPS-2 (fiabilité + support FR)

### APIs IA (optionnelles)

| API | Coût | Usage |
|-----|------|-------|
| Whisper (OpenAI) | 0,006$/min | Transcription premium |
| Claude Sonnet 4.5 | 3$ per 1M tokens input | Analyse contenu |
| ElevenLabs TTS | 22$/mois | Voix-off IA |
| Stable Diffusion | Gratuit (local) | Génération images |

## Conclusion : Quelle Solution Choisir ?

### Choisir Submagic si :
- ✅ Démarrage rapide (< 1 semaine)
- ✅ Budget 40-70€/mois OK
- ✅ Pas de compétences DevOps
- ✅ Production 10-100 vidéos/mois

### Choisir Open-Source si :
- ✅ Budget développement 1.500€ disponible
- ✅ Compétences techniques (Docker, FFmpeg, Python)
- ✅ Vision long terme (3+ ans)
- ✅ Production > 50 vidéos/mois OU besoin contrôle total

### Approche Hybride Recommandée :
1. **Mois 1-6** : Submagic (validation marché, premiers clients)
2. **Mois 6-12** : Développement stack open-source en parallèle
3. **Mois 12+** : Migration progressive, Submagic en backup

**ROI optimal** : -91% coûts année 1, -97% année 2+

---

*Dernière mise à jour : 15 novembre 2025*