# Walker Nerd Icons Menu

![Illustration](./assets/illustration.jpg)

Custom [Walker](https://github.com/abenz1267/walker) provider for searching Nerd Font glyphs, copying the selected icon, or inserting it directly in the focused app.
Built as a custom [elephant's menus](https://github.com/abenz1267/elephant/tree/master/internal/providers/menus).

## Prerequisites

- [Walker](https://github.com/abenz1267/walker)
- [Elephant](https://github.com/abenz1267/elephant) with `menus` provider
- `wl-copy` (from `wl-clipboard`) for clipboard copy
- `wtype` for the insert action (`Ctrl+i`)
- At least one of `curl` or `wget` (used by the menu to fetch `glyphnames.json` when missing)

## Installation

```bash
git clone https://github.com/nino-mau/walker-nerd-icons-menu.git
cd walker-nerd-icons-menu
./install.sh
```

The installer copies `nerd-icons.lua` to:

`~/.config/elephant/menus/nerd-icons.lua`

It also runs `configure_walker.sh`, which updates `~/.config/walker/config.toml` to add custom actions for `menus:nerd-icons` under `[providers.actions]`.
A timestamped backup of your Walker config is created before modification.

## Walker setup

Add a prefix in your Walker config (`~/.config/walker/config.toml`):

```toml
[[providers.prefixes]]
prefix = "nf" # Can be anything
provider = "menus:nerd-icons"
```

Restart Walker and Elephant after configuration.

## Usage

- Launch walker
- Type your prefix (`nf`) followed by a query
- Search by icon name (example: `cod-arrow`)
- Press `Enter` to copy the glyph
- Press `Ctrl+i` to insert/type the glyph in the focused window

> [!TIP]
> You can launch the menu directly with `walker --provider menus:nerd-icons`

## Data source

Glyph metadata is loaded from:

1. Local Nerd Fonts `glyphnames.json` paths (if found)
2. Cached file in `~/.cache/elephant/nerd-icons/glyphnames.json`
3. Nerd Fonts upstream `glyphnames.json` URL
