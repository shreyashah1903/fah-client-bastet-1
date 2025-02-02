; Defines
!define PRODUCT_NAME            "FAHClient"
!define PROJECT_NAME            "Folding@home"
!define DISPLAY_NAME            "Folding@home Client"

!define WEB_CLIENT_URL          "https://app.foldingathome.org/"

!define CLIENT_NAME             "FAHClient"
!define CLIENT_EXE              "FAHClient.exe"
!define CLIENT_ICON             "FAHClient.ico"
!define CLIENT_HOME             "..\.."

!define MENU_PATH               "$SMPROGRAMS\${PROJECT_NAME}"

!define UNINSTALLER             "Uninstall.exe"

;!define PRODUCT_CONFIG          "config.xml"
!define PRODUCT_LICENSE         "${CLIENT_HOME}\LICENSE"
!define PRODUCT_VENDOR          "foldingathome.org"
!define PRODUCT_TARGET          "${CLIENT_HOME}\%(package)s"
!define PRODUCT_VERSION         "%(version)s"
!define PRODUCT_WEBSITE         "https://foldingathome.org/"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_UNINST_KEY \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_DIR_REGKEY \
  "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}"

!define MUI_ABORTWARNING
!define MUI_ICON "${CLIENT_HOME}\images\fahlogo.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH


; Plugins
!addplugindir "plugins\ansi"


; Variables
Var AutoStart
Var UninstDir
Var DataDir
Var InstallDirText
Var DataDirText


; Includes
!include MUI2.nsh
!include nsDialogs.nsh
!include LogicLib.nsh
!include EnvVarUpdate.nsh
!include WinVer.nsh


; Config
Name "${DISPLAY_NAME} ${PRODUCT_VERSION}"
OutFile "${PRODUCT_TARGET}"
InstallDir "$PROGRAMFILES%(PACKAGE_ARCH)s\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show


; Pages
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_LICENSE "${PRODUCT_LICENSE}"
Page custom OnInstallPageEnter OnInstallPageLeave
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start Folding@home"
!define MUI_FINISHPAGE_RUN_FUNCTION OnRunFAH
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_TITLE "Instructions"
!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_INFO \
  "You may choose to save your configuration and work unit data for later \
   use or completely uninstall."
!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

RequestExecutionLevel admin


; Sections
Section -Install
  ; 32/64 bit registry
  SetRegView %(PACKAGE_ARCH)s

  ReadRegStr $UninstDir ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_DIR_REGKEY}" \
    "Path"

  ; Remove service
  IfFileExists "$UninstDir\${CLIENT_EXE}" 0 +4
    DetailPrint "Removing service, if previously installed. (This can take \
        awhile)"
    nsExec::Exec '"$UninstDir\${CLIENT_EXE}" --stop-service'
    nsExec::Exec '"$UninstDir\${CLIENT_EXE}" --uninstall-service'

  ; Terminate
  FindProcDLL::KillProc    "$UninstDir\${CLIENT_EXE}"
  FindProcDLL::WaitProcEnd "$UninstDir\${CLIENT_EXE}"
  FindProcDLL::KillProc    "$UninstDir\FAHControl.exe"
  FindProcDLL::WaitProcEnd "$UninstDir\FAHControl.exe"

  ; Remove Autostart
  Delete "$SMSTARTUP\${CLIENT_NAME}.lnk"
  Delete "$SMSTARTUP\FAHControl.lnk"

  ; Uninstall old software
  ; Avoid simply removing the whole directory as that causes subsequent file
  ; writes to fail for several seconds.
  DetailPrint "Uninstalling any conflicting Folding@home software"
  Push $INSTDIR
  Call EmptyDir

  ; Install files
  install_files:
  ClearErrors
  SetOverwrite try
  SetOutPath "$INSTDIR"
  File /oname=${CLIENT_EXE}  "${CLIENT_HOME}\fah-client.exe"
  File /oname=${CLIENT_ICON} "${CLIENT_HOME}\images\fahlogo.ico"
  File /oname=README.txt     "${CLIENT_HOME}\README.md"
  File /oname=License.txt    "${CLIENT_HOME}\LICENSE"
  File /oname=ChangeLog.txt  "${CLIENT_HOME}\CHANGELOG.md"
  %(NSIS_INSTALL_FILES)s

  IfErrors 0 +2
    MessageBox MB_RETRYCANCEL "Failed to install files.  Most likely some \
        software, possibly Folding@home is currently using one or more files \
        that the installer is trying to upgrade.  Please stop all running \
        Folding@home software and quit any applications that are using files \
        from the Folding@home installation.  Note, complete shutdown can take \
        a little while after the application has closed." \
        IDRETRY install_files IDCANCEL abort

  ; Add to PATH
  SetShellVarContext current
  ${EnvVarUpdate} $0 "PATH" "A" "HKCU" $INSTDIR

  ; Data directory
  CreateDirectory $DataDir
  AccessControl::GrantOnFile "$DataDir" "(S-1-5-32-545)" "FullAccess"

  ; Delete old desktop links
  Delete "$DESKTOP\FAHControl.lnk"
  Delete "$DESKTOP\Folding@home.lnk"

  ; Desktop link
  CreateShortCut "$DESKTOP\Folding @Home.lnk" "$INSTDIR\${CLIENT_EXE}" \
    '--open-web-control' "$INSTDIR\${CLIENT_ICON}"

  ; Write uninstaller
write_uninstaller:
  ClearErrors
  WriteUninstaller "$INSTDIR\${UNINSTALLER}"
  IfErrors 0 +2
    MessageBox MB_ABORTRETRYIGNORE "Failed to create uninstaller" \
      IDABORT abort IDRETRY write_uninstaller

  ; Save uninstall information
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "UninstallString" "$INSTDIR\${UNINSTALLER}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayIcon" "$INSTDIR\${CLIENT_ICON}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "URLInfoAbout" "${PRODUCT_WEBSITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "Publisher" "${PRODUCT_VENDOR}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_DIR_REGKEY}" "" \
    "$INSTDIR\${CLIENT_EXE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_DIR_REGKEY}" "Path" \
    "$INSTDIR"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DataDirectory" $DataDir

  ; Start Menu
  RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
  RMDir /r "${MENU_PATH}"
  CreateDirectory "${MENU_PATH}"
  CreateShortCut "${MENU_PATH}\Folding@home.lnk" "$INSTDIR\${CLIENT_EXE}" \
    '--open-web-control' "$INSTDIR\${CLIENT_ICON}"
  CreateShortCut "${MENU_PATH}\Data Directory.lnk" "$DataDir"
  CreateShortCut "${MENU_PATH}\Homepage.lnk" "$INSTDIR\Homepage.url"
  CreateShortCut "${MENU_PATH}\Uninstall.lnk" "$INSTDIR\${UNINSTALLER}"

  ; Internet shortcuts
  WriteIniStr "$INSTDIR\Homepage.url" "InternetShortcut" "URL" \
    "${PRODUCT_WEBSITE}"

  ;  Autostart
  Delete "$SMSTARTUP\${CLIENT_NAME}.lnk" # Clean up old link
  ${If} $AutoStart == ${BST_CHECKED}
    CreateShortCut "$SMSTARTUP\Folding@home.lnk" "$INSTDIR\${CLIENT_EXE}" "" \
      "$INSTDIR\${CLIENT_ICON}"
  ${Else}
    Delete "$SMSTARTUP\Folding@home.lnk"
  ${EndIf}

  Return

abort:
  Abort
SectionEnd


Section -un.Program
  ; Shutdown running client
  DetailPrint "Shutting down any local clients"
  nsExec::Exec '"$INSTDIR\${CLIENT_EXE}" --send-command=shutdown'

  ; Menu
  RMDir /r "${MENU_PATH}"

  ; Autostart
  Delete "$SMSTARTUP\${CLIENT_NAME}.lnk"

  ; Desktop
  Delete "$DESKTOP\Folding @Home.lnk"

  ; Remove from PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKCU" $INSTDIR

  ; Registry
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

  ; Program directory
  remove_dir:
  ClearErrors
  RMDir /r "$INSTDIR"
  IfErrors 0 +3
    IfSilent +2
    MessageBox MB_RETRYCANCEL "Failed to remove $INSTDIR.  Please stop all \
      running Folding@home software." IDRETRY remove_dir
SectionEnd


Section /o un.Data
  RMDir /r $DataDir
SectionEnd


; Functions
Function .onInit
  ${IfNot} ${AtLeastWinXP}
    MessageBox MB_OK "Windows XP or newer required"
    Quit
  ${EndIf}
FunctionEnd


Function EmptyDir
  Pop $0

  FindFirst $1 $2 $0\*.*
  empty_dir_loop:
    StrCmp $2 "" empty_dir_done

    ; Skip . and ..
    StrCmp $2 "." empty_dir_next
    StrCmp $2 ".." empty_dir_next

    ; Remove subdirectories
    IfFileExists $0\$2\*.* 0 +3
    RmDir /r $0\$2
    Goto empty_dir_next

    ; Remove file
    Delete $INSTDIR\$2

    ; Next
    empty_dir_next:
    FindNext $1 $2
    Goto empty_dir_loop

  ; Done
  empty_dir_done:
  FindClose $1
FunctionEnd


Function ValidPath
  Pop $0

  ; Get Length
  StrLen $1 $0

loop:
  ; Check length
  StrCmp $1 0 pass

  ; Get next char
  StrCpy $2 $0 1
  StrCpy $0 $0 "" 1

  ; Check for invalid characters
  StrCmp $2 "@" fail
  StrCmp $2 "?" fail
  StrCmp $2 "*" fail
  StrCmp $2 "|" fail
  StrCmp $2 "<" fail
  StrCmp $2 ">" fail
  StrCmp $2 "'" fail
  StrCmp $2 '"' fail

  ; Decrement length
  IntOp $1 $1 - 1
  Goto loop

pass:
  Return

fail:
  MessageBox MB_OK `The following characters are not allowed: @?*|<>'"`
  Abort
FunctionEnd


Function OnInstallPageEnter
  ; Init data dir
  ${If} $DataDir == ""
    ReadRegStr $DataDir ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
      "DataDirectory"
  ${EndIf}

  ${If} $DataDir == ""
    StrCpy $DataDir "$APPDATA\${PRODUCT_NAME}"
  ${EndIf}

  !insertmacro MUI_HEADER_TEXT "Installation Options" ""

  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ; Client Startup
  ${NSD_CreateCheckbox} 5%% 8u 90%% 12u \
    "Automatically start at login time. (Recommended)"
  Pop $0
  ${NSD_SetState} $0 ${BST_CHECKED}
  ${NSD_OnClick} $0 OnAutoStartChange

  ; Install Path
  ${NSD_CreateGroupBox} 5%% 35u 90%% 34u "Install Path"
  Pop $0

    ${NSD_CreateDirRequest} 10%% 49u 59%% 12u "$INSTDIR"
    Pop $InstallDirText

    ${NSD_CreateBrowseButton} 70%% 49u 20%% 12u "Browse..."
    Pop $0
    ${NSD_OnClick} $0 OnInstallDirBrowse

  ; Data Path
  ${NSD_CreateGroupBox} 5%% 79u 90%% 34u "Data Path"
  Pop $0

    ${NSD_CreateDirRequest} 10%% 93u 59%% 12u "$DataDir"
    Pop $DataDirText

    ${NSD_CreateBrowseButton} 70%% 93u 20%% 12u "Browse..."
    Pop $0
    ${NSD_OnClick} $0 OnDataDirBrowse

  nsDialogs::Show
FunctionEnd


Function OnInstallDirBrowse
    ${NSD_GetText} $InstallDirText $0
    nsDialogs::SelectFolderDialog "Select Install Directory" "$0"
    Pop $0
    ${If} $0 != error
        ${NSD_SetText} $InstallDirText "$0"
    ${EndIf}
FunctionEnd


Function OnDataDirBrowse
    ${NSD_GetText} $DataDirText $0
    nsDialogs::SelectFolderDialog "Select Data Directory" "$0"
    Pop $0
    ${If} $0 != error
        ${NSD_SetText} $DataDirText "$0"
    ${EndIf}
FunctionEnd


Function OnInstallPageLeave
  ; Validate install dir
  Push $INSTDIR
  Call ValidPath

  ; Validate data dir
  Push $DataDir
  Call ValidPath

  StrLen $0 $INSTDIR
  StrCpy $1 $DataDir $0
  StrCmp $INSTDIR $1 0 exit

  MessageBox MB_OKCANCEL \
    "WARNING: If the data directory is a sub-directory of the install \
     directory it will always be removed at uninstall time." IDOK exit
  Abort

exit:
FunctionEnd


Function OnAutoStartChange
  Pop $0
  ${NSD_GetState} $0 $AutoStart
FunctionEnd


Function OnRunFAH
  ${If} $AutoStart == ${BST_CHECKED}
    # Also opens Web Control
    ExecShell "open" "${MENU_PATH}\Folding@home.lnk"
  ${EndIf}
FunctionEnd


Function un.onInit
  ; Get Data Directory
  ReadRegStr $DataDir ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DataDirectory"
FunctionEnd
