import VersoManual

open Verso.Genre Manual

set_option maxRecDepth 512

#doc (Manual) "lean4-infoview-png" =>

Display PNG images in the Lean 4 VS Code infoview with interactive resize controls.

# Installation

**lakefile.lean:**

```
require Png from git "https://github.com/alok/lean4-infoview-png" @ "main"
```

**lakefile.toml:**

```
[[require]]
name = "Png"
git = "https://github.com/alok/lean4-infoview-png"
rev = "main"
```

Then run `lake update`.

# Usage

```
import InfoviewPng

#png "/path/to/image.png"       -- default 400px width
#png "/path/to/image.png" 300   -- explicit width
```

Drag the slider to resize. Changes written back to source.

# Features

 * Interactive slider to resize images
 * Size presets (Thumb, Small, Med, Large, Wide, Full)
 * Changes written back to source automatically
 * Cached by file modification time for fast reloads
 * Uses native base64 for efficient encoding

# License

Apache 2.0
