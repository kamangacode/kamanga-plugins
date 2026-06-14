# Refacto Fable-native du plugin Kamanga (dev-core)

> Proposition d'architecture pour casser le cycle de dev linéaire actuel et le remplacer
> par une "Org d'ingénierie virtuelle" qui décompose un PRD en issues, puis les construit
> en essaim parallèle avec revue adversariale de très haute qualité.
>
> Date : 2026-06-10. Cible d'édition : `kamanga-plugins/plugins/dev-core`.
> Statut : proposition (draft). Aucun code n'a été modifié par ce document.
>
> **Compagnon** : [discovery-and-bootstrap.md](./discovery-and-bootstrap.md) étend cette
> architecture de 3 couches avec deux couches amont : **Couche 0 (Discovery / Shaping)** =
> étudier une idée, regarder le passé, challenger le présent, analyser le risque et proposer
> plusieurs solutions ; et **Couche -1 (Bootstrap)** = readiness du projet + intégration des
> skills d'init (env, github, CI, releases, ADR axial, docs). À lire après la section 5.

---

## 0. Comment lire ce document

| Section | Contenu | Pour qui |
|---------|---------|----------|
| 1 | TL;DR : le changement de paradigme en une page | Décision rapide |
| 2 | Capacités de Fable 5 (connu vs supposé) | Honnêteté technique |
| 3 | Diagnostic : ce que `/dev` fait aujourd'hui, et pourquoi | Comprendre l'existant |
| 4 | Le pivot : de la chaîne linéaire à l'essaim | Le coeur de la proposition |
| 5 | Architecture cible : les 3 couches de l'Org virtuelle | Conception |
| 6 | Le cycle de vie dense (4 passes au lieu de 15 étapes) | Conception |
| 7 | Nouveaux skills, agents et artifacts (specs concrètes) | À construire |
| 8 | Implémentations concrètes (scripts Workflow) | Code de départ |
| 9 | Sélection de modèle par rôle (Fable vs Opus vs Haiku) | Coût et qualité |
| 10 | Mapping ancien vers nouveau | Migration |
| 11 | Plan d'action par phases | Exécution |
| 12 | Risques et mitigations | Garde-fous |
| 13 | Construire ce plugin AVEC Fable | Méta |
| 14 | Décisions ouvertes (les vrais choix de goût) | À trancher avec toi |

---

## 1. TL;DR

Le plugin actuel (`/dev #N`) est une **machine à états linéaire pour une seule issue**, conçue
pour un monde où le modèle était lent, cher, à contexte court, et où l'humain servait de
colle entre chaque micro-étape. D'où : 15 étapes séquentielles, beaucoup de gates, des
artifacts minuscules passés d'étape en étape, et une notation compressée pour économiser
des tokens.

Fable 5 change les contraintes de base : contexte de 1M tokens, intelligence au sommet du
palier Opus, exécution agentique longue très solide, sortie structurée fiable, et surtout la
possibilité de **fan-out massif** (essaims d'agents) à coût maîtrisé.

Le refacto propose de remplacer la chaîne linéaire mono-issue par une **Org d'ingénierie
virtuelle** en trois couches :

1. **Décomposition** : tu donnes un PRD (ou une grosse feature). Un agent "Principal Engineer"
   le lit avec tout le codebase en contexte et produit un **graphe d'issues** (noeuds = issues
   dimensionnées avec critères d'acceptation, arêtes = dépendances bloquantes), exactement comme
   une équipe ferait un découpage de backlog. Tu valides le graphe (gate niveau org).
2. **Exécution en essaim** : les issues parallélisables tournent en **vagues** concurrentes, chacune
   dans son worktree isolé, à travers un cycle de vie compressé.
3. **Revue de très haute qualité** : revue multi-agents par dimension (correctness, sécurité,
   perf, architecture, tests, docs) avec **vérification adversariale** (chaque finding doit
   survivre à un vote de sceptiques) et **boucle jusqu'à épuisement** (loop-until-dry).

Le principe central du pivot : l'ancien design **dépensait des gates** (attention humaine) pour
compenser la faiblesse de chaque étape. Fable nous laisse **dépenser du compute** (plus d'agents,
vérification adversariale) à la place. L'humain passe de "approbateur d'étape" (10 gates) à
"arbitre de goût" sur 2 décisions clés plus le merge final.

Concrètement : 15 micro-étapes par issue deviennent **4 passes denses** (Shape, Build, Verify,
Ship), avec plus de compute total mais moins de gates humains, et la capacité d'avancer
**N issues en parallèle**.

Nom proposé pour le nouvel orchestrateur : **`/forge`** (voir section 14 pour le choix du nom).

---

## 2. Capacités de Fable 5 (ce qui est connu vs supposé)

> Cette section sépare ce qui est vérifié (via la skill `claude-api` du harness, cache du 2026-05-26)
> de ce qui est une hypothèse de conception. Le but : que l'architecture reste honnête et
> dégrade proprement si une hypothèse se révèle fausse.

### 2.1 Faits vérifiés

| Propriété | Valeur | Implication pour le refacto |
|-----------|--------|------------------------------|
| Model ID | `claude-fable-5` | À référencer tel quel, sans suffixe de date |
| Palier | "Le plus puissant, le plus intelligent". Nouveau tier au-dessus d'Opus | Réserver Fable aux rôles à fort levier |
| Contexte | 1M tokens (entrée) | Un agent peut tenir un PRD entier + le codebase pertinent + les standards |
| Sortie max | 128K tokens (streaming requis au-delà de ~16K) | Plans, specs et dossiers volumineux en une passe |
| Tarif | 10 $ / MTok entrée, 50 $ / MTok sortie | 2x Opus en sortie. Le fan-out doit être tiéré (section 9) |
| Thinking | adaptive uniquement (`thinking: {type:"adaptive"}`) | Pas de `budget_tokens`. `temperature`/`top_p`/`top_k` rejetés (400) |
| Effort | `low`/`medium`/`high`/`xhigh`/`max` (`output_config.effort`) | Levier principal de profondeur. `high` par défaut, `xhigh` pour coder |
| Task Budgets (beta) | `task_budget` sur la boucle agentique, min 20k tokens | Borne le coût d'un essaim long sans tuer la qualité |
| Vision haute résolution | jusqu'à 2576px, coords 1:1 | Lecture de maquettes Figma, captures, diagrammes dans un PRD |
| Sortie structurée | `output_config.format` + schémas JSON | Le graphe d'issues et les findings deviennent des objets validés |
| Compaction (beta) | résumé serveur du contexte long | Sessions d'essaim longues sans exploser le 1M |
| Messages system mid-session (beta) | `role:"system"` dans `messages` | Injecter du contexte appris en cours de route sans casser le cache |
| Cache minimal | 2048 tokens (vs 4096 pour Opus) | Les petits préfixes d'agents fan-out cachent mieux sur Fable |

### 2.2 Particularité Fable à coder explicitement

Sur Fable 5, un `thinking: {type:"disabled"}` explicite renvoie une 400 (alors qu'Opus 4.8/4.7
l'acceptent). Il faut **omettre** le paramètre `thinking` au lieu de le désactiver. À tracer dans
les références du plugin si un jour il appelle l'API directement.

### 2.3 Hypothèses de conception (à valider, dégradation prévue)

Ces points portent la charge architecturale sans être chiffrés dans la doc API. Je les marque
comme hypothèses, et j'indique comment l'architecture dégrade si elles sont plus faibles que prévu.

| Hypothèse | Si plus faible que prévu, alors |
|-----------|----------------------------------|
| Fable décompose un PRD en graphe d'issues cohérent et bien dimensionné | Garder un gate humain fort sur le graphe (déjà prévu) + panel de juges (déjà prévu) |
| Fan-out de 8 à 16 agents concurrents reste de qualité | Réduire la largeur de vague, augmenter `effort`, sérialiser davantage |
| L'exécution longue (overnight) reste cohérente | Découper en vagues plus courtes avec re-scan d'état entre chaque |
| Le 1M de contexte permet de tenir PRD + codebase pertinent | Revenir à la fragmentation en artifacts (le modèle actuel), par sous-système |

Conclusion : même dans le pire cas, on retombe sur quelque chose de proche de l'actuel, jamais pire.
Le design est **additif et réversible**.

---

## 3. Diagnostic du process actuel

### 3.1 Ce que fait `/dev` aujourd'hui (rappel ancré dans le code)

Source : `plugins/dev-core/skills/dev/SKILL.md` (390 lignes).

Pipeline linéaire, une issue à la fois :

```
triage -> recheck -> frame -> analyze -> requirements -> spec -> plan ->
implement -> pr -> ci-watch -> validate -> review -> fix -> promote -> cleanup
```

- **Tiers** : `S` (≤3 fichiers), `F-lite` (1 domaine), `F-full` (multi-domaine). Le tier décide
  quelles étapes sont sautées.
- **Artifacts comme état** : `.mdx` dans `artifacts/frames|analyses|specs|plans`. `/dev` scanne
  ces dossiers pour détecter où on en est et reprendre.
- **Gates** : `frame -> spec -> plan` exigent une approbation humaine (frontmatter `status: approved`).
- **12 agents** : architect, backend-dev, frontend-dev, devops, tester, fixer, doc-writer,
  product-lead, security-auditor, recall, axial-adr-create, axial-adr-review.
- **Délégation** : l'orchestrateur ne code pas, il délègue aux skills et aux agents de domaine.

### 3.2 Ce qui marche bien (à préserver absolument)

1. **Artifacts comme marqueurs d'état** : robustesse, reprise après crash, persistance entre sessions.
2. **Worktrees isolés** : pas de code sur staging sans branche.
3. **Protocole de décision (DP)** : présentation propre des choix à l'humain.
4. **Conventional Comments** : format de findings standardisé.
5. **Pas de `--force`/`--hard`/`--amend`** : garde-fous git.
6. **Délégation orchestrateur -> agents** : séparation des responsabilités.

### 3.3 Ce qui est une contrainte de l'ancien monde (à casser)

| Trait actuel | Pourquoi il existait | Pourquoi Fable le rend obsolète |
|--------------|----------------------|----------------------------------|
| 15 étapes séquentielles | Chaque étape était fragile, il fallait découper finement | Un agent Fable fait plus par tour, avec tout le contexte |
| Une issue à la fois | Parallélisme risqué, contexte court | Fan-out fiable, worktrees isolés, vagues dépendance-aware |
| 10 gates humains | Compenser la faiblesse de chaque étape | La vérif adversariale compense, l'humain arbitre le goût |
| Artifacts minuscules passés d'étape en étape | Contexte court, il fallait re-hydrater | 1M permet de tenir frame+analyze+spec en un seul dossier |
| `frame` et `analyze` et `spec` séparés | Chaque passe coûtait cher | Collapsables en une passe "Shape" structurée |
| Décomposition manuelle (issue-triage une par une) | Pas d'agent capable de découper un PRD | Fable décompose un PRD en graphe naturellement |
| Revue mono-passe | Coût | Essaim adversarial multi-dimensions, loop-until-dry |

---

## 4. Le pivot : de la chaîne linéaire à l'essaim

### 4.1 Table du changement de paradigme

| Dimension | Ancien (`/dev`) | Nouveau (`/forge`) |
|-----------|-----------------|---------------------|
| Unité d'entrée | Une issue (`#N`) | Un PRD, une feature, ou un epic |
| Décomposition | Manuelle, une issue à la fois | Automatique, graphe d'issues + vagues |
| Forme du flux | Chaîne linéaire de 15 étapes | 4 passes denses x N issues en parallèle |
| Parallélisme | Aucun (mono-issue) | Vagues dépendance-aware, fan-out par passe |
| Rôle de l'humain | Approbateur de 10 gates | Arbitre de goût sur 2 gates + merge |
| Ce qu'on dépense pour la qualité | Gates (attention humaine) | Compute (agents + vérif adversariale) |
| Revue | Mono-passe multi-domaine | Multi-agents adversarial, loop-until-dry |
| Détection d'état | Scan artifacts + GitHub | Idem + graphe d'epic + journal Workflow |
| Modèle | Un seul, partout | Tiéré par rôle (Fable / Opus / Haiku) |
| Reprise | Re-scan artifacts | Idem + resume Workflow (`resumeFromRunId`) |

### 4.2 Le mantra

> Ancien monde : **moins d'étapes seraient risquées, donc on gate beaucoup.**
>
> Nouveau monde : **on peut se permettre plus de compute, donc on vérifie au lieu de gater.**

L'humain ne disparait pas. Il monte en altitude : il valide la **décomposition** (est-ce le bon
découpage du problème ?) et arbitre le **goût** là où la machine ne peut pas trancher (close calls
d'architecture, scope borderline). Le reste (correctness, complétude, qualité de revue) devient
une affaire d'essaim d'agents qui se vérifient mutuellement.

---

## 5. Architecture cible : l'Org d'ingénierie virtuelle

Trois couches. Chacune correspond à un rôle d'une vraie équipe.

```
   PRD / feature / epic
          |
          v
  +-------------------------------------------------------------+
  |  COUCHE 1 : DECOMPOSITION  (le "Staff Engineer + EM")       |
  |  PRD -> graphe d'issues dimensionnées + vagues             |
  |  -> panel de juges (complétude, sizing, dépendances)       |
  |  -> [GATE org] l'humain valide le graphe                   |
  |  -> issues GitHub réelles créées via issue-triage          |
  +-------------------------------------------------------------+
          |
          v  (vague 1, vague 2, ... selon dépendances)
  +-------------------------------------------------------------+
  |  COUCHE 2 : EXECUTION EN ESSAIM  (la "Squad")              |
  |  N issues en parallele, chacune dans son worktree          |
  |  cycle de vie dense : Shape -> Build -> Verify -> Ship     |
  |  pipeline sans barriere (issue A en Build pendant que      |
  |  issue B est encore en Shape)                              |
  +-------------------------------------------------------------+
          |
          v
  +-------------------------------------------------------------+
  |  COUCHE 3 : REVUE TRES HAUTE QUALITE  (la "Quality Guild") |
  |  fan-out par dimension -> findings                         |
  |  -> verif adversariale (vote de sceptiques)               |
  |  -> loop-until-dry (jusqu'a 2 rounds sans rien de neuf)    |
  |  -> critique de complétude                                 |
  |  -> Conventional Comments + verdict avec confiance         |
  +-------------------------------------------------------------+
```

### 5.1 Couche 1 : Décomposition (la fonctionnalité phare que tu demandes)

C'est le "donner un PRD et qu'il le décompose comme une équipe l'aurait fait".

**Entrée** : un fichier PRD (markdown), une description de feature riche, ou un epic GitHub existant.
Peut inclure des images (maquettes) grâce à la vision haute résolution de Fable.

**Processus** :

1. **Cartographie** (Fable, effort high) : un agent "Principal Engineer" lit le PRD + scanne le
   codebase (glob/grep ciblés, le 1M permet de tenir beaucoup) -> note les surfaces affectées,
   les contraintes existantes, les ADR pertinents (dont l'ADR axial via `axial-adr-review`).
2. **Décomposition** (Fable, effort xhigh, sortie structurée) : produit un **graphe d'issues** :
   - noeuds : `{ title, problem_statement, tier (S|F-lite|F-full), acceptance_seed[],
     affected_surfaces[], estimate }`
   - arêtes : `blocks` / `blocked_by` (dépendances)
   - vagues : partition topologique du graphe (quelles issues peuvent tourner ensemble)
3. **Panel de juges** (parallèle) : 2 à 3 agents évaluent la décomposition sous des angles distincts :
   - **Complétude** (product-lead) : est-ce que tout le PRD est couvert ? Rien d'orphelin ?
   - **Dimensionnement** (architect) : pas de méga-issue ? Pas de sur-découpage ?
   - **Dépendances** (architect) : le graphe est-il acyclique ? Les vagues sont-elles correctes ?
   - **Piège d'axe** (axial-adr-review) : la découpe respecte-t-elle l'axe de décomposition du repo ?
4. **Synthèse** : un graphe final consolidé.
5. **[GATE org]** : l'humain voit le graphe (table + diagramme mermaid des dépendances) et valide,
   ajuste, ou rejette. C'est le gate le plus important de tout le système.
6. **Matérialisation** : création des issues GitHub réelles + epic parent via `issue-triage`,
   avec les labels de tier, les liens parent/enfant et blocked-by.

**Sortie** : artifact `artifacts/forge/{epic-slug}/graph.mdx` (le graphe, source de vérité d'état) +
issues GitHub.

### 5.2 Couche 2 : Exécution en essaim (la Squad)

Une fois le graphe validé, `/forge` exécute **vague par vague**. Dans une vague, toutes les issues
non bloquées tournent en parallèle, chacune dans son worktree, à travers le cycle dense (section 6).

Clé : c'est un **pipeline sans barrière** (pattern `pipeline()` du Workflow). L'issue A peut être en
phase Build pendant que l'issue B est encore en Shape. On ne synchronise pas inutilement.

Le worktree par issue reprend exactement la mécanique actuelle (`worktree-setup-checklist.md`), donc
zéro réinvention sur ce point. La nouveauté est l'**ordonnancement par vagues dépendance-aware** et
un **agent de détection de conflits** qui surveille si deux issues d'une même vague touchent les
mêmes fichiers (et, si oui, les sérialise ou alerte).

### 5.3 Couche 3 : Revue de très haute qualité (la Quality Guild)

C'est le "revues de très haute qualité avec tous les agents de revue" que tu demandes. On applique
les patterns de qualité du primitif Workflow de façon explicite :

1. **Fan-out par dimension** : un agent reviewer par dimension, en réutilisant les agents existants :
   - correctness (architect / backend-dev / frontend-dev selon le domaine)
   - sécurité (security-auditor)
   - architecture et dérive d'axe (axial-adr-review)
   - tests et couverture (tester)
   - docs (doc-writer)
   - perf (architect)
2. **Vérification adversariale** : chaque finding part vers N sceptiques (3) dont la consigne est de
   **réfuter** le finding. Un finding ne devient bloquant que s'il survit au vote majoritaire. Cela
   tue les faux positifs (un vrai problème sur Fable d'après la doc : si on dit "ne signale que le
   high-severity", il filtre trop. On lui dit donc de tout signaler, et on filtre par vote).
3. **Vérification par perspectives diverses** : quand un finding peut échouer de plusieurs façons,
   chaque vérificateur reçoit une lentille distincte (correctness, sécurité, reproductibilité).
4. **Loop-until-dry** : on relance des finders jusqu'à 2 rounds consécutifs sans nouveau finding.
   On déduplique contre l'ensemble des findings déjà vus (et non contre les seuls confirmés, sinon
   ça ne converge jamais).
5. **Critique de complétude** : un dernier agent demande "qu'est-ce qu'on n'a PAS vérifié ?" (une
   modalité non lancée, une affirmation non prouvée, un fichier non lu). Ce qu'il trouve alimente
   le round suivant.
6. **Sortie** : Conventional Comments (même format qu'aujourd'hui) + verdict, mais chaque finding
   porte un **score de confiance** issu du vote. L'humain ne voit que les findings confirmés, triés
   par sévérité et confiance.

Le verdict pilote le merge (comme aujourd'hui via `/code-review` Phase 8), avec la même garde
humaine au merge.

---

## 6. Le cycle de vie dense (4 passes au lieu de 15 étapes)

Par issue, on collapse les 15 micro-étapes en 4 passes denses. On dépense plus de compute par passe
(fan-out, vérif) mais moins de gates humains (1 gate Shape, 1 gate Ship).

| Passe | Absorbe (ancien) | Ce qui se passe | Gate humain |
|-------|------------------|-----------------|-------------|
| **Shape** | triage, recheck, frame, analyze, requirements, spec | Un agent Fable, avec tout le contexte, produit un **dossier de cadrage** unique : problème, contraintes, hors-scope, analyse technique, critères d'acceptation binaires, breadboard, slices. Pour F-full : exploration de code en sous-agents parallèles. | **1 gate** sur le dossier complet (au lieu de 3 gates frame+spec+plan) |
| **Build** | plan, implement, pr | Le plan est émis comme graphe de micro-tâches structuré, puis les agents de domaine fan-out pour implémenter en parallèle dans le worktree. Tests écrits avec le code. PR ouverte. | Pause de compaction optionnelle (comme aujourd'hui) |
| **Verify** | ci-watch, validate, review, fix | L'essaim de revue (couche 3) tourne. CI surveillée. Findings confirmés -> fix ciblés (agent fixer) -> re-revue (max 2 itérations). | Aucun (la vérif adversariale remplace le gate) |
| **Ship** | promote, cleanup | Merge feature -> staging (garde humaine au merge), nettoyage worktree. `promote` vers prod reste standalone. | **Garde au merge** |

Résultat net : **15 étapes -> 4 passes**, **10 gates -> 2 gates + garde merge**, mais avec plus de
compute total et la possibilité de tourner N issues en parallèle.

Le tier reste, mais sa sémantique change : il ne décide plus quelles étapes sauter, il décide
l'**intensité du fan-out** :

| Tier | Sens nouveau | Shape | Build fan-out | Verify (revue) |
|------|--------------|-------|----------------|-----------------|
| `S` (solo) | 1 agent, pas d'essaim | dossier léger, pas de gate | 1 agent | 1 passe, vote simple |
| `F-lite` (pair) | essaim restreint | dossier + gate | 2 a 3 agents | dimensions + vote simple |
| `F-full` (squad) | essaim complet | dossier + gate, exploration parallèle | fan-out complet | adversarial + loop-until-dry + complétude |

---

## 7. Nouveaux skills, agents et artifacts

### 7.1 Nouveau skill orchestrateur : `forge`

```
plugins/dev-core/skills/forge/
├── SKILL.md            # orchestrateur niveau org
├── README.md
├── scripts/
│   ├── decompose.workflow.js   # PRD -> graphe (section 8.1)
│   ├── review-swarm.workflow.js # revue adversariale (section 8.2)
│   └── scan-epic-state.sh      # detection d'etat niveau epic
└── references/
    └── wave-scheduling.md       # ordonnancement par vagues
```

Frontmatter cible (esquisse) :

```yaml
---
name: forge
argument-hint: '[<prd-file> | "feature" | #epic | --resume <epic-slug>]'
description: >-
  Org d'ingenierie virtuelle. Decompose un PRD en graphe d'issues puis les
  construit en essaim parallele avec revue adversariale.
  Triggers: "forge" | "decompose this PRD" | "build this feature" |
  "break this PRD into issues" | "construis cette feature".
version: 0.1.0
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, EnterWorktree, ExitWorktree,
  Task, TaskCreate, TaskUpdate, TaskList, TaskGet, Skill, ToolSearch, Workflow
---
```

Entrées :

```
/forge prd.md            -> decompose le PRD, propose le graphe, [gate], puis execute par vagues
/forge "dark mode"       -> traite comme une feature : mini-decomposition puis execution
/forge #123              -> epic GitHub existant : decompose en enfants
/forge --resume dark-mode -> reprend un epic en cours (re-scan graphe + worktrees + PR)
/forge #123 --issue-only -> decompose et cree les issues, sans construire (s'arreter apres le gate)
```

`/forge #N` sur une **issue unique** doit aussi marcher : il bascule sur le cycle dense (section 6)
sans passer par la décomposition. Cela permet à `/forge` de **subsumer `/dev`** : un point d'entrée
unique pour tout, de l'issue isolée au PRD complet.

### 7.2 Nouveaux agents (ou évolutions)

| Agent | Rôle | Base |
|-------|------|------|
| `principal-engineer` | Décompose le PRD en graphe d'issues | Nouveau (proche de architect + product-lead) |
| `decomposition-judge` | Juge complétude / sizing / dépendances du graphe | Nouveau (peut être product-lead + architect en panel) |
| `conflict-detector` | Surveille les collisions de fichiers entre issues d'une vague | Nouveau (léger, Haiku suffit) |
| `skeptic` | Réfute un finding pour la vérif adversariale | Nouveau (générique, paramétré par lentille) |

Les 12 agents existants sont **conservés tels quels** et réutilisés dans les couches 2 et 3.

### 7.3 Nouveaux artifacts

| Type | Chemin | Question |
|------|--------|----------|
| PRD (entrée) | `artifacts/prds/{slug}.md` | Que veut-on construire (niveau produit) ? |
| Graphe d'epic | `artifacts/forge/{epic-slug}/graph.mdx` | Comment découper et dans quel ordre ? |
| Dossier de cadrage | `artifacts/forge/{epic-slug}/{N}-{slug}-dossier.mdx` | Problème + analyse + spec (fusionnés) |
| État de vague | `artifacts/forge/{epic-slug}/state.mdx` | Quelle issue est dans quelle passe ? |

Le graphe (`graph.mdx`) est la **source de vérité d'état niveau org**, comme les frames/specs le sont
aujourd'hui niveau issue. Frontmatter type :

```mdx
---
title: Notification system
epic: 123
status: draft        # devient "approved" apres le gate org
created: 2026-06-10
waves:
  - [124, 125]       # vague 1 : issues parallelisables
  - [126]            # vague 2 : depend de 124 et 125
---

## Issues
### #124 - Backend: notification storage (F-lite)
...
### #125 - Frontend: notification bell (F-lite)
...
### #126 - E2E: delivery pipeline (F-full, blocked_by: 124, 125)
...

## Dependency graph (mermaid)
```

---

## 8. Implémentations concrètes (scripts Workflow)

Ces scripts utilisent le primitif `Workflow` (orchestration déterministe multi-agents). Ils sont
**illustratifs et prêts à itérer** : la structure est correcte, les prompts sont à affiner. C'est
exactement le genre de code que Fable peut générer et raffiner (section 13).

### 8.1 Décomposition d'un PRD en graphe d'issues

```javascript
export const meta = {
  name: 'forge-decompose',
  description: 'PRD vers graphe d issues (decomposition type equipe) avec panel de juges',
  phases: [
    { title: 'Map', detail: 'lire le PRD et cartographier le codebase' },
    { title: 'Decompose', detail: 'generer le graphe d issues candidat', model: 'fable' },
    { title: 'Judge', detail: 'panel : completude, sizing, dependances, axe' },
    { title: 'Synthesize', detail: 'graphe final consolide + vagues' },
  ],
}

const GRAPH_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    issues: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          ref: { type: 'string' },                 // id temporaire, ex "I1"
          title: { type: 'string' },
          problem_statement: { type: 'string' },
          tier: { type: 'string', enum: ['S', 'F-lite', 'F-full'] },
          acceptance_seed: { type: 'array', items: { type: 'string' } },
          affected_surfaces: { type: 'array', items: { type: 'string' } },
          blocked_by: { type: 'array', items: { type: 'string' } },
        },
        required: ['ref', 'title', 'problem_statement', 'tier',
                   'acceptance_seed', 'affected_surfaces', 'blocked_by'],
      },
    },
  },
  required: ['issues'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    ok: { type: 'boolean' },
    issues_found: { type: 'array', items: { type: 'string' } },
    suggested_changes: { type: 'array', items: { type: 'string' } },
  },
  required: ['ok', 'issues_found', 'suggested_changes'],
}

// args = { prdPath, repoRoot }
phase('Map')
const map = await agent(
  `Lis le PRD dans ${args.prdPath}. Cartographie le codebase a ${args.repoRoot} :
   surfaces affectees, contraintes existantes, ADR pertinents (cherche un ADR
   axial = frontmatter axial:true). Rends une note de cadrage technique dense.`,
  { label: 'map', phase: 'Map' }
)

phase('Decompose')
const draft = await agent(
  `A partir de cette note de cadrage et du PRD, decompose en graphe d issues
   comme une equipe de dev experimentee le ferait. Regles :
   - chaque issue est independamment livrable (slice verticale)
   - pas de mega-issue (>2 jours) ni de sur-decoupage (<2h)
   - criteres d acceptation binaires (passe ou echoue)
   - dependances explicites via blocked_by (refs d issues)
   Note de cadrage :\n${map}`,
  { label: 'decompose', phase: 'Decompose', model: 'fable', schema: GRAPH_SCHEMA }
)

phase('Judge')
const lenses = [
  { key: 'completeness', prompt: 'Tout le PRD est-il couvert ? Quelque chose d orphelin ?' },
  { key: 'sizing', prompt: 'Y a-t-il une mega-issue ou un sur-decoupage ?' },
  { key: 'dependencies', prompt: 'Le graphe blocked_by est-il acyclique et correct ?' },
  { key: 'axis', prompt: 'La decoupe respecte-t-elle l axe de decomposition du repo (ADR axial) ?' },
]
const verdicts = await parallel(
  lenses.map(l => () =>
    agent(
      `Juge cette decomposition sous l angle "${l.key}" : ${l.prompt}
       Graphe :\n${JSON.stringify(draft, null, 2)}`,
      { label: `judge:${l.key}`, phase: 'Judge', schema: VERDICT_SCHEMA }
    )
  )
)

phase('Synthesize')
const problems = verdicts.filter(Boolean).filter(v => !v.ok)
const final = problems.length === 0
  ? draft
  : await agent(
      `Consolide le graphe en corrigeant ces problemes detectes par le panel :
       ${JSON.stringify(problems, null, 2)}
       Graphe initial :\n${JSON.stringify(draft, null, 2)}`,
      { label: 'synthesize', phase: 'Synthesize', model: 'fable', schema: GRAPH_SCHEMA }
    )

// Partition topologique en vagues (code pur, pas un agent)
const byRef = Object.fromEntries(final.issues.map(i => [i.ref, i]))
const waves = []
const placed = new Set()
while (placed.size < final.issues.length) {
  const wave = final.issues
    .filter(i => !placed.has(i.ref))
    .filter(i => i.blocked_by.every(b => placed.has(b)))
    .map(i => i.ref)
  if (wave.length === 0) { log('CYCLE detecte dans blocked_by - arret'); break }
  wave.forEach(r => placed.add(r))
  waves.push(wave)
}

return { graph: final, waves }
```

L'orchestrateur `forge` appelle ce workflow, présente le graphe + les vagues à l'humain via DP(A)
(le gate org), puis matérialise les issues GitHub via `issue-triage`.

### 8.2 Revue adversariale (la Quality Guild)

```javascript
export const meta = {
  name: 'review-swarm',
  description: 'Revue multi-dimensions avec verification adversariale et loop-until-dry',
  phases: [
    { title: 'Find', detail: 'un finder par dimension' },
    { title: 'Verify', detail: 'sceptiques qui tentent de refuter chaque finding' },
  ],
}

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['blocking', 'issue', 'suggestion', 'nitpick'] },
          title: { type: 'string' },
          rationale: { type: 'string' },
        },
        required: ['file', 'line', 'severity', 'title', 'rationale'],
      },
    },
  },
  required: ['findings'],
}

const REFUTE_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { refuted: { type: 'boolean' }, reason: { type: 'string' } },
  required: ['refuted', 'reason'],
}

// args = { diffRef, dimensions, maxDryRounds }
const DIMENSIONS = args.dimensions ?? [
  { key: 'correctness', prompt: 'Bugs de logique, cas limites, erreurs de correctness.' },
  { key: 'security',    prompt: 'OWASP, secrets, injection, frontieres de confiance.' },
  { key: 'tests',       prompt: 'Couverture manquante, tests fragiles, pyramide.' },
  { key: 'arch',        prompt: 'Derive d axe, couplage, violations d architecture.' },
  { key: 'perf',        prompt: 'N+1, allocations, requetes non bornees.' },
  { key: 'docs',        prompt: 'Docs et references obsoletes apres ce diff.' },
]

const seen = new Set()
const confirmed = []
const key = f => `${f.file}:${f.line}:${f.title}`
let dry = 0

while (dry < (args.maxDryRounds ?? 2)) {
  // 1. Fan-out par dimension (barriere : on collecte tout avant de verifier)
  const rounds = await parallel(
    DIMENSIONS.map(d => () =>
      agent(
        `Revois le diff ${args.diffRef} sous l angle "${d.key}" : ${d.prompt}
         Signale TOUT, meme incertain ou low-severity. Un filtre aval triera.`,
        { label: `find:${d.key}`, phase: 'Find', schema: FINDINGS_SCHEMA }
      )
    )
  )
  const fresh = rounds.filter(Boolean)
    .flatMap(r => r.findings)
    .filter(f => !seen.has(key(f)))

  if (fresh.length === 0) { dry++; continue }
  dry = 0
  fresh.forEach(f => seen.add(key(f)))

  // 2. Verification adversariale : 3 sceptiques par finding, lentilles diverses
  const judged = await parallel(
    fresh.map(f => () =>
      parallel(['correctness', 'repro', 'severity'].map(lens => () =>
        agent(
          `Tente de REFUTER ce finding via la lentille "${lens}". Par defaut
           refuted=true si tu n es pas convaincu. Finding :\n${JSON.stringify(f)}`,
          { label: `verify:${f.file}`, phase: 'Verify', schema: REFUTE_SCHEMA }
        )
      )).then(votes => {
        const survives = votes.filter(Boolean).filter(v => !v.refuted).length >= 2
        return survives ? f : null
      })
    )
  )
  confirmed.push(...judged.filter(Boolean))
}

return { confirmed }
```

Le skill `code-review` (ou une variante `code-review --swarm`) appelle ce workflow, formate les
findings confirmés en Conventional Comments, et émet le verdict.

### 8.3 Pipeline d'exécution en vagues (esquisse)

```javascript
export const meta = {
  name: 'forge-execute-wave',
  description: 'Execute une vague d issues en pipeline sans barriere (Shape -> Build -> Verify)',
  phases: [{ title: 'Shape' }, { title: 'Build' }, { title: 'Verify' }],
}

// args = { issues: [{ number, slug, tier }] }
// Chaque issue traverse les 3 passes independamment (pipeline, pas de barriere).
// Build s execute en worktree isole -> isolation: 'worktree' sur l agent Build.
const results = await pipeline(
  args.issues,
  // Shape : un dossier de cadrage dense (frame+analyze+spec fusionnes)
  (issue) => agent(
    `Produis le dossier de cadrage pour l issue #${issue.number} (tier ${issue.tier}) :
     probleme, contraintes, hors-scope, analyse, criteres d acceptation binaires,
     breadboard, slices. Ecris-le dans artifacts/forge/.../${issue.number}-dossier.mdx`,
    { label: `shape:#${issue.number}`, phase: 'Shape',
      model: issue.tier === 'F-full' ? 'fable' : undefined }
  ).then(() => issue),
  // Build : plan + implement + PR, en worktree isole
  (issue) => agent(
    `Implemente l issue #${issue.number} a partir de son dossier de cadrage.
     Cree le worktree, ecris code + tests, ouvre la PR. Delegue aux agents de domaine.`,
    { label: `build:#${issue.number}`, phase: 'Build', isolation: 'worktree' }
  ).then(() => issue),
  // Verify : la Quality Guild (appelle review-swarm en sous-workflow)
  (issue) => workflow('review-swarm', { diffRef: `pr-for-${issue.number}` })
    .then(r => ({ issue, review: r }))
)

return results.filter(Boolean)
```

Note : un `parallel()` (barrière) est correct **entre deux vagues** (la vague 2 dépend de toute la
vague 1), mais **à l'intérieur d'une vague** on reste en `pipeline()` sans barrière. C'est le bon
usage du primitif.

---

## 9. Sélection de modèle par rôle

Fable coûte 10/50 $ par MTok (2x Opus en sortie). Un fan-out naïf de 16 agents Fable serait cher.
La règle : **Fable sur les rôles à fort levier, des modèles moins chers pour le fan-out de masse.**

| Rôle | Modèle | Pourquoi |
|------|--------|----------|
| Décomposition du PRD (principal-engineer) | **Fable** | Décision la plus structurante. Qualité = tout le reste en dépend |
| Synthèse de graphe | **Fable** | Cohérence globale critique |
| Shape d'une issue F-full | **Fable** | Cadrage profond, multi-domaine |
| Shape d'une issue S / F-lite | Opus 4.8 | Suffisant, moins cher |
| Build / implémentation | Opus 4.8 (`effort xhigh`) | Le sweet spot coding selon la doc |
| Finders de revue (dimensions) | Opus 4.8 | Bonne détection de bugs, volume modéré |
| Sceptiques (vérif adversariale) | Haiku 4.5 ou Sonnet 4.6 | Tâche bornée (réfuter un finding), fort volume |
| Détecteur de conflits | Haiku 4.5 | Tâche mécanique (collision de fichiers) |
| Juges de décomposition | Opus 4.8 | Jugement sans être le générateur |

Dans le primitif Workflow, le modèle par défaut d'un agent est celui de la boucle principale (donc
Fable si tu lances `/forge` sous Fable). On surcharge avec `model:` uniquement là où on est sûr.
Combiné aux **Task Budgets** (borne du coût d'un essaim) et au **cache** (préfixe minimal 2048 sur
Fable, donc les petits prompts d'essaim cachent bien), le coût reste maitrisable.

Garde-fou coût : le tier `S` saute l'essaim entièrement (1 agent, revue mono-passe). On ne paie le
fan-out adversarial que sur `F-full`.

---

## 10. Mapping ancien vers nouveau

| Ancien (`/dev`) | Nouveau (`/forge`) | Devenir |
|------------------|---------------------|---------|
| `/dev #N` | `/forge #N` | Conservé : bascule sur cycle dense |
| triage | matérialisation du graphe (issue-triage) | Réutilisé |
| recheck | recheck (début de Shape) | Conservé |
| frame + analyze + spec | passe **Shape** (dossier unique) | Fusionnés |
| requirements | section du dossier Shape | Absorbé |
| plan + implement | passe **Build** (graphe de tâches + fan-out) | Fusionnés |
| pr | fin de Build | Conservé |
| ci-watch + validate + review + fix | passe **Verify** (essaim adversarial) | Fusionnés + renforcés |
| promote + cleanup | passe **Ship** | Conservé |
| (rien) | couche **Décomposition** (PRD -> graphe) | **Nouveau** |
| (rien) | ordonnancement par **vagues** | **Nouveau** |
| code-review mono-passe | review-swarm adversarial | Renforcé |

Skills conservés tels quels et appelés par `/forge` : `issue-triage`, `recheck`, `pr`, `ci-watch`,
`validate`, `fix`, `promote`, `cleanup`, `adr`, `doc-sync`. Agents : les 12 existants.

`/dev` peut rester comme **alias** vers `/forge #N` pendant une période de transition, puis être
déprécié une fois `/forge` éprouvé.

---

## 11. Plan d'action par phases

Chaque phase est livrable et testable indépendamment. On construit le nouveau système avec le
plugin lui-même (dogfooding).

### Phase 0 : Fondations (1 à 2 jours)
- [ ] Créer `skills/forge/` (squelette SKILL.md + README).
- [ ] Ajouter les dossiers d'artifacts : `artifacts/prds/`, `artifacts/forge/`.
- [ ] Définir les schémas JSON (graphe, findings, verdict) dans `references/`.
- [ ] Écrire `references/wave-scheduling.md` (algorithme de partition topologique).
- **Livrable** : structure en place, rien d'exécutable encore.

### Phase 1 : Couche Décomposition (le coeur de ta demande) (2 à 3 jours)
- [ ] Écrire `decompose.workflow.js` (section 8.1).
- [ ] Implémenter le gate org dans `forge` SKILL.md (DP(A) sur le graphe + mermaid).
- [ ] Brancher la matérialisation des issues via `issue-triage`.
- [ ] Tester sur un vrai PRD (par ex. un doc de `docs/` du repo).
- **Livrable** : `/forge prd.md --issue-only` produit un graphe validé + des issues GitHub.

### Phase 2 : Revue de très haute qualité (2 à 3 jours)
- [ ] Écrire `review-swarm.workflow.js` (section 8.2).
- [ ] Variante `/code-review --swarm` qui l'appelle et formate en Conventional Comments.
- [ ] Calibrer : largeur de dimensions, nombre de sceptiques, seuil de vote, rounds dry.
- **Livrable** : revue adversariale autonome, branchable sur une PR existante.

### Phase 3 : Cycle dense par issue (3 à 4 jours)
- [ ] Implémenter les 4 passes (Shape/Build/Verify/Ship) dans `forge`.
- [ ] Réutiliser worktrees, gates Shape/Ship, garde merge.
- [ ] Brancher Verify sur review-swarm (Phase 2).
- **Livrable** : `/forge #N` construit une issue de bout en bout via le cycle dense.

### Phase 4 : Exécution en essaim (vagues) (3 à 4 jours)
- [ ] Écrire `forge-execute-wave.workflow.js` (section 8.3, pipeline sans barrière).
- [ ] Ajouter `conflict-detector` (collisions de fichiers intra-vague).
- [ ] Ordonnancement vague par vague (barrière entre vagues).
- [ ] État niveau epic (`state.mdx`) + reprise (`--resume`).
- **Livrable** : `/forge prd.md` décompose ET construit, vague par vague, en parallèle.

### Phase 5 : Sélection de modèle et coût (1 à 2 jours)
- [ ] Appliquer la table de la section 9 (model overrides par rôle).
- [ ] Brancher les Task Budgets sur les essaims longs.
- [ ] Mesurer le coût réel sur un epic complet, ajuster.
- **Livrable** : coût par epic instrumenté et maitrisé.

### Phase 6 : Transition et docs (1 à 2 jours)
- [ ] `/dev` devient alias de `/forge #N`.
- [ ] Mettre à jour README plugin + CLAUDE.md.
- [ ] `doc-sync` sur tout le plugin.
- **Livrable** : un point d'entrée unique, documenté.

Total indicatif : **2 à 3 semaines** de travail effectif, livrable en continu.

---

## 12. Risques et mitigations

| Risque | Gravité | Mitigation |
|--------|---------|------------|
| Conflits de merge entre issues parallèles d'une vague | Élevée | Ordonnancement dépendance-aware + `conflict-detector` + worktrees isolés. Sérialiser les issues qui touchent les mêmes fichiers. |
| Moins de gates = dérive par rapport à l'intention | Moyenne | Gate org plus riche (graphe complet) + dossier Shape gaté + vérif adversariale qui rattrape les écarts |
| Coût du fan-out | Moyenne | Tiérage modèle (section 9), tier S sans essaim, Task Budgets, cache |
| Décomposition LLM non déterministe | Moyenne | Panel de juges + gate humain obligatoire sur le graphe |
| Findings faux positifs noient l'humain | Moyenne | Vote adversarial de sceptiques : seuls les findings confirmés remontent |
| Essaim long qui se perd (overnight) | Moyenne | Vagues courtes, re-scan d'état entre vagues, resume Workflow, compaction |
| Régression vs l'existant | Faible | Design additif : `/dev` reste, `/forge #N` retombe sur le cycle dense, dégradation prévue (section 2.3) |
| Filtrage de sévérité trop agressif de Fable en revue | Faible | Documenté : on dit "signale tout", on filtre par vote en aval (pas par auto-censure du finder) |

---

## 13. Construire ce plugin AVEC Fable (méta)

Le plugin sait s'auto-construire. La bonne façon de bâtir `/forge` est d'utiliser le cycle existant
pour le faire, puis de basculer.

1. **Ce document EST le PRD.** Une fois que tu valides l'approche, on peut faire :
   `/dev "construire le skill forge - couche decomposition"` pour la Phase 1, etc.
2. **Dogfooding progressif.** Dès que `/forge --issue-only` marche (Phase 1), on l'utilise pour
   décomposer les phases suivantes en issues.
3. **Fable comme constructeur.** Les scripts Workflow de la section 8 sont conçus pour être générés
   et raffinés par Fable : ils sont structurés, avec schémas, prompts explicites, et patterns de
   qualité. Lance la construction sous Fable (`effort xhigh`) avec la spec complète en un seul tour
   (c'est le mode où Fable excelle selon la doc : long-horizon, goal clair en entrée).
4. **Spec en entrée, pas en goutte-à-goutte.** Fable est plus autonome quand on lui donne tout le
   cadrage d'emblée. Donc : un dossier Shape complet par phase, plutôt que des allers-retours.

---

## 14. Décisions ouvertes (à trancher avec toi)

Ce sont les vrais choix de goût que je ne tranche pas à ta place.

1. **Nom de l'orchestrateur.** Je propose `/forge`. Alternatives : `/squad`, `/atelier` (clin d'oeil
   francophone), `/kamanga` (entrée de marque). Le nom du dossier d'artifact suit (`artifacts/forge/`).

2. **`/forge` remplace-t-il `/dev`, ou cohabitent-ils ?** Recommandation : cohabitation puis `/dev`
   devient alias de `/forge #N`, dépréciation douce. Tu peux préférer un remplacement net.

3. **Largeur d'essaim par défaut.** Combien d'agents par dimension de revue, combien de sceptiques
   (je propose 6 dimensions, 3 sceptiques, vote majoritaire à 2/3). Plus = plus sûr et plus cher.

4. **Niveau d'autonomie au merge.** Le merge feature -> staging garde une garde humaine. Veux-tu une
   option "auto-merge si verdict vert et CI verte" pour les tiers S/F-lite ?

5. **Budget par défaut.** Faut-il un plafond de tokens par epic (Task Budget) imposé par défaut, ou
   au cas par cas ?

6. **Décomposition : issues GitHub réelles dès le gate, ou graphe en artifact d'abord ?** Je propose
   de matérialiser les issues GitHub seulement APRÈS le gate org (le graphe vit en artifact avant).

---

## Annexe A : invariants préservés (rien ne casse côté garde-fous)

- Worktrees isolés, jamais de code sur staging sans branche.
- Pas de `--force` / `--hard` / `--amend`.
- Protocole DP pour toute décision (jamais AskUserQuestion directement, conformément au plugin).
- Conventional Comments pour les findings.
- Artifacts comme source de vérité d'état (étendus au niveau epic).
- Délégation orchestrateur -> agents de domaine.
- `bun run test` (Vitest), jamais `bun test`.

## Annexe B : schéma mental du flux complet

```
PRD ──► [Map] ──► [Decompose:Fable] ──► [Judge panel] ──► [GATE org]
                                                              │
                                                  issues GitHub + graph.mdx
                                                              │
                              ┌───────────── vague 1 ─────────┴──── vague 2 ──────┐
                              │  #124        #125                    #126          │
                              │  Shape       Shape                   (bloquee)     │
                              │   │ [gate]    │ [gate]                             │
                              │  Build       Build                                │
                              │   │ worktree  │ worktree                          │
                              │  Verify      Verify                               │
                              │   │ swarm     │ swarm                             │
                              │  Ship        Ship ───────────────► Shape #126 ... │
                              └────────────────────────────────────────────────────┘
                                                              │
                                              merge ──► staging  (garde humaine)
                                                              │
                                                       /promote (standalone) ──► prod
```
