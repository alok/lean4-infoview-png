import Lake
open Lake DSL

require proofwidgets from git "https://github.com/leanprover-community/ProofWidgets4" @ "v0.0.82"

package «lean4-infoview-png» where
  version := v!"0.1.0"
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib InfoviewPng where
  srcDir := "src"
