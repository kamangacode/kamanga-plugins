---
name: build
argument-hint: '[#N | "idea" | --from <step> | --audit]'
description: Alias de /dev — orchestrateur du cycle dev complet (frame, shape, build, verify, ship). Déclencheurs identiques à /dev. Triggers "build" | "build this" | "build it out".
version: 0.1.0
allowed-tools: Skill
---

# Build

Alias mince de `/dev`. Ce skill ne fait rien par lui-même : il route vers l'orchestrateur `dev`.

## Action

Invoque immédiatement le skill `dev` via l'outil Skill (`skill: "dev"`), en lui transmettant
tels quels les arguments reçus par `/build` (ex. `#N`, `"idea"`, `--from <step>`, `--audit`).

Ne demande pas de confirmation : `/build` et `/dev` sont strictement équivalents.
