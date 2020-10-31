import std/[os, strformat]
import maxminddb
import maxminddb/errors

proc show(path: string) =
  try:
    echo &"OK {path}: {initMaxMind(readFile(path)).metadata}"
  except BadMaxmindDatabaseError as e:
    stderr.writeLine &"ERROR {path}: {e.msg}"
  except IndexDefect as e:
    stderr.writeLine &"ERROR {path}: {e.msg}"
  except AssertionDefect as e:
    stderr.writeLine &"ERROR {path}: {e.msg}"

when isMainModule:
  if paramCount() > 0:
    for i in 1 .. paramCount():
      show(paramStr(i))
  else:
    quit &"usage: {paramStr(0)} <file1> [<file2> [... <filen>]]"
