# Emojimage [![Gem Version](https://badge.fury.io/rb/emojimage.svg)](https://badge.fury.io/rb/emojimage)

Emojimage takes an input PNG image (sorry, JPG lovers!) and outputs it composed of emoji.

## Installation

```bash
$ gem install emojimage
```

## Command-line

```bash
$ emojimage cast FILENAME --output OUTPUT --type TYPE [--size SIZE] [--no-wrap] [--no-transparency] [--blend=RED GREEN BLUE]
```

### Options

- _`--output`_ or _`-o`_ — The output filename. Required.
- _`--type`_ or _`-t`_ — The output type. One of `image` (PNG only), `text`, or `html`. Required.
- _`--size`_ or _`-s`_ — Emoji size. Defaults to `4`.
- _`--no-wrap`_ — Doesn't wrap HTML output with `<code><pre></pre></code>`. Disabled by default.
- _`--blend`_ or _`-b`_ — Color to treat as background when dealing with transparency. This way, the output image can look good on a specific background color. _Must be last option._ Example: _`--blend 255 0 0`_ (blends with red). Defaults to white (`255 255 255`).
- _`--no-transparency`_ — Converts wholly transparent blocks to an emoji. Otherwise, keeps it transparent. Disabled by default.