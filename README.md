# lean4-infoview-png

Display PNG images in the Lean 4 infoview with interactive resize controls.

## Install

**lakefile.lean:**
```lean
require Png from git "https://github.com/alok/lean4-infoview-png" @ "main"
```

**lakefile.toml:**
```toml
[[require]]
name = "Png"
git = "https://github.com/alok/lean4-infoview-png"
rev = "main"
```

Then run `lake update`.

## Usage

```lean
import InfoviewPng

#png "/path/to/image.png"       -- default 400px width
#png "/path/to/image.png" 300   -- explicit width
```

Drag the slider to resize. Changes are written back to source.

<!-- TODO: add usage screenshot -->

## License

Apache 2.0
