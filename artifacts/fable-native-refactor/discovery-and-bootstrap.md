# Forge : couche Discovery (cadrage amont) et couche Bootstrap (préparation du terrain)

> Compagnon de [README.md](./README.md). Ce document étend l'architecture en 3 couches du
> README avec deux couches supplémentaires :
>
> - **Couche 0 (Discovery / Shaping)** : étudier, regarder le passé, challenger le présent,
>   analyser le risque et proposer plusieurs solutions, AVANT de décomposer et de construire.
> - **Couche -1 (Bootstrap)** : préparer le terrain (init projet, CI, github, releases, ADR axial,
>   docs) et rendre l'orchestrateur project-aware.
>
> Date : 2026-06-10. Cible d'édition : `kamanga-plugins/plugins/dev-core`.

---

## 0. La pile complète (révisée)

Le README présentait 3 couches (Décomposition, Exécution, Revue). Avec tes deux ajouts, la pile
complète de `/forge` devient :

```
   idee | feature | PRD
          |
   [ -1 ] BOOTSTRAP / readiness ........ le terrain est-il pret ? (init, CI, github, ADR axial, docs)
          |
   [  0 ] DISCOVERY / SHAPING ........... etudier, passe, present, risque, shapes  [GATE concept]
          |
   [  1 ] DECOMPOSITION ................. concept -> graphe d issues + vagues       [GATE org]
          |
   [  2 ] EXECUTION EN ESSAIM ........... vagues paralleles, cycle dense par issue  [GATE shape/issue]
          |
   [  3 ] REVUE TRES HAUTE QUALITE ...... swarm adversarial, loop-until-dry
          |
        merge -> staging  (garde humaine)  ->  /promote (standalone) -> prod
```

Deux remarques de principe :

1. **Discovery (0) peut conclure "ne construis pas ça".** C'est volontaire. L'orchestrateur doit
   pouvoir challenger la demande, pas seulement l'exécuter. C'est l'esprit "office hours / CEO review".
2. **Bootstrap (-1) nourrit les couches suivantes.** L'ADR axial décidé au bootstrap est exactement
   ce que le juge "piège d'axe" de la décomposition (couche 1) utilise. Mieux le terrain est préparé,
   meilleure est la décomposition. C'est une boucle vertueuse.

---

## 1. Couche 0 : Discovery / Shaping (le cadrage amont)

### 1.1 Tes 4 attentes, mappées à l'existant et à Fable

| Ton attente | Skill existant qui le fait | Version Fable-native (couche 0) |
|-------------|-----------------------------|----------------------------------|
| Étudier la demande / l'idée | `interview` (brainstorm divergent, Shape Up) | Interview humain pour l'**intention**, puis fan-out d'agents |
| Regarder ce qui a été fait (passé) | interview Step 1 + analyze 2a + git | **Éclaireurs de prior-art** parallèles (multi-modal sweep) |
| Challenger par rapport au présent | analyze "Fit Check" + alignement contraintes + `recheck` | **Panel de challenge** adversarial (avocat du diable) |
| Analyse de risque + plusieurs solutions | analyze "Shapes" (2-3 approches + trade-offs + spike) | **Tournoi de shapes** + matrice de risque + panel de juges |

Le skill `interview` actuel est un Q&A **linéaire** (un intervieweur, des phases). Fable ne remplace
pas l'interview humain (c'est là que tu donnes l'intention), il **l'entoure** d'essaims qui font le
travail d'investigation que ferait une équipe : des gens qui fouillent l'historique, des gens qui
challengent, des gens qui proposent des approches concurrentes.

### 1.2 Les 4 sous-étapes de Discovery

```
                    intention humaine (mini-interview, 3-4 questions)
                                   |
        +--------------------------+---------------------------+
        |                          |                           |
   [A] ETUDIER             [B] PASSE                    [C] PRESENT
   brainstorm divergent    eclaireurs prior-art         panel de challenge
   (1 agent + humain)      (sweep multi-modal)          (avocats du diable)
        |                          |                           |
        +--------------------------+---------------------------+
                                   |
                          [D] SHAPES + RISQUE
                   tournoi de N approches mutuellement exclusives
                   -> panel de juges -> matrice de risque -> reco
                                   |
                          [GATE concept] l humain tranche
                                   |
                   concept vise (PRD-candidat ou frame unique)
                                   -> couche 1 (decomposition)
```

#### [A] Étudier (brainstorm divergent)

Un mini-interview humain (3 a 4 questions Shape Up : qu'est-ce qui a déclenché ça ? quel est le
problème vs la solution ? quel appétit ?), puis un agent diverge (brainstorm) pour élargir l'espace
des possibles. C'est exactement le `interview` type β actuel, gardé tel quel mais alimenté ensuite
par B et C.

#### [B] Regarder le passé (éclaireurs de prior-art, en parallèle)

Pattern "multi-modal sweep" : plusieurs éclaireurs cherchent **chacun d'une façon différente**,
aveugles les uns aux autres. Chacun répond à "qu'est-ce qui a déjà été fait / tenté / décidé ?" :

| Éclaireur | Cherche dans | Répond à |
|-----------|--------------|----------|
| historien-git | `git log`, commits, blame | A-t-on déjà touché ça ? Quand, pourquoi ? |
| archiviste-issues | issues/PR fermées (gh) | A-t-on déjà tenté ça ? Pourquoi abandonné ? |
| archiviste-artifacts | `artifacts/` (frames, specs, analyses, ADR) | A-t-on déjà cadré ça ? Une décision existe-t-elle ? |
| cartographe-code | glob/grep ciblés du codebase | Existe-t-il déjà une implémentation proche à réutiliser ? |
| lecteur-docs | `docs/`, README, CLAUDE.md | Y a-t-il une contrainte documentée pertinente ? |

Sortie : une **note de prior-art** consolidée. Évite le piège classique "réinventer ce qui existe"
ou "refaire une erreur déjà faite". C'est là que le 1M de contexte de Fable paie : un agent peut
tenir beaucoup d'historique d'un coup.

#### [C] Challenger le présent (panel d'avocats du diable)

Pattern adversarial. Des agents challengent la demande **contre l'état présent du projet**. Chacun
a une lentille distincte. Le but n'est pas de valider, c'est de **trouver pourquoi ne pas faire** :

| Challenger | Question forçante |
|------------|-------------------|
| problème-réel | Est-ce le vrai problème, ou un symptôme ? (Mom Test, JTBD) |
| duplication | Est-ce que ça duplique une capacité existante ? (utilise la note de prior-art) |
| axe | Est-ce que ça combat l'axe de décomposition du repo (ADR axial) ? (axial-adr-review) |
| wedge | Quel est le plus petit incrément qui crée de la valeur ? Faut-il tout faire ? |
| coût-présent | Le code actuel supporte-t-il ça, ou ça force un refacto caché ? (rabbit holes Shape Up) |

Sortie : une **note de challenge** (objections classées par sévérité). Si les objections sont
fortes, Discovery peut recommander de **réduire le scope, reformuler, ou ne pas faire**. L'orchestrateur
gagne le droit de dire non, comme une bonne équipe le ferait.

#### [D] Shapes + analyse de risque (tournoi d'approches)

Reprend les "Shapes" de `analyze` (2-3 approches mutuellement exclusives), mais en **tournoi** :

1. **Génération** (Fable, effort xhigh) : produit N approches concurrentes (par ex. MVP-first,
   robustesse-first, réutilisation-first), chacune avec description, trade-offs, scope grossier.
2. **Spikes optionnels** (worktrees jetables) : pour les inconnues techniques, un agent teste une
   hypothèse dans un worktree throwaway (exactement le flux `analyze` Step 2.5), puis le jette.
3. **Matrice de risque** par shape : chaque risque coté Impact x Probabilité (H/M/L), avec mitigation.
4. **Panel de juges** (parallèle, Opus) : note chaque shape sur faisabilité, fit aux contraintes,
   coût, risque. Pattern "judge panel".
5. **Synthèse** : recommande une shape, en **greffant les meilleures idées** des shapes perdantes.

Sortie : un **concept visé** (la shape retenue + sa matrice de risque + ce qui est hors-scope).

### 1.3 Le gate concept

L'humain voit : le problème reformulé, la note de prior-art (ce qui existe), la note de challenge
(les objections), les shapes avec leur risque, et la recommandation. Il tranche via DP(A) :
**Adopter la shape recommandée** | **Choisir une autre shape** | **Réduire le scope** | **Ne pas faire**.

C'est un gate de **goût et de stratégie**, distinct du gate org (couche 1) qui porte sur le découpage.

### 1.4 Ce que Discovery produit, et comment ça branche sur le reste

- Petite idée (tier S/F-lite) : Discovery produit un **frame unique** (le dossier de cadrage de la
  passe Shape). Pas de décomposition. On passe direct au cycle dense (couche 2).
- Grosse idée / PRD (F-full) : Discovery produit (ou affûte) un **PRD-candidat** + le concept visé,
  qui alimente la **décomposition** (couche 1). Le PRD validé en Discovery est un bien meilleur
  intrant pour le graphe d'issues.

La promotion de `interview` (brainstorm β -> analysis α -> spec σ) est conservée comme échelle de
maturité du document. Discovery est la version multi-agents de cette montée en maturité.

### 1.5 Esquisse de workflow : Discovery

```javascript
export const meta = {
  name: 'forge-discovery',
  description: 'Cadrage amont : etudier, prior-art, challenge, shapes + risque',
  phases: [
    { title: 'PriorArt', detail: 'eclaireurs paralleles sur le passe' },
    { title: 'Challenge', detail: 'panel adversarial sur le present' },
    { title: 'Shapes', detail: 'tournoi d approches + matrice de risque', model: 'fable' },
    { title: 'Judge', detail: 'panel note les shapes' },
  ],
}

// args = { intent, repoRoot }  (intent = sortie du mini-interview humain)

// [B] Passe : eclaireurs multi-modaux (barriere : on veut tout avant de challenger)
phase('PriorArt')
const scouts = [
  { k: 'git',      p: 'Cherche dans git log/blame ce qui a deja touche ce domaine.' },
  { k: 'issues',   p: 'Cherche issues/PR fermees liees (gh). Pourquoi abandonnees ?' },
  { k: 'artifacts',p: 'Cherche frames/specs/analyses/ADR existants lies.' },
  { k: 'code',     p: 'Cherche une implementation proche reutilisable (glob/grep).' },
  { k: 'docs',     p: 'Cherche contraintes documentees pertinentes (docs/CLAUDE.md).' },
]
const priorArt = await parallel(
  scouts.map(s => () => agent(
    `Intention : ${args.intent}\nRepo : ${args.repoRoot}\n${s.p}`,
    { label: `scout:${s.k}`, phase: 'PriorArt', model: 'haiku' }
  ))
)

// [C] Present : panel de challenge adversarial
phase('Challenge')
const lenses = [
  { k: 'real-problem', p: 'Est-ce le vrai probleme ou un symptome ?' },
  { k: 'duplication',  p: 'Est-ce que ca duplique une capacite existante ?' },
  { k: 'axis',         p: 'Est-ce que ca combat l ADR axial du repo ?' },
  { k: 'wedge',        p: 'Quel est le plus petit increment de valeur ?' },
  { k: 'hidden-cost',  p: 'Le code actuel force-t-il un refacto cache (rabbit hole) ?' },
]
const challenges = await parallel(
  lenses.map(l => () => agent(
    `Intention : ${args.intent}\nPrior-art :\n${JSON.stringify(priorArt)}\n` +
    `Challenge "${l.k}" : ${l.p} Cherche pourquoi NE PAS faire, ou faire plus petit.`,
    { label: `challenge:${l.k}`, phase: 'Challenge' }
  ))
)

// [D] Shapes : tournoi + matrice de risque (Fable), puis panel de juges (Opus)
phase('Shapes')
const shapes = await agent(
  `Genere 3 approches mutuellement exclusives pour : ${args.intent}\n` +
  `Tiens compte du prior-art et des challenges :\n` +
  `${JSON.stringify({ priorArt, challenges })}\n` +
  `Pour chaque shape : description, trade-offs, scope grossier, matrice de risque ` +
  `(chaque risque : impact x probabilite H/M/L + mitigation).`,
  { label: 'shapes', phase: 'Shapes', model: 'fable' }
)

phase('Judge')
const scores = await parallel(
  ['faisabilite', 'fit-contraintes', 'cout', 'risque'].map(crit => () => agent(
    `Note chaque shape sur le critere "${crit}" (0-10) avec justification.\n${shapes}`,
    { label: `judge:${crit}`, phase: 'Judge' }
  ))
)

return { priorArt, challenges, shapes, scores }
```

L'orchestrateur présente la synthèse au gate concept, puis route : frame unique (petit) ou
PRD-candidat vers la décomposition (gros).

---

## 2. Couche -1 : Bootstrap (préparation du terrain)

### 2.1 Le problème

Tes skills de bootstrap existent déjà et sont orchestrés par `/init` :

| Skill | Concern |
|-------|---------|
| `env-setup` | stack.yml, règles CLAUDE.md, stubs docs, VS Code, LSP |
| `axial-adr-create` (agent) | ADR de l'axe de décomposition (anti-dérive N x M) |
| `github-setup` | GitHub Project V2, labels, branch protection, workspace |
| `ci-setup` | GitHub Actions, TruffleHog, Dependabot, hooks |
| `release-setup` | Commitizen, commitlint, semantic-release / Release Please |
| `seed-docs` | peuple les stubs de docs depuis CLAUDE.md + codebase |
| `seed-community` | CONTRIBUTING, CODE_OF_CONDUCT, SECURITY |
| `checkup` | health check de toute la config |

Aujourd'hui, `/dev` suppose que le terrain est prêt. Le nouvel orchestrateur doit être
**project-aware** : détecter l'état du projet et préparer le terrain s'il manque quelque chose,
conformément au principe de design n°1 du plugin (project-agnostic, auto-discover).

### 2.2 Intégration : une phase de readiness en tête de `/forge`

```
/forge <entree>
   |
   v
Phase -1 : READINESS (delegue a /checkup)
   |
   +-- vert (projet pret) ----------------------> Discovery (couche 0)
   |
   +-- rouge (manque env / github / CI / ADR axial / docs)
         |
         v
       DP(A) :  Bootstrap maintenant (/init)
              | Continuer en mode degrade (warn)
              | Abort
```

- **Détection** : `/checkup` sait déjà vérifier dev-core, github, CI, stack. On l'utilise comme
  capteur en lecture seule. Il rend un rapport pass/fail par concern.
- **Bootstrap** : si l'humain accepte, on délègue à `/init` (qui orchestre env-setup, axial-adr,
  github-setup, ci-setup, release-setup). `/init` est déjà **idempotent**, donc re-runnable sans danger.
- **Seed** : après init, proposer `/seed-docs` et `/seed-community` (pour un repo OSS).
- **Prépare le terrain forge** : créer aussi les dossiers d'artifacts dont forge a besoin
  (`artifacts/prds/`, `artifacts/forge/`).

Le bootstrap reste **gaté** : on ne lance jamais une config lourde (branch protection, workflows CI)
sans consentement explicite.

### 2.3 Rendre le bootstrap lui-même Fable-native (gains optionnels)

Le bootstrap actuel est surtout des wizards. Fable peut le rendre plus intelligent, sans tout
réécrire :

| Étape bootstrap | Aujourd'hui | Gain Fable-native |
|------------------|-------------|--------------------|
| stack-setup | wizard interactif (langages, frameworks, PM, test runner) | Un agent scanne le repo et **propose** un `stack.yml` pré-rempli, l'humain corrige |
| seed-docs | génère des stubs | Un agent lit le codebase et **rédige** un premier jet de docs (Diátaxis) |
| axial-adr-create | interview (conservé) | **Conservé tel quel** : c'est une décision humaine fondamentale |
| ci-setup | templates | Un agent détecte le stack et **propose** les workflows adaptés |

L'ADR axial mérite une mention spéciale : il devient **doublement important** dans le nouveau monde.
Avant, il prévenait la dérive d'un humain qui code. Maintenant, il **guide la décomposition
automatique** : le juge "piège d'axe" de la couche 1 lit cet ADR pour vérifier que le graphe d'issues
respecte l'axe primaire. Un mauvais ADR axial = une mauvaise décomposition à grande échelle. Donc on
le garde obligatoire (sauf `--skip-axial` pour les projets triviaux), exactement comme `/init`.

### 2.4 Le cycle de vie complet, projet compris

```
[ -1 ] BOOTSTRAP
   readiness (/checkup) -> [DP bootstrap] -> /init (env, axial-adr, github, ci, release)
                                          -> /seed-docs, /seed-community
                                          -> creer artifacts/prds, artifacts/forge
   |
   v
[ 0 ] DISCOVERY  (etudier, passe, present, risque, shapes)  -> [GATE concept]
   |
   v
[ 1 ] DECOMPOSITION  (concept -> graphe + vagues)  -> [GATE org]
   |        ^ le juge "axe" lit l ADR axial produit au bootstrap
   v
[ 2 ] EXECUTION EN ESSAIM  (vagues, cycle dense Shape/Build/Verify/Ship)
   |
   v
[ 3 ] REVUE TRES HAUTE QUALITE  (swarm adversarial)
   |
   v
merge -> staging  ->  /promote -> prod
```

---

## 3. Impact sur le reste de la proposition

### 3.1 Points d'entrée mis à jour de `/forge`

```
/forge                       -> readiness check du projet, propose bootstrap si besoin
/forge "une idee"            -> Discovery (etudier/challenger/shaper) -> (frame ou PRD) -> build
/forge prd.md                -> Discovery affute le PRD -> decomposition -> build par vagues
/forge #N                    -> cycle dense sur une issue existante (subsume /dev)
/forge --shape "une idee"    -> Discovery seule, s arrete au gate concept (ne construit pas)
/forge --bootstrap           -> prepare le terrain uniquement (delegue a /init + seed)
/forge --resume <epic-slug>  -> reprend un epic en cours
```

### 3.2 Sélection de modèle (ajouts à la table du README section 9)

| Rôle (couche 0 / -1) | Modèle | Pourquoi |
|----------------------|--------|----------|
| Éclaireurs de prior-art | Haiku 4.5 | Recherche bornée, fort volume parallèle |
| Panel de challenge | Opus 4.8 | Jugement adversarial de qualité |
| Génération de shapes + risque | **Fable** | Créativité et profondeur des approches |
| Juges de shapes | Opus 4.8 | Notation indépendante du générateur |
| stack-setup / seed-docs (proposition) | Opus 4.8 | Lecture de codebase + rédaction |
| axial-adr-create (interview) | Fable | Décision fondamentale, vaut le meilleur modèle |

### 3.3 Ajouts au plan d'action (README section 11)

- **Phase A — Couche Discovery** (3 a 4 jours) : `forge-discovery.workflow.js` (prior-art sweep +
  challenge panel + shape tournament + judge), gate concept, branchement vers frame ou décomposition.
  Livrable : `/forge --shape "idee"` produit un concept visé challengé et chiffré en risque.
- **Phase B — Couche Bootstrap** (1 a 2 jours) : phase readiness en tête de `/forge` (capteur
  `/checkup`), DP de bootstrap déléguant à `/init`, création des dossiers d'artifacts forge.
  Optionnel : agent de proposition de `stack.yml`. Livrable : `/forge` sur un repo vierge propose
  et exécute le bootstrap, puis enchaine.

Ordre recommandé : Bootstrap (B) et Discovery (A) peuvent se faire tôt, car ils sont en amont et
indépendants du moteur d'essaim. On peut même livrer Discovery avant la décomposition : challenger
et shaper une idée a de la valeur seul.

### 3.4 Décisions ouvertes supplémentaires (à trancher avec toi)

7. **Agressivité du challenge.** Discovery doit-il pouvoir conclure "ne fais pas ça" et bloquer, ou
   seulement avertir ? Je propose : il recommande fortement, mais l'humain garde la décision au gate.
8. **Bootstrap auto ou toujours demandé ?** Je propose : toujours demandé (DP), jamais de config
   lourde sans consentement. Option `--bootstrap-yes` pour les habitués.
9. **Discovery obligatoire ou optionnelle ?** Pour un `#N` déjà cadré, on saute Discovery. Pour une
   idée neuve, elle est recommandée. Faut-il pouvoir la forcer/sauter explicitement (`--no-shape`) ?
10. **stack-setup / seed-docs : agent-propose ou wizard ?** Garder le wizard comme repli, ajouter la
    proposition par agent comme accélérateur.

---

## 4. Synthèse : ce que l'orchestrateur sait faire désormais

En une phrase : `/forge` devient un **partenaire d'ingénierie complet** qui prépare le terrain,
étudie une idée comme une équipe (passé + présent + risque + alternatives), la challenge avant de
s'engager, la décompose en issues, la construit en essaim, et la revoit à très haute qualité.

| Tu demandes | Couche qui le porte |
|-------------|---------------------|
| Étudier une demande / idée | 0 — Discovery [A] brainstorm |
| Regarder ce qui a été fait (passé) | 0 — Discovery [B] éclaireurs de prior-art |
| Challenger par rapport au présent | 0 — Discovery [C] panel de challenge |
| Analyse de risque + plusieurs solutions | 0 — Discovery [D] tournoi de shapes + matrice de risque |
| Bootstrapper le projet (init, CI, github, releases, ADR, docs) | -1 — Bootstrap (readiness + `/init`) |
| Décomposer un PRD en issues | 1 — Décomposition |
| Construire en parallèle | 2 — Exécution en essaim |
| Revue de très haute qualité | 3 — Quality Guild adversariale |
