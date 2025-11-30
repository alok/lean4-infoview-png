import VersoManual
import Docs

open Verso.Genre Manual

def config : Config where
  emitTeX := false
  emitHtmlSingle := false
  emitHtmlMulti := true
  htmlDepth := 1

def main := manualMain (%doc Docs) (config := config)
