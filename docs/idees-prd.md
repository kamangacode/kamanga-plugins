Voici un document de spécifications fonctionnelles (PRD) pour le développement d'un plugin Claude basé sur le modèle **"Orchestrator to Claude Headless"**.

---

# Product Requirements Document (PRD) : Plugin Claude "Orchestrator-Headless"

## 1. Vision et Objectif
L'objectif de ce plugin est de résoudre le problème de la **"pourriture du contexte" (context rot)** qui survient lors de l'utilisation de fonctions autonomes (comme `/goal`) dans une session unique. Le plugin doit permettre à un **Orchestrateur** de déléguer des tâches complexes à des instances de **Claude Headless** indépendantes pour garantir une précision maximale et une exécution autonome sur de longues périodes.

## 2. Problématique
Dans les sessions classiques, plus la conversation est longue, plus la précision diminue. Si l'agent commence à halluciner lors de l'évaluation ou de l'exécution d'une tâche, il peut faussement croire qu'il a terminé son travail alors que ce n'est pas le cas.

## 3. Architecture du Système
Le plugin repose sur le pattern **Orchestrator to Claude Headless** :
*   **L'Orchestrateur :** Reste dans une fenêtre de contexte restreinte et propre. Son rôle est uniquement de déléguer, d'évaluer et de passer à l'itération suivante.
*   **Claude Headless :** Des instances éphémères déclenchées via terminal (ex: `claude -p`) pour exécuter une itération spécifique, puis se fermer.
*   **Gestion d'État (State Management) :** Utilisation de **GitHub Projects** pour suivre l'avancement via des colonnes (Queue, Testing, Done, Bug, etc.).

## 4. Fonctionnalités Principales

### A. Le Super Orchestrateur
*   **Délégation :** Découpe un objectif global en itérations spécifiques.
*   **Boucle de Condition :** Continue de déclencher des itérations jusqu'à ce qu'une condition de succès soit mét (ex: "plus aucun bug", "toutes les fonctionnalités testées").
*   **Maintien du Contexte :** Ne reçoit que des rapports de fin d'itération pour éviter de saturer sa propre mémoire.

### B. Skill : Super QA (Qualité)
*   **Exploration BFS (Breadth-First Search) :** Parcourt l'application niveau par niveau (ex: accueil -> dashboard -> pages secondaires).
*   **Tests E2E :** Écrit et exécute des tests avec **Playwright**.
*   **Reporting :** Ajoute automatiquement les bugs détectés dans la colonne "Bugs" de GitHub.

### C. Skill : Super Build (Développement)
*   **Approche TDD (Test-Driven Development) :** Écrit le test avant l'implémentation, puis effectue le refactoring.
*   **Vérification :** S'assure que le code est scalable et réutilisable avant de valider l'itération.

### D. Skill : GStack (Aide à la décision)
*   **Auto Plan :** Simule un vote entre différents rôles d'IA (CEO, Engineering Manager, Designer, QA) pour prendre des décisions architecturales ou de design de manière autonome.

## 5. Flux d'Exécution (Workflow)
1.  **Initialisation :** L'utilisateur définit un objectif global à l'Orchestrateur.
2.  **Planification :** L'Orchestrateur vérifie l'état sur GitHub Projects (colonne "Queue").
3.  **Exécution Headless :**
    *   L'Orchestrateur lance un **Super QA headless** pour trouver des bugs.
    *   Si des bugs existent, il lance un **Super Build headless** pour les corriger.
4.  **Évaluation :** Une fois l'instance headless fermée, l'Orchestrateur analyse le résultat et met à jour le statut GitHub.
5.  **Boucle :** Passage à la tâche suivante dans la file d'attente jusqu'à complétion totale.

## 6. Exigences Techniques
*   **Intégration GitHub CLI :** Le plugin doit utiliser la CLI GitHub déjà présente pour manipuler les tickets et les projets sans installation supplémentaire.
*   **Commandes Terminal :** Capacité à exécuter des commandes type `claude -p "prompt"` avec l'option de passer les confirmations (dangerously skip) pour une autonomie totale.
*   **Persistance de l'État :** Utilisation d'un fichier Markdown ou idéalement des colonnes GitHub pour que l'état survive entre deux sessions de l'Orchestrateur.

## 7. Indicateurs de Succès (KPIs)
*   **Zéro Context Rot :** L'Orchestrateur doit maintenir une fenêtre de contexte stable même après 50 itérations.
*   **Autonomie :** Capacité à construire ou tester une application entière sans intervention humaine une fois l'objectif lancé.
*   **Précision :** Augmentation du taux de succès des corrections grâce au TDD et au vote multi-agents (GStack).