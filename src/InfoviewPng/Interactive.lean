import Lean
import ProofWidgets.Component.HtmlDisplay
import ProofWidgets.Component.MakeEditLink
import ProofWidgets.Component.Panel.Basic
import InfoviewPng.Basic

/-!
# Interactive PNG Viewer

Display PNG files with resize controls that update source code.

Usage:
  #png "path/to/image.png"      -- default 400px width
  #png "path/to/image.png" 300  -- explicit width

Clicking resize buttons will insert/update the width in source.
-/

open Lean ProofWidgets System Widget Server

namespace InfoviewPng

/-- Props for the interactive PNG widget -/
structure InteractivePngProps where
  /-- Base64-encoded PNG data -/
  base64 : String
  /-- Initial width from source -/
  initialWidth : Nat
  /-- Line number where the command is (0-indexed) -/
  lineNum : Nat
  /-- Original path string for reconstructing the command -/
  pathStr : String
  /-- Document URI for edits -/
  uri : String
  deriving FromJson, ToJson, Inhabited

/-- The interactive PNG panel widget with smooth slider resize -/
@[widget_module]
def InteractivePngPanel : Component InteractivePngProps where
  javascript := "
import * as React from 'react';
import { EditorContext } from '@leanprover/infoview';
const e = React.createElement;

export default function(props) {
  const ec = React.useContext(EditorContext);
  const imgRef = React.useRef(null);
  const labelRef = React.useRef(null);
  const sliderRef = React.useRef(null);
  const widthRef = React.useRef(props.initialWidth);
  const [showPresets, setShowPresets] = React.useState(false);
  const [, forceUpdate] = React.useReducer(x => x + 1, 0);

  // Sync refs with props on mount and prop changes
  React.useLayoutEffect(() => {
    widthRef.current = props.initialWidth;
    if (imgRef.current) imgRef.current.style.maxWidth = props.initialWidth + 'px';
    if (labelRef.current) labelRef.current.textContent = props.initialWidth + 'px';
    if (sliderRef.current) sliderRef.current.value = props.initialWidth;
  }, [props.initialWidth]);

  const src = 'data:image/png;base64,' + props.base64;

  const presets = [
    { label: 'Thumb', w: 100 },
    { label: 'Small', w: 200 },
    { label: 'Med', w: 400 },
    { label: 'Large', w: 600 },
    { label: 'Wide', w: 800 },
    { label: 'Full', w: 1000 },
  ];

  const commitToSource = (newW) => {
    ec.api.applyEdit({
      documentChanges: [{
        textDocument: { uri: props.uri, version: null },
        edits: [{
          range: { start: { line: props.lineNum, character: 0 }, end: { line: props.lineNum, character: 1000 } },
          newText: '#png \"' + props.pathStr + '\" ' + newW
        }]
      }]
    });
  };

  // Smooth interpolation to dampen large jumps
  const rafRef = React.useRef(null);
  const lastCommittedRef = React.useRef(props.initialWidth);
  const displayWidthRef = React.useRef(props.initialWidth);
  const targetWidthRef = React.useRef(props.initialWidth);
  const animatingRef = React.useRef(false);

  const lerp = (a, b, t) => a + (b - a) * t;

  const animateToTarget = () => {
    const current = displayWidthRef.current;
    const target = targetWidthRef.current;
    const diff = Math.abs(target - current);

    if (diff < 1) {
      displayWidthRef.current = target;
      imgRef.current.style.maxWidth = target + 'px';
      labelRef.current.textContent = Math.round(target) + 'px';
      animatingRef.current = false;
      return;
    }

    // Lerp factor: faster for small diffs, slower for large jumps
    const t = diff > 100 ? 0.25 : diff > 50 ? 0.35 : 0.5;
    displayWidthRef.current = lerp(current, target, t);
    imgRef.current.style.maxWidth = displayWidthRef.current + 'px';
    labelRef.current.textContent = Math.round(displayWidthRef.current) + 'px';

    requestAnimationFrame(animateToTarget);
  };

  const handleSliderInput = (evt) => {
    const w = evt.target.valueAsNumber;
    widthRef.current = w;
    targetWidthRef.current = w;

    // Start smooth animation if not already running
    if (!animatingRef.current) {
      animatingRef.current = true;
      requestAnimationFrame(animateToTarget);
    }

    // Throttle source commits
    if (!rafRef.current) {
      rafRef.current = requestAnimationFrame(() => {
        rafRef.current = null;
        if (widthRef.current !== lastCommittedRef.current) {
          lastCommittedRef.current = widthRef.current;
          commitToSource(widthRef.current);
        }
      });
    }
  };

  const handleSliderEnd = () => {
    if (rafRef.current) { cancelAnimationFrame(rafRef.current); rafRef.current = null; }
    // Snap to final value
    targetWidthRef.current = widthRef.current;
    displayWidthRef.current = widthRef.current;
    imgRef.current.style.maxWidth = widthRef.current + 'px';
    labelRef.current.textContent = widthRef.current + 'px';
    if (widthRef.current !== lastCommittedRef.current) {
      lastCommittedRef.current = widthRef.current;
      commitToSource(widthRef.current);
    }
  };

  const setPreset = (w) => {
    widthRef.current = w;
    targetWidthRef.current = w;
    sliderRef.current.value = w;
    // Animate to preset
    if (!animatingRef.current) {
      animatingRef.current = true;
      requestAnimationFrame(animateToTarget);
    }
    commitToSource(w);
    setShowPresets(false);
  };

  const ctrl = {
    position: 'absolute', top: 8, left: 8, right: 8,
    background: 'rgba(0,0,0,0.8)', padding: '6px 10px',
    borderRadius: 6, display: 'flex', flexDirection: 'column', gap: 4
  };
  const row = { display: 'flex', alignItems: 'center', gap: 6 };
  const lbl = { color: '#fff', fontFamily: 'monospace', fontSize: 13, fontWeight: 600, minWidth: 52 };
  const btn = {
    padding: '2px 6px', cursor: 'pointer', fontFamily: 'monospace', fontSize: 10,
    background: 'rgba(255,255,255,0.1)', color: '#fff',
    border: '1px solid rgba(255,255,255,0.25)', borderRadius: 3
  };

  return e('div', { style: { position: 'relative', display: 'inline-block' } },
    e('img', { ref: imgRef, src, style: { maxWidth: props.initialWidth + 'px', height: 'auto', display: 'block' } }),
    e('div', { style: ctrl },
      e('div', { style: row },
        e('span', { ref: labelRef, style: lbl }, props.initialWidth + 'px'),
        e('input', {
          ref: sliderRef, type: 'range', min: 50, max: 1200, defaultValue: props.initialWidth,
          onInput: handleSliderInput, onMouseUp: handleSliderEnd, onTouchEnd: handleSliderEnd,
          style: { flex: 1, height: 6, cursor: 'pointer', accentColor: '#4fc3f7' }
        }),
        e('button', { style: { ...btn, marginLeft: 2 }, onClick: () => setShowPresets(!showPresets) }, showPresets ? '▲' : '▼')
      ),
      showPresets && e('div', { style: { ...row, flexWrap: 'wrap', gap: 3 } },
        presets.map(p => {
          const active = Math.abs(widthRef.current - p.w) < 25;
          return e('button', {
            key: p.label,
            style: { ...btn, background: active ? '#4fc3f7' : btn.background, color: active ? '#000' : '#fff' },
            onClick: () => setPreset(p.w)
          }, p.label + ' ' + p.w);
        })
      )
    )
  );
}
"

end InfoviewPng

open Elab Command InfoviewPng

/-- Display a PNG with interactive resize controls. Width is optional (default 400). -/
syntax (name := pngCmd) "#png " str (num)? : command

/-- Command elaborator for #png -/
@[command_elab pngCmd]
def elabPngCmd : CommandElab
  | stx@`(#png $path:str $[$width:num]?) => do
    let pathStr := path.getString
    let initialWidth := width.map (·.getNat) |>.getD 400
    let filePath := FilePath.mk pathStr

    -- Read PNG and encode
    let base64 ← readPNGBase64 filePath

    -- Get document info for edits
    let fileMap ← getFileMap
    let some range := fileMap.lspRangeOfStx? stx
      | throwError "Could not determine source range"
    let lineNum := range.start.line

    -- Get document URI
    let fileName ← getFileName
    let uri := s!"file://{fileName}"

    -- Log interactive widget as message (shows in "All Messages")
    let props : InteractivePngProps := {
      base64 := base64
      initialWidth := initialWidth
      lineNum := lineNum
      pathStr := pathStr
      uri := uri
    }
    let msg ← liftCoreM <| MessageData.ofComponent InteractivePngPanel props s!"[PNG: {pathStr} @ {initialWidth}px]"
    logInfo msg
  | _ => throwError "Unexpected syntax"
