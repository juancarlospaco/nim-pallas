import os, osproc, terminal, strutils, times, logging, rdstdin, json

const
  configStr = staticRead"config.json".strip
  guiMsg = """Choose a User Interface?
    y for Terminal Color (Default)
    t for Terminal No Colors (Legacy)
    n for NCurses Whiptail (Experimental)
    w for Web HTML (Beta)
  """

let
  started = cpuTime()
  config = parseJson(configStr)
  delay = config["delay"].getInt.byte
var counter: byte

addQuitProc(resetAttributes)
if likely(config["log"].getBool): addHandler(newFileLogger(fmtStr = verboseFmtStr))
setControlCHook((proc {.noconv.} = quit(" CTRL+C Pressed, Logs saved, shutting down, Bye! ", execCmdEx(config["ctrlcCommand"].getStr).exitCode)))
addQuitProc((proc {.noconv.} = quit(" Shutting down, Bye! ", execCmdEx(config["quitCommand"].getStr).exitCode)))


proc call(cmd: string) =
  echo "Running:\t", cmd
  for i in countdown(delay, 0.byte):
    write(stdout, "\r  in " & $i)
    flushFile(stdout)
    sleep 999
  write(stdout, "\r       ")
  flushFile(stdout)
  echo ""
  when defined(interactive):
    if readLineFromStdin("Run this command? (y/N): ").normalize == "y":
      let t = cpuTime()
      let (output, exitCode) = execCmdEx(cmd)
      echo output
      if exitCode == 0:
        inc counter
        echo counter, exitCode, "\t", now(), "\t", formatFloat(cpuTime() - t, precision = -1), "Secs"
      else:
        if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
          call(cmd)
    else:
      let t = cpuTime()
      let (output, exitCode) = execCmdEx(readLineFromStdin("Edit this command:\n").strip)
      echo output
      if exitCode == 0:
        inc counter
        echo counter, exitCode, "\t", now(), "\t", formatFloat(cpuTime() - t, precision = -1), "Secs"
      else:
        if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
          call(cmd)
  else:
    let t = cpuTime()
    let (output, exitCode) = execCmdEx(cmd)
    echo output
    if exitCode == 0:
      inc counter
      echo counter, exitCode, "\t", now(), "\t", formatFloat(cpuTime() - t, precision = -1), "Secs"
    else:
      if readLineFromStdin("This command returned a Non-Zero exit code, retry this command? (y/N): ").normalize == "y":
        call(cmd)


when isMainModule:
  eraseScreen()
  echo config["welcomeMessage"].getStr.strip
  if config["beforeCommand"].getStr.len > 0: discard execCmdEx(config["beforeCommand"].getStr).exitCode
  let editor = if readLineFromStdin("Choose a Text Editor ? (y/N): ").normalize == "y": readLineFromStdin("Type a Text Editor command: ").strip else: getEnv"EDITOR"
  var gui: string
  while gui notin ["t", "w", "n", "y"]: gui = readLineFromStdin(guiMsg).normalize

  if isTrueColorSupported(): enableTrueColors()
  setBackgroundColor(bgBlack)

  # for item in config["steps"].pairs:
  #   #echo item.key
  #   #echo item.val
  #   echo $item

  # if config["afterCommand"].getStr.len > 0: discard execCmdEx(config["afterCommand"].getStr).exitCode
  # if likely(config["postinstallResume"].getBool):
  #   echo counter, " total commands executed."
  #   echo delay, " seconds of delay between commands executed."
  #   echo formatFloat(cpuTime() - started, precision = -1), " total time elapsed."
  #   echo $now(), " time of completion."
  #   echo "Current directory is " & getCurrentDir()
  #   echo "Log file at " & defaultFilename()
  # if unlikely(config["canSuicide"].getBool):
  #   if readLineFromStdin("Suicide, Delete Itself ? (y/N): ").normalize == "y": echo tryRemoveFile(currentSourcePath()[0..^5])


# ? help   print help and retry
# r retry  retry the command
# s skip   skips the command
# y yes    yes
# n no     no
# e edit   launch editor with command inside
