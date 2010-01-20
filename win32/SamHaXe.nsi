!define SamhaxeVersion "v1.0-mojito"
!define DevilVersion "1.7.8"
!define FreeTypeVersion "2.3.5-1"

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  
  !include "StrFunc.nsh"
  ${StrRep}

;--------------------------------
;General

  Name "Sam HaXe"
  OutFile "..\dist\SamHaXe-${SamhaxeVersion}.exe"

  ;Default installation folder
  InstallDir $PROGRAMFILES\SamHaXe

  ;Request application privileges for Windows Vista
  RequestExecutionLevel user

;--------------------------------
;Interface Configuration

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "logo.bmp"
  !define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
  !define MUI_ABORTWARNING
 
;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Dummy Section" SecDummy

  SetOutPath $INSTDIR
  
  File ..\bin\SamHaXe.exe
  File ..\samhaxe.conf.xml.template
  File /r ..\bin\modules
  File /r ..\doc
  
  File "libs\DevIL-${DevilVersion}\*.*"
  File "libs\freetype-${FreeTypeVersion}\*.*"
  File "libs\Dependencies\*.*"
  
  File LICENSE.txt
  
  FileOpen $0 $INSTDIR\samhaxe.conf.xml.template r
  FileOpen $1 $INSTDIR\samhaxe.conf.xml w
  
  nextline:
    FileRead $0 $2
    IfErrors done
    ${StrRep} $3 $2 "##PATH##" $INSTDIR\modules
    FileWrite $1 $3
    goto nextline
  done:
  FileClose $0
  FileClose $1
  
  Delete $INSTDIR\samhaxe.conf.xml.template
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  RMDir /r "$INSTDIR"

SectionEnd