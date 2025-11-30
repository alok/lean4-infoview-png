import Lean
import ProofWidgets.Component.HtmlDisplay
import Std.Data.HashMap

/-!
# PNG Viewer Utilities

Base64 encoding and HTML generation for PNG display in VS Code infoview.
-/

open Lean ProofWidgets System Widget Server
open Std (HashMap)

namespace InfoviewPng

/-- Cache key: (absolute path, modification time in seconds) -/
abbrev CacheKey := String × Int

/-- Global cache for base64-encoded PNGs, keyed by (path, mtime) -/
initialize pngCache : IO.Ref (HashMap CacheKey String) ← IO.mkRef {}

/-- Use native `base64` command for fast encoding -/
private def base64Native (path : FilePath) : IO String := do
  let out ← IO.Process.output { cmd := "base64", args := #["-i", path.toString] }
  if out.exitCode != 0 then
    throw <| IO.userError s!"base64 command failed: {out.stderr}"
  pure (out.stdout.replace "\n" "")

/-- Read a PNG file and return its base64 encoding (cached by mtime) -/
def readPNGBase64 (path : FilePath) : IO String := do
  let fileMeta ← path.metadata
  let mtime := fileMeta.modified.sec
  let key : CacheKey := (path.toString, mtime)

  -- Check cache first
  let cache ← pngCache.get
  if let some b64 := cache[key]? then
    return b64

  -- Cache miss: encode and store
  let b64 ← base64Native path
  pngCache.modify (·.insert key b64)
  pure b64

/-- Create HTML to display a base64-encoded image -/
def imageHtml (base64Data : String) (maxWidth : Option Nat := none) : Html :=
  let src := s!"data:image/png;base64,{base64Data}"
  match maxWidth with
  | some w =>
    .element "img" #[
      ("src", src),
      ("style", json% { maxWidth: $(s!"{w}px"), height: "auto" })
    ] #[]
  | none =>
    .element "img" #[("src", src)] #[]

/-- Create HTML to display a PNG file with error handling -/
def pngHtml (path : FilePath) (maxWidth : Option Nat := none) : IO Html := do
  try
    let base64 ← readPNGBase64 path
    pure (imageHtml base64 maxWidth)
  catch e =>
    pure <| .element "div"
      #[("style", json% { color: "red" })]
      #[.text s!"Error loading PNG: {e}"]

end InfoviewPng
