---
name: kamanga-guide
description: 'Produit un guide editorial KAMANGA (lead magnet HTML print A4) a partir d''un brief : charte, composants, offres et page auteur. Triggers: "kamanga guide" | "nouveau guide" | "guide KAMANGA" | "lead magnet" | "livre blanc" | "cree un guide" | "produis un guide" | "guide PDF".'
version: 0.1.0
argument-hint: '[brief ou chemin du contenu]'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# kamanga-guide

Génère un document éditorial à la charte KAMANGA (page A4, HTML autoportant, prêt à imprimer en PDF), identique en mise en page aux guides « Le Nouveau Développeur 2026 » et « Réduire votre Lead Time ». Seuls le contenu et le choix des composants changent.

## Ressources (à lire au démarrage)

- `templates/guide.html` : squelette + CSS complet de la charte (source de vérité visuelle).
- `reference/brand.md` : couleurs, fontes, format, règle typo stricte.
- `reference/components.md` : catalogue de composants + snippets (quand utiliser quoi).
- `reference/offers.md` : catalogue d'offres pour la page CTA.
- `reference/author.md` : contenu de la page « À propos ».
- `assets/logo-kamanga.png` : logo à copier à côté de chaque guide produit.

`${CLAUDE_PLUGIN_ROOT}` pointe vers la racine du plugin. Les ressources sont sous `${CLAUDE_PLUGIN_ROOT}/skills/kamanga-guide/`.

## Workflow

### 1. Intake

Récupérer le brief et le contenu :
- Si l'argument est un chemin de fichier : le lire.
- Si c'est du texte : le prendre tel quel.
- Sinon, demander à l'utilisateur le sujet, l'angle, l'audience, et le matériau (notes, plan, contenu existant).

Mode de production (décision projet par défaut) : **brief vers contenu + mise en page**. À partir du brief et des notes, rédiger le contenu dans le ton KAMANGA (direct, concret, chiffré, sans jargon creux), puis le mettre en page. Si l'utilisateur fournit déjà le texte final, ne pas le réécrire, seulement le mettre en page.

### 2. Plan de pages

Proposer un découpage page par page (1 section = 1 page A4) avant de générer. Structure type :

1. **Couverture** (`page-dark cover`) : eyebrow, titre avec promesse chiffrée accentuée, sous-titre, méta auteur.
2. **(si > 12 pages)** Sommaire (`toc-list`).
3. **Pages de contenu** : 1 idée structurante par page, chacune mappée sur un composant de `components.md` (pipeline, table, escalier, cas, pièges, étapes...).
4. **À propos de l'auteur** (avant-dernière page) : depuis `reference/author.md`.
5. **CTA / Offres** (`page-dark cta-page`, dernière page) : offres choisies + citation + contacts.

Pour chaque page de contenu, choisir le composant qui sert le mieux la donnée (voir la règle de choix de `components.md`). Privilégier 1 à 2 blocs visuels par page. Réutiliser les pipelines pour montrer les dynamiques entre étapes/segments.

Valider ce plan avec l'utilisateur (gate léger) avant de générer le HTML.

### 3. Interview (AskUserQuestion)

Poser en un seul lot les décisions variables :

1. **Couverture** : titre (avec la partie à accentuer en ambre), sous-titre, eyebrow (ex. « Guide gratuit · N pages · Framework KAMANGA »).
2. **Identité** : auteur (`Hervé Muludiki` / `Kamanga Muludiki`), email footer (`herve@kamanga.fr` / `kamanga@kamanga.fr`), année d'édition.
3. **Page auteur** : inclure la page « À propos » (oui par défaut) ; proposer le contenu de `author.md` à confirmer/éditer.
4. **Offres CTA** : présenter le catalogue de `offers.md` en choix multiple, plus l'option d'ajouter une offre. Le label de la section annoncera le **nombre exact** retenu.
5. **Sortie** : dossier de destination du `guide.html`.

Pour les offres et la bio, toujours **partir du catalogue par défaut** et demander confirmation, ne jamais faire re-saisir ce qui existe déjà.

### 4. Génération

1. Copier `templates/guide.html` vers le dossier de sortie comme `guide.html`.
2. Copier `assets/logo-kamanga.png` dans le même dossier (le HTML référence `logo-kamanga.png` en relatif).
3. Remplacer les placeholders `{{...}}` de la couverture, des footers, de la page auteur et de la page CTA.
4. Construire les pages de contenu en clonant le gabarit de page et en y insérant les composants choisis, remplis avec le contenu.
5. Numéroter les footers séquentiellement (`N / TOTAL`).
6. Page CTA : un bloc `.cta-offer` par offre retenue, label avec le nombre en toutes lettres, contacts standard.

### 5. Validation (bloquant)

Lancer ces vérifications et corriger avant de livrer :

```bash
GUIDE="<dossier>/guide.html"
# 1. Aucun tiret cadratin/demi-cadratin (doit afficher 0)
grep -c $'—\|–' "$GUIDE"
# 2. Nombre de pages == TOTAL annonce
grep -c 'class="page ' "$GUIDE"
# 3. Footers sequentiels et logo present
grep -o '[0-9]* / [0-9]*' "$GUIDE"
ls "$(dirname "$GUIDE")/logo-kamanga.png"
```

Checklist finale :
- Zéro `—` / `–` (remplacés par `,` `:` `()` `-` `.` ou `·`).
- Pagination cohérente, footer email correct sur toutes les pages.
- Chaque offre CTA a un lien (ou un `placeholder` explicite si lien à fournir).
- La couverture accentue bien la promesse chiffrée (`<span class="accent">`).
- Contraste et badges texte+couleur conformes à `brand.md`.

### 6. PDF (optionnel, sur demande)

Ne générer le PDF que si l'utilisateur le demande. Rendu via Chrome headless :

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="<dossier>/guide.pdf" "file://<chemin absolu>/guide.html"
```

## Garde-fous

- Ne jamais modifier le CSS de la charte pour un guide donné : réutiliser les classes. Une nouvelle classe n'est justifiée que par un composant réellement nouveau (et alors, l'ajouter aussi au template + `components.md`).
- Respecter la règle typo stricte (aucun tiret long), c'est non négociable.
- Si le catalogue d'offres ou la bio évoluent, mettre à jour `reference/offers.md` / `reference/author.md`, pas seulement le guide produit.
