FocusElseActivate(exe, path) {
  if (WinExist("ahk_exe " exe)) {
    WinActivate
  }
  else {
    Run(exe, path)
  }
}

LocalPath(path) {
  return EnvGet("USERPROFILE") "\AppData\Local\" path
}

; Open apps
!w:: FocusElseActivate("brave.exe", LocalPath("BraveSoftware\Brave-Browser\Application"))
!e:: Run "explorer"
!f:: FocusElseActivate("Everything64.exe", "C:\Program Files\Everything 1.5a")
!c:: FocusElseActivate("Code.exe", LocalPath("Programs\Microsoft VS Code"))
!o:: FocusElseActivate("Obsidian.exe", LocalPath("Obsidian"))
!Enter:: Run "wezterm-gui"

; Close active window
!q::
{
  if (WinGetTitle("A")) {
    WinClose(WinGetTitle("A"))
  }
  return
}

; Remap Caps to Esc
CapsLock::Escape

; Reload current script
!+r:: Reload