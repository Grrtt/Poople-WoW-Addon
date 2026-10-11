# Poople for WoW

Play a four-letter word ladder inside World of Warcraft. Change exactly one
letter per move, use a word from the bundled dictionary, and reach `POOP` in as
few moves as you can. For example, `COOL → COOP → POOP` is a valid two-move route.

This is a standalone addon with no addon dependencies.

[Download the latest release](https://github.com/Grrtt/Poople/releases/latest).

## Install

1. Open the [latest release](https://github.com/Grrtt/Poople/releases/latest) and
   download **Poople-0.2.0.zip** from **Assets**. Use the addon ZIP rather than
   GitHub's **Source code** archives.
2. Extract the ZIP into your WoW client's
   `Interface/AddOns` directory. The manifest must end up at
   `Interface/AddOns/Poople/Poople.toc`.
3. Restart WoW if you added the folder while the client was running. Enable
   **Poople for WoW** in the addon list.
4. Log in and enter `/poople`.

Common client folders are `_retail_`, `_classic_`, `_classic_era_`, and
`_classic_beta_`. Use the `Interface/AddOns` directory inside the client you play.

The manifest includes Retail, Forever, Classic Era, Burning Crusade Classic,
and Mists Classic interface versions. In-game testing so far is limited to Forever.
If a client marks the addon as out of date,
check its interface version with `/dump select(4, GetBuildInfo())` and update
`Poople.toc` accordingly.

## Play

- Enter your next four-letter word and press **Enter** or click **Play word**.
- Click **Undo** to remove your last move before completing a puzzle.
- Click **Hint** to reveal one word on a shortest route. Hint use is recorded.
- Click **Daily** to resume today's addon puzzle. It changes at midnight UTC.
- Click **New practice** to start another solvable puzzle. This preserves daily progress.
- To play from the website's starting word, enter it in **Website start word**
  and click **Start**. This starts a practice puzzle.
- Click **Copy result**, then press **Ctrl+C** to copy your ladder and score.
- Drag the title bar or the window background to reposition the game. Press
  **Escape** to close it. Your window position is saved automatically.
- Click the lock icon beside the close button to lock or unlock the game window's
  position. The icon shows the current state and also updates the lock setting.
- Left-click the minimap button to open or close the game. Right-click it to
  open settings. Drag it to reposition it around the minimap.

`Par` is the shortest possible route in the bundled dictionary. There is no move
limit. Completed puzzles cannot be undone. You can replay a word in practice.
Daily wins, streaks, hints, the window position, and daily and practice progress
are saved across reloads and shared by your characters on the same WoW account
and client installation. Starting another practice puzzle replaces the previous
practice puzzle. Daily wins count once per day; practice does not affect stats.

| Command | Action |
| --- | --- |
| `/poople` | Open or close the window. |
| `/poople daily` | Resume today's addon puzzle. |
| `/poople practice` | Start a random practice puzzle. |
| `/poople start COLD` | Start practice from a specific word. |
| `/poople settings` | Open settings. |

## Settings

Click **Settings** in the game window, right-click the minimap button, or enter
`/poople settings`. Changes apply immediately and are saved across reloads.

- **Background opacity**: Set the game and result backgrounds from 0% (transparent)
  to 100% (opaque). Text and controls remain visible.
- **Show minimap button**: Show or hide the minimap button. If you hide it, you can
  still open settings with `/poople settings`.
- **Lock game window position**: Prevent dragging the game window. Clear this
  checkbox to move it again.
- **Reset window position**: Center the game window and clear its saved position.

## Website compatibility

WoW addons cannot embed a website or make HTTP requests. This addon runs locally
and does not synchronize with poople.io. Its daily schedule and dictionary are
independent, so accepted words and shortest routes can differ from the website.
If a website start word is absent from the database or has no route to `POOP`,
the addon explains why it cannot start that puzzle.

The word database includes 3,903 four-letter words from the public-domain ENABLE
list, including uncommon words and inflections. See [word database attribution](THIRD_PARTY.md).
Daily and random practice starts come from a smaller, curated list of familiar
words with a route of at least three moves. Every accepted move still uses the
full dictionary.

## Development

Clone the repository into your development directory:

```sh
git clone https://github.com/Grrtt/Poople.git
cd Poople
```

You can copy this folder directly into `Interface/AddOns/Poople`. After editing
Lua files, use `/reload` to reload them. The addon needs no build step or network
connection to run. Python 3 is required only to create the release ZIP, and
LuaJIT is required for the automated tests.

From the repository root, run:

```sh
luajit tests/run.lua
python3 tools/package.py
```

The tests check the complete dictionary graph against an independent shortest-path
calculation, validate 365 daily puzzles, exercise invalid moves and saved games,
check statistics, and run the UI event handlers with a WoW API stub.

The packager creates `dist/Poople-0.2.0.zip`, containing a `Poople` folder ready
to extract into `Interface/AddOns`.

In WoW, check typing, buttons, scrolling through a long ladder, moving and locking
the window, resetting its position, copying results, **Escape**, switching between
daily and practice, and persistence after `/reload`. Check minimap clicking and
dragging, minimap visibility, and opacity at 0%, 50%, and 100%. Run
`/console scriptErrors 1` to display Lua errors during testing.

## License and credits

Addon code is available under the [MIT license](LICENSE). The bundled ENABLE
word database is public domain; see [word database attribution](THIRD_PARTY.md).
This is an independent fan implementation inspired by [Poople](https://poople.io/),
not an official port or a connection to its online service.
