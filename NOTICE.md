# NOTICE

Most of this repository is other people's work, vendored and in places modified.
This file records what came from where and under which license, per directory.
Full license texts are in `licenses/`.

Three licenses apply. They are not interchangeable: the MIT portions may be
redistributed freely provided their copyright and permission notices travel with
them, while the FSL portions carry a non-compete restriction. There is no single
license for the repository as a whole.

## MIT — pstack, Copyright (c) 2026 Lauren Tan

Source: https://github.com/cursor/plugins, `pstack/` at version 0.14.2.
License text: `licenses/MIT-pstack-lauren-tan.txt`.

Vendored, then modified: the model rosters, subagent parameters, and MCP
discovery were ported from Cursor to Claude Code. See INDEX.md, "Ported off
Cursor", for what changed.

    skills/arena/                 skills/interrogate/
    skills/architect/             skills/no-comments/
    skills/blast-radius/          skills/tdd/
    skills/how/                   skills/unslop/
                                  skills/why/
    skills/principle-*/           (21 directories)
    agents/comment-sicko.md

## MIT — mattpocock/skills, Copyright (c) 2026 Matt Pocock

Source: https://github.com/mattpocock/skills, plugin version 1.2.3.
License text: `licenses/MIT-mattpocock-skills.txt`.

Vendored verbatim except `two-axis-review`, noted below.

    skills/codebase-design/       skills/handoff/
    skills/domain-modeling/       skills/improve-codebase-architecture/
    skills/grill-me/              skills/wait-what/
    skills/grill-with-docs/       skills/wizard/
    skills/grilling/              skills/writing-for-agents/
    skills/resolving-merge-conflicts/
    skills/two-axis-review/       (upstream `engineering/code-review`, renamed
                                   and modified: see INDEX.md)

## FSL-1.1-Apache-2.0 — dxos/dxos, Copyright 2026 DXOS

Source: https://github.com/dxos/dxos, `.agents/skills/`.
License text: `licenses/FSL-1.1-Apache-2.0-dxos.txt`.

The Functional Source License is source-available, not permissive. It permits
use, copying, modification, and redistribution for any Permitted Purpose, which
is any purpose other than a Competing Use, and converts to Apache 2.0 two years
after each version's release. Redistributing these directories carries that
restriction; it cannot be relicensed as MIT.

    skills/diagnosing-ui/         derived from .agents/skills/debugging-ui @ cc9b81fcad
    skills/instrumentation/       derived from .agents/skills/debugging @ e68ddada8f

### Mixed provenance

    skills/diagnosing-bugs/

Derived from both mattpocock/skills `engineering/diagnosing-bugs` (MIT) and
dxos/dxos `.agents/skills/debugging-ui` (FSL-1.1-Apache-2.0). Both notices
apply, and the more restrictive terms govern the combined work.

## Not distributed here

    skills/worktree-slots         a relative symlink to ~/Code/worktree-slots/skill

The link is committed; the content it points at is not part of this repository
and carries its own repository's license.

## Original to this repository

    README.md   INDEX.md   NOTICE.md   install.sh   .gitignore

No license is asserted over these. If this repository is published, choose one
for them, and keep it separate from the terms above.
