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

; Open/focus brave
!w:: FocusElseActivate("brave.exe", LocalPath("BraveSoftware\Brave-Browser\Application"))

; Open explorer
!e:: Run "explorer"

; Open/focus everything
!f:: FocusElseActivate("Everything64.exe", "C:\Program Files\Everything 1.5a")

; Open/focus VsCode
!c:: FocusElseActivate("Code.exe", LocalPath("Programs\Microsoft VS Code"))

; Open/focus obsidian
!o:: FocusElseActivate("Obsidian.exe", LocalPath("Obsidian"))

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
!Numpad1::^#Right

; Reload current script
!+r::
{
  Reload
}