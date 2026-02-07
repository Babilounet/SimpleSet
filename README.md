# SimpleSet

Lightweight equipment set manager for **WoW Classic Anniversary Edition**.

Save and load gear sets from the character panel with two dropdown menus. Each set targets the exact equipment slot, fixing the classic bug where rings and trinkets end up in the wrong slot.

## Features

- **Save/Load sets** from dropdowns on the character panel (top, under your name)
- **Per-slot equipping** — rings and trinkets go to the correct slot, even with identical names
- **Dynamic sets** — start with 2, add or remove up to 10 via the settings panel (gear icon)
- **Rename sets** — both Load and Save dropdowns reflect custom names
- **Bag lock icons** — items belonging to a set are marked with a lock overlay so you don't vendor them by accident
- **Baganator support** — integrates as a native corner widget (also works with default bags)
- **Slash commands** — `/ss save 1`, `/ss load 2`, `/ss list`, `/unequipall`

## Installation

1. Download or clone this repo
2. Copy the `SimpleSet` folder into `World of Warcraft/_anniversary_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Usage

Open your character panel (**C**). You'll see **Load** and **Save** dropdowns at the top.

- **Save a set**: click Save, pick a slot, confirm overwrite
- **Load a set**: click Load, pick a set — gear equips to the correct slots
- **Rename/Add/Remove sets**: click the gear icon next to the dropdowns
- **Tooltips**: hover over a set in the dropdown to preview its contents

## Slash Commands

| Command | Description |
|---------|-------------|
| `/ss save <n>` | Save current gear to set n |
| `/ss load <n>` | Load set n |
| `/ss list` | List all sets and their status |
| `/unequipall` | Remove all equipped gear to bags |

## Bag Icons

Items in your bags that belong to at least one saved set display a small lock icon.

- **Baganator users**: the lock appears as a corner widget (configurable in Baganator settings)
- **Default bags**: the lock appears in the top-left corner of the item slot

## License

MIT
