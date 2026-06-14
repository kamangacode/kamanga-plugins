# kamanga-guide

Produit des guides éditoriaux à la charte KAMANGA (lead magnets / livres blancs) en HTML print A4, prêts à exporter en PDF. Même mise en page que « Le Nouveau Développeur 2026 » et « Réduire votre Lead Time ». Seuls le contenu et le choix des composants changent.

## Usage

```
/kamanga-guide <brief ou chemin du contenu>
```

Le skill :
1. lit le brief / contenu,
2. propose un plan de pages,
3. interroge sur la couverture, l'identité, la page auteur et les offres CTA (depuis un catalogue par défaut),
4. génère un `guide.html` autoportant + copie du logo,
5. valide (typo, pagination, liens),
6. exporte le PDF sur demande.

## Contenu

| Ressource | Rôle |
|-----------|------|
| `skills/kamanga-guide/SKILL.md` | Workflow d'orchestration |
| `skills/kamanga-guide/templates/guide.html` | Squelette + CSS complet de la charte |
| `skills/kamanga-guide/reference/brand.md` | Couleurs, fontes, format, règle typo |
| `skills/kamanga-guide/reference/components.md` | Catalogue de composants + snippets |
| `skills/kamanga-guide/reference/offers.md` | Catalogue d'offres (page CTA) |
| `skills/kamanga-guide/reference/author.md` | Page « À propos de l'auteur » |
| `skills/kamanga-guide/assets/logo-kamanga.png` | Logo copié dans chaque guide |

## Maintenance

Faire évoluer la charte ou la bibliothèque de composants dans `templates/guide.html` (+ documenter dans `components.md`). Tenir `offers.md` et `author.md` à jour : ce sont les sources de vérité des offres et de la bio.
