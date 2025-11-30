import Lake
open Lake DSL

require proofwidgets from git "https://github.com/leanprover-community/ProofWidgets4" @ "v0.0.53"
require verso from git "https://github.com/leanprover/verso" @ "v4.24.0"

package Png where
  version := v!"0.1.0"
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib InfoviewPng where
  srcDir := "src"

lean_lib Docs where
  srcDir := "doc"

lean_exe «gendocs» where
  root := `Main
  srcDir := "doc"
