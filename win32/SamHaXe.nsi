!define SamhaxeVersion "v1.0-mojito"
!define DevilVersion "1.7.8"
!define FreeTypeVersion "2.3.5-1"

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "FileFunc.nsh"
  !include "LogicLib.nsh"
  !include "StrFunc.nsh"
  ${StrRep}

;--------------------------------
;General

  Name "Sam HaXe"
  OutFile "..\dist\samhaxe-${SamhaxeVersion}.exe"

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
  
  Var StartMenuFolder
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\SamHaXe" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  
  !insertmacro MUI_PAGE_STARTMENU "Application" $StartMenuFolder
  
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"
  
;--------------------------------
;Installer Sections

Function .onVerifyInstDir
    FindFirst $0 $1 "$INSTDIR\*.*"
    ${While} $1 != ""
        ${If} $1 != "."
            ${If} $1 != ".."
                Abort "The installation directory should be empty or non-existent!"
            ${Endif}
        ${Endif}
        FindNext $0 $1
    ${EndWhile}
    End:
FunctionEnd

Section "Dummy Section" SecDummy

  SetOutPath $INSTDIR
  
  WriteRegStr HKCU "Software\SamHaXe" "" $INSTDIR
  
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
  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Documentation.lnk" "$INSTDIR\doc\index.html"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  RMDir /r "$INSTDIR"
  
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
    
  Delete "$SMPROGRAMS\$StartMenuFolder\Documentation.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
  RMDir "$SMPROGRAMS\$StartMenuFolder"
  
  DeleteRegKey /ifempty HKCU "Software\SamHaXe"

SectionEnd