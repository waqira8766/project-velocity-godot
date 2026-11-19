# Checkpoints

| ID | Checkpoint | State | Evidence |
| --- | --- | --- | --- |
| 01 | ENVIRONMENT, REQUIREMENTS AND ASSET RESEARCH | IN_PROGRESS | Original asset pipeline and engine verified. Broad asset research and polish stayed open. |
| 02 | GODOT FOUNDATION AND WEB PIPELINE | VERIFIED | Godot 4.6.3 release exported and loaded over Chromium WebGL 2. |
| 03 | REALISTIC HERO AND ANIMATION ASSET PIPELINE | IN_PROGRESS | Original rig and required imported clips verified. Full visual and motion review open. |
| 04 | FULL MOVEMENT, CAMERA AND INPUT | IN_PROGRESS | Native locomotion and touch suites passed. Physical controller parity and full camera play review open. |
| 05 | SPEED PHYSICS, SLIDER AND EXTREME TRANSIT | VERIFIED | Traversal fixture passed, including a 134.5 m/s bounded run and a 22 cm collision test. |
| 06 | PROCEDURAL CITY AND SEAMLESS STREAMING | VERIFIED | World fixture passed for routes, collision and deterministic bounded streaming. |
| 07 | NPC CIVILIZATION AND TRAFFIC | VERIFIED | Population fixture passed for signals, crowds, collision, police and playable dispatch. |
| 08 | ALL SPEED FORCE ABILITIES AND VFX | VERIFIED | 54 power assertions passed. |
| 09 | GENUINE WORLD TIME REWIND | VERIFIED | 86 progression and rewind assertions passed, including multi-entity state. M05 integrates live vehicle and crowd rewind. |
| 10 | CORE COMBAT, ENEMIES AND ADAPTIVE AI | VERIFIED | Native combat integration fixture passed. |
| 11 | TWO DISTINCT MULTIPHASE BOSS FIGHTS | VERIFIED | Both bosses defeated with timed counter/heavy commands in native integration. |
| 12 | RUN-TO-EARN ECONOMY, GACHA AND SAVES | VERIFIED | Native progression suite and Chromium restart persistence passed. |
| 13 | COMPLETE EIGHT-MISSION STORY AND ENDGAME | IN_PROGRESS | 49 native campaign checks, including eight missions and postgame, passed. Full browser play-through open. |
| 14 | TABLET HUD, GAMEPAD, OPTIONS AND ACCESSIBILITY | IN_PROGRESS | 46 native HUD checks and Chromium four-touch plus page reload passed. Physical tablet and controller open. |
| 15 | AUDIO, DAY/NIGHT, ART AND FINAL POLISH | IN_PROGRESS | Original audio and city lighting render in browser; complete presentation review open. |
| 16 | PERFORMANCE AND STABILITY | IN_PROGRESS | Measured desktop software WebGL 2 performance. Target tablet and long play open. |
| 17 | COMPLETE CROSS-SYSTEM REGRESSION | IN_PROGRESS | Native integration and Web smoke passed, whole-campaign browser regression open. |
| 18 | FINAL GODOT WEB EXPORT AND HANDOFF VERIFICATION | IN_PROGRESS | Current multi-file Web archive verified. Full production release gates open. |

## Release gates

| Gate | Scope | State |
| --- | --- | --- |
| A | GODOT BUILD | VERIFIED |
| B | HERO | IN_PROGRESS |
| C | CONTROLS | IN_PROGRESS |
| D | SPEED | IN_PROGRESS |
| E | CITY | VERIFIED |
| F | POWERS | VERIFIED |
| G | REWIND | VERIFIED |
| H | COMBAT | VERIFIED |
| I | BOSSES | VERIFIED |
| J | STORY | IN_PROGRESS |
| K | ECONOMY | VERIFIED |
| L | ART/AUDIO | IN_PROGRESS |
| M | SETTINGS/ACCESSIBILITY | IN_PROGRESS |
| N | STABILITY | IN_PROGRESS |
| O | PERFORMANCE | IN_PROGRESS |
| P | FINAL DELIVERY | IN_PROGRESS |

See QA_REPORT.md for reproducible evidence and the remaining acceptance work.
