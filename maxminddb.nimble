# Package

version       = "0.1.0"
author        = "Julian Fondren"
description   = "A reader library for MaxMind's GeoLite2 databases"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "iputils >= 0.2.0"

# Tasks

import strutils

task fetchmm, "Fetch MaxMindDB test-data":
  exec "git clone --depth=1 https://github.com/maxmind/MaxMind-DB.git testdata"

task testmm, "Run tests requiring MaxMindDB test-data":
  for fn in listFiles("tests"):
    if not fn.endsWith ".nim": continue
    if not fn.contains "/mmdb_": continue
    selfExec "r -f --hints:off " & fn

task testlite, "Run tests requiring the official GeoLite2-Country.mmdb":
  for fn in listFiles("tests"):
    if not fn.endsWith ".nim": continue
    if not fn.contains "/lite_": continue
    selfExec "r -f --hints:off " & fn

task clean, "Clean up common files":
  for fn in listFiles("tests"):
    if fn.endsWith ".nim": continue
    if fn.endsWith ".nims": continue
    if fn.endsWith ".swp": continue
    if fileExists(fn & ".nim"):
      rmFile fn
