import os, osproc, terminal, strutils, times, logging, rdstdin, json

addQuitProc(resetAttributes)
addHandler(newFileLogger(fmtStr = verboseFmtStr))
setControlCHook((proc {.noconv.} = quit" CTRL+C Pressed, Logs saved, shutting down, Bye! "))
var counter: byte
let started = cpuTime()


proc call(cmd: string) =
  echo "Running\t", cmd, "\n  in 3"
  sleep 999
  echo "  in 2"
  sleep 999
  echo "  in 1"
  when defined(interactive):
    if readLineFromStdin("Run this command? (y/N): ").normalize == "y":
      let t = cpuTime()
      let (output, exitCode) = execCmdEx(cmd)
      echo output
      if exitCode == 0:
        inc counter
        echo counter, exitCode, "\t", now(), "\t", cpuTime() - t, "Secs"
      else:
        if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
          call(cmd)
    else:
      let t = cpuTime()
      let (output, exitCode) = execCmdEx(readLineFromStdin("Edit this command:\n").strip)
      echo output
      if exitCode == 0:
        inc counter
        echo counter, exitCode, "\t", now(), "\t", cpuTime() - t, "Secs"
      else:
        if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
          call(cmd)
  else:
    let t = cpuTime()
    let (output, exitCode) = execCmdEx(cmd)
    echo output
    if exitCode == 0:
      inc counter
      echo counter, exitCode, "\t", now(), "\t", cpuTime() - t, "Secs"
    else:
      if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
        call(cmd)


when isMainModule:
  eraseScreen()
  if isTrueColorSupported(): enableTrueColors()
  setBackgroundColor(bgBlack)
  styledEcho(fgGreen, "Welcome to Palas Cat Installer for Cats")
  for item in parseJson(static(staticRead"palas.json")).pairs:
    echo item.key
    call item.val.getStr
  echo counter, " total commands executed."
  echo cpuTime() - started, " total time elapsed."
  if readLineFromStdin("Suicide, Delete Itself ? (y/N): ").normalize == "y": echo tryRemoveFile(currentSourcePath()[0..^5])
