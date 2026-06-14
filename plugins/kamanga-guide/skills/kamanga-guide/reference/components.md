# Catalogue de composants

Le CSS de tous ces composants vit dans `templates/guide.html`. Ici : **quand** utiliser chaque composant et le **snippet HTML** à coller dans un `.page-body`.

Règle de choix : un composant graphique (pipeline, escalier, table, cas) par idée structurante. Ne pas empiler 3 visualisations sur une page. Viser 1 à 2 blocs visuels + texte par page.

---

## Texte et accents

### Titre de section
```html
<div class="phase-num">Chapitre 03 · Le référentiel</div>
<h2 class="phase-title">Le titre fort<br/>de la page.</h2>
<h3>3.1 Sous-section</h3>
<p>Paragraphe. <strong>Gras magenta</strong>, <em>italique magenta</em>.</p>
```

### Citation mise en avant
```html
<div class="quote-box">« La phrase qui doit rester en tête. »</div>
```

### Encadré d'information (neutre ou ambre)
```html
<div class="info-note">
  <div class="label">Le titre de l'encadré</div>
  <p>Le contenu.</p>
</div>
<div class="info-note amber-note">
  <div class="label">Encadré accentué</div>
  <p>Pour un message clé ou un avertissement.</p>
</div>
```

---

## Cartes et grilles

### Piliers (grille 2 colonnes)
Pour 2 à 5 idées de même niveau. `wide` = pleine largeur (idéal pour un 5e élément).
```html
<div class="pillars">
  <div class="pillar"><div class="num">01</div><div class="head">Titre</div><div class="body">Texte.</div></div>
  <div class="pillar"><div class="num">02</div><div class="head">Titre</div><div class="body">Texte.</div></div>
  <div class="pillar wide"><div class="num">05</div><div class="head">Titre large</div><div class="body">Texte.</div></div>
</div>
```

---

## Tables

### Table de métriques (zébrée, arrondie)
```html
<table class="metrics">
  <thead><tr><th>Métrique</th><th>Baseline</th><th>Objectif</th></tr></thead>
  <tbody>
    <tr><td><strong>Lead time</strong></td><td class="muted">à mesurer</td><td><span class="badge badge-high">&minus;50%</span></td></tr>
    <tr><td><strong>Failure rate</strong></td><td class="num">12%</td><td><span class="badge badge-mid">&lt; 15%</span></td></tr>
  </tbody>
</table>
```
- `td.muted` : valeur en attente (italique gris). `td.num` : chiffres alignés.

### Badges (toujours texte + couleur)
```html
<span class="badge badge-low">Faible</span>
<span class="badge badge-mid">Modéré</span>
<span class="badge badge-high">Objectif</span>
<span class="badge badge-crit">Critique</span>
```

---

## Pipelines et flux (montrer les dynamiques entre composants)

### Pipeline 4 étapes avec flèches
Pour un framework / process en 4 phases.
```html
<div class="flow4">
  <div class="f-step"><div class="f-num">PHASE 1</div><div class="f-name">Mesurer</div><div class="f-desc">Description courte.</div></div>
  <div class="f-step"><div class="f-num">PHASE 2</div><div class="f-name">Débloquer</div><div class="f-desc">Description courte.</div></div>
  <div class="f-step"><div class="f-num">PHASE 3</div><div class="f-name">Stabiliser</div><div class="f-desc">Description courte.</div></div>
  <div class="f-step"><div class="f-num">PHASE 4</div><div class="f-name">Accélérer</div><div class="f-desc">Description courte.</div></div>
</div>
```

### Chronologie proportionnelle
À placer SOUS un `flow4` pour montrer la durée relative de chaque phase. `flex:` = poids proportionnel.
```html
<div class="timeline-bar">
  <div class="tb-seg tb-1" style="flex: 2;"><span class="tb-name">Mesurer</span><span class="tb-week">Sem. 1-2</span></div>
  <div class="tb-seg tb-2" style="flex: 3;"><span class="tb-name">Débloquer</span><span class="tb-week">Sem. 3-5</span></div>
  <div class="tb-seg tb-3" style="flex: 5;"><span class="tb-name">Stabiliser</span><span class="tb-week">Sem. 6-10</span></div>
  <div class="tb-seg tb-4" style="flex: 3;"><span class="tb-name">Accélérer</span><span class="tb-week">Sem. 11-13</span></div>
</div>
<p class="timeline-caption">La largeur de chaque bloc reflète sa durée réelle.</p>
```

### Pipeline à segments + barre de répartition (dynamique du temps)
Pour décomposer un flux et montrer OÙ le temps se concentre. Marquer le goulot avec `bottleneck`. La `seg-bar` en dessous a des `flex:` proportionnels au temps réel.
```html
<div class="leadflow">
  <div class="lf-step"><div class="lf-name">Prêt à dev</div><div class="lf-tag">file d'attente</div></div>
  <div class="lf-step"><div class="lf-name">En cours</div><div class="lf-tag">dev actif</div></div>
  <div class="lf-step bottleneck"><div class="lf-name">En review</div><div class="lf-tag">goulot n°1</div></div>
  <div class="lf-step"><div class="lf-name">Prêt à déployer</div><div class="lf-tag">attente release</div></div>
  <div class="lf-step"><div class="lf-name">En production</div><div class="lf-tag">livré</div></div>
</div>
<div class="seg-bar-legend">
  <span class="sl"><span class="dot dot-bottleneck"></span>Segment goulot</span>
  <span class="sl"><span class="dot dot-flow"></span>Reste du flux</span>
</div>
<div class="seg-bar">
  <div class="sg sg-1" style="flex: 10;">10%</div>
  <div class="sg sg-2" style="flex: 20;">20%</div>
  <div class="sg sg-3" style="flex: 50;">Review · 50%</div>
  <div class="sg sg-4" style="flex: 15;">15%</div>
  <div class="sg sg-5" style="flex: 5;">5%</div>
</div>
```

### Pipeline 6 étapes à deux acteurs (humain / IA)
Quand chaque étape implique deux rôles. Légende `flow-legend` au-dessus.
```html
<div class="flow-legend">
  <span class="lg"><span class="chip chip-humain">Humain</span> décide, autorise</span>
  <span class="lg"><span class="chip chip-ia">IA</span> exécute</span>
</div>
<div class="flow6">
  <div class="f-step">
    <div class="f-num">PHASE 1</div><div class="f-name">Cadrage</div>
    <div class="f-actor"><span class="chip chip-ia">IA</span><span class="t">analyse l'existant</span></div>
    <div class="f-actor"><span class="chip chip-humain">Humain</span><span class="t">pose le problème</span></div>
  </div>
  <!-- ... 6 .f-step ... -->
</div>
```

### Stepper 7 étapes (parcours linéaire)
Idée vers livraison. `s-ia` colore la pastille en ambre. `pilote-bar` montre le partage.
```html
<div class="stepper7">
  <div class="s-step"><div class="s-dot">1</div><div class="s-name">Idée</div><div class="s-actor">métier</div></div>
  <div class="s-step s-ia"><div class="s-dot">5</div><div class="s-name">Implémen-<br/>tation</div><div class="s-actor">agents IA</div></div>
  <!-- ... jusqu'a 7 ... -->
</div>
<div class="pilote-bar"><div class="pb-h">Piloté par l'humain</div><div class="pb-ia">Développé par l'IA</div></div>
```

---

## Escalier de maturité (5 niveaux)
Pour une grille de progression. Barres de hauteur croissante (`l1`..`l5`), légendes alignées dessous.
```html
<div class="stairs-bars">
  <div class="st-col l1"><div class="st-name">Artisanal</div><div class="st-bar">1</div></div>
  <div class="st-col l2"><div class="st-name">Documenté</div><div class="st-bar">2</div></div>
  <div class="st-col l3"><div class="st-name">Outillé</div><div class="st-bar">3</div></div>
  <div class="st-col l4"><div class="st-name">Automatisé</div><div class="st-bar">4</div></div>
  <div class="st-col l5"><div class="st-name">Garanti</div><div class="st-bar">5</div></div>
</div>
<div class="stairs-caps">
  <div class="st-cap"><div class="st-desc">Tout dans les têtes</div><div class="st-risk">Dépendance individus</div></div>
  <!-- ... -->
  <div class="st-cap"><div class="st-desc">IA + contrôles + humain</div><div class="st-risk risk-target">La cible</div><div class="st-flag"><span class="badge badge-high">Objectif</span></div></div>
</div>
```
Variantes de risque : `st-risk risk-danger` (rouge) / `st-risk risk-target` (ambre).

---

## Cas clients (avant / après)
```html
<div class="case">
  <div class="case-title">Secteur, type d'organisation</div>
  <div class="case-lead">Contexte en une ligne.</div>
  <div class="case-row before"><div class="case-label">Avant</div><div class="case-value">Situation, <strong>chiffre clé</strong>.</div></div>
  <div class="case-row after"><div class="case-label">Après 90j</div><div class="case-value">Résultat, <strong>chiffre clé</strong>.</div></div>
  <div class="case-row"><div class="case-label">Levier clé</div><div class="case-value">Ce qui a fait la différence.</div></div>
</div>
```
Variante diagnostic : `case-row absent` (label rouge) pour "signaux d'absence".

---

## Pièges + antidotes
```html
<div class="trap">
  <div class="trap-num">Piège 1</div>
  <div class="trap-title">Le titre du piège</div>
  <p>La description du piège.</p>
  <p class="trap-antidote"><span class="label">Antidote</span>La parade.</p>
</div>
```

---

## Étapes chronométrées (template review, plan d'action)
```html
<div class="review-step">
  <div class="step-meta"><div class="step-num">ÉTAPE 1</div><div class="step-time">10 minutes</div></div>
  <div class="step-body">
    <div class="step-title">Le titre de l'étape</div>
    <p>Le contenu.</p>
  </div>
</div>
```

---

## Checklist (cases à cocher)
```html
<ul class="check-list">
  <li>Premier point à vérifier</li>
  <li>Deuxième point</li>
</ul>
```

---

## Sommaire (uniquement si > 12 pages)
```html
<ol class="toc-list">
  <li><span class="toc-label">Titre du chapitre</span><span class="toc-dots"></span><span class="toc-page">3</span></li>
</ol>
```

---

## Carte CTA intra-contenu (sur page claire)
Pour une offre placée au milieu du guide (pas la page finale).
```html
<div class="cta-card">
  <div class="offer-label">Auto-évaluation · 5 minutes</div>
  <div class="head">Votre process est-il prêt ? <span class="arrow">&#8594;</span></div>
  <div class="body">Description de l'offre.</div>
  <a class="link-hint" href="https://app.kamanga.fr/forms/xxx">app.kamanga.fr/forms/xxx</a>
</div>
```
Lien manquant : `<span class="placeholder">lien à fournir : NOM</span>`.

---

## Flèches et caractères sûrs (pas de tiret long)
- Flèche : `&#8594;` (→) dans les CTA.
- Chevron de pipeline : géré en CSS (`\203A`), ne pas l'écrire en dur.
- Séparateur méta : `·` (point médian).
- Moins : `&minus;` (pour `−50%`). Inférieur : `&lt;`.
