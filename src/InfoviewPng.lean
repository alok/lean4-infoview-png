import InfoviewPng.Basic
import InfoviewPng.Interactive

/-!
# InfoviewPng

Display PNG images in the Lean 4 infoview with interactive resize controls.

## Usage

```lean
import InfoviewPng

#png "/path/to/image.png"       -- default 400px width
#png "/path/to/image.png" 300   -- explicit width
```

The widget shows a slider to resize images, with changes written back to source.
-/
