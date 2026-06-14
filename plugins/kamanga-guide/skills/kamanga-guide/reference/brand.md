# Charte KAMANGA — invariants

Ces valeurs sont figées dans `templates/guide.html`. Ne jamais les redéfinir à la volée : réutiliser les classes.

## Couleurs

| Rôle | Hex | Usage |
|------|-----|-------|
| Magenta | `#422749` | Couleur primaire : titres, header, fonds sombres, texte fort |
| Magenta profond | `#2a1830` | Fond des pages sombres (cover, CTA) |
| Ambre | `#FFA81D` | Accent : eyebrows, badges, liens, mises en avant, goulots |
| Ambre foncé | `#b27300` / `#8a5a00` | Variante lisible de l'ambre sur fond clair (numéros, labels) |
| Crème | `#FFF6ED` | Fond des pages claires |
| Encre | `#1a0a00` | Texte courant |
| Rouge brique | `#b35a4a` | Badge critique / risque danger uniquement |
| Gris écran | `#d8cdc0` | Fond de prévisualisation écran (hors impression) |

## Typographie

- **Titres** : `Sora` (400/500/600/700)
- **Corps** : `Poppins` (300/400/500/600)
- Import Google Fonts déjà dans le `<head>` du template.
- Tailles de référence : corps 10.3pt, titres de page 20pt, phase-title 21pt, cover-title 34pt.

## Format

- Page **A4** : `210mm × 297mm`, une `<section class="page">` = une page.
- Pages claires : `page-light`. Pages sombres (cover, CTA) : `page-dark`.
- Marges de contenu : `padding: 8mm 20mm 22mm` (classe `page-body`).
- Header magenta avec logo à gauche, titre + sous-titre ambre.
- Footer : `kamanga.fr · {email}` à gauche, `N / TOTAL` à droite.

## Identité variable (à confirmer à chaque guide)

| Variable | Valeurs connues |
|----------|-----------------|
| Auteur | `Hervé Muludiki` (livre blanc) ou `Kamanga Muludiki` (lead magnet) |
| Email footer | `herve@kamanga.fr` ou `kamanga@kamanga.fr` |
| Édition | année courante (ex. 2026) |
| Domaine | toujours `kamanga.fr` (apex ; `blog.kamanga.fr` n'existe pas) |

## Règle typographique STRICTE

**Interdiction absolue du tiret cadratin `—` (U+2014) et demi-cadratin `–` (U+2013)** dans tout le HTML (texte, titres, attributs, commentaires).

Remplacer par :
- virgule ou deux-points `:` pour une apposition,
- parenthèses `()` pour une incise,
- tiret simple `-` (U+002D) si séparation visuelle,
- point pour scinder en deux phrases.

Le séparateur de méta/footer est le point médian `·` (U+00B7), jamais un tiret long.

## Accessibilité (validée via UI/UX Pro Max, pattern Trust & Authority)

- La couleur ne porte jamais seule l'information : les badges combinent **texte + couleur** (`badge-low/mid/high/crit`).
- Contraste texte/fond ≥ 4.5:1 (encre sur crème, crème sur magenta).
- Chiffres en `tabular-nums` dans les colonnes de données (`td.num`).
