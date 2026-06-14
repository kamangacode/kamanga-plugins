# Catalogue d'offres KAMANGA

Offres réutilisables pour la page CTA finale. À chaque guide, le skill **propose ce catalogue** et l'utilisateur coche celles à inclure (ou en ajoute). Garder ce fichier à jour : il est la source de vérité des offres.

Le label de la section CTA doit annoncer le **nombre exact** d'offres affichées (« Trois façons », « Quatre façons », etc.).

---

## Offres standard

### EMA — Engineering Maturity Assessment
- **Public** : équipes / leaders engineering
- **Lien** : `https://app.kamanga.fr/forms/ema`
- **Pitch** : Auto-évaluation gratuite de la maturité engineering de votre équipe. 12 axes, restitution écrite, 20 minutes.
- **Format** : gratuit, auto-évaluation

### AI-Ready Engineering Checklist
- **Public** : équipes engineering, CTOs
- **Lien** : `https://app.kamanga.fr/forms/ai-checklist`
- **Pitch** : 25 questions, 5 dimensions (Tests, CI/CD, Gouvernance IA, Pratiques d'équipe, Dette technique). Score de maturité sur 25 et plan d'action 30/60/90 jours. Gratuit, 7 minutes.
- **Format** : gratuit, auto-évaluation

### EMA-Dev — auto-évaluation du développeur
- **Public** : développeurs individuels
- **Lien** : à fournir (placeholder `LIEN-EMA-DEV`)
- **Pitch** : Situez votre profil face au rôle d'administrateur IA, et identifiez vos prochains gestes de progression.
- **Format** : gratuit, auto-évaluation

### Programme Craft & Velocity
- **Public** : équipes, direction technique
- **Lien** : `https://kamanga.fr/craft-velocity`
- **Pitch** : Accompagnement équipe sur 90 jours. Le framework déployé dans votre contexte, avec mesure et coaching.
- **Format** : payant, accompagnement

### Session découverte (Discovery Call, 30 min)
- **Public** : tous
- **Lien** : `https://app.kamanga.fr/forms/discovery`
- **Pitch** : Échange gratuit sans engagement. On regarde votre situation, on identifie le levier prioritaire.
- **Format** : gratuit, appel

### Regard extérieur sur votre process (CTOs)
- **Public** : CTOs, leaders engineering
- **Lien** : à fournir (placeholder `LIEN-DISCOVERY-CALL`)
- **Pitch** : Les six phases, votre outillage IA, vos contrôles, votre conformité : 30 minutes pour situer votre équipe et identifier le premier chantier.
- **Format** : gratuit, appel

---

## Rendu : bloc offre (page CTA sombre)
```html
<a class="cta-offer" href="https://app.kamanga.fr/forms/ema">
  <div class="head"><span>Engineering Maturity Assessment</span><span class="arrow">&#8594;</span></div>
  <div class="body">Auto-évaluation gratuite de la maturité engineering de votre équipe. 12 axes, restitution écrite, 20 minutes.</div>
  <span class="link-hint">app.kamanga.fr/forms/ema</span>
</a>
```
- 2 à 4 offres : grille `cta-offers` (2 colonnes). Au-delà, préférer 4 max sur la page finale.
- Lien manquant : remplacer `link-hint` par `<span class="placeholder">lien à fournir : NOM</span>`.

## Contacts standard (toujours en pied de page CTA)
- Site : `kamanga.fr`
- LinkedIn : `@kamangacode` (linkedin.com/in/kamangacode)
- Email : `herve@kamanga.fr` ou `kamanga@kamanga.fr` (selon le guide)
