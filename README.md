# 杏林墨问 / Xinglin Mowen

Godot 4 垂直切片骨架。Steam 水墨中医问诊，不是执医题库。

Open `project.godot` in Godot 4.3+ (4.x). Main scene: `scenes/main.tscn`.

## Slice (do not expand)

- One ink-wash clinic, one apprentice, 3 patients
- Full 望闻问切 (ask via local llama-server / optional DEV remote; offline template fallback)
- Formula (drag herbs) and acupuncture both viable
- CN playable; EN/JP i18n keys present
- Boot disclaimer required

Not this slice: time-travel, leaderboards, full map, hiring apprentices.

## Secrets / LLM

- **Shipping**: local OpenAI-compatible server (llama.cpp `llama-server`) or offline symptom templates. See `docs/LLM-LOCAL.md` / `other-systems/LLM-LOCAL.md`. Dialogue can run offline.
- **DEV remote** (Helix): `secrets.env` on the machine only. Never commit. Never paste in chat. Do not market model names on Steam.

## Layout

```
scenes/     main boot scene (clinic comes next)
locale/     CN / EN / JA keys
ui/         UI later
DESIGN.md / DEV-TASKS-SLICE.md / STEAM-MARKET-RESEARCH.md  design sources
```


## Runnable stubs (local)

- Boot: `scenes/main.tscn` (title + disclaimer)
- Clinic placeholder: `scenes/clinic.tscn`
- Pulse placeholder (Steam screenshot target): `scenes/pulse.tscn`
- Flow autoload: `GameFlow` in `scripts/game_flow.gd`
- Windows export preset: `export_presets.cfg` (excludes secrets.env)

See `LAYOUT.md` for who owns which folder.
