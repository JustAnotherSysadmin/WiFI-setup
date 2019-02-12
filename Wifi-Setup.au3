#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         John Lucas

 Script Purpose:
   Purpose of this script:
     1) Automatically join wifi "CorpWIFI".
     2) Automatically remove the CorpGUEST guest SSID from all domain connected machines.

   Script Function:
     1) GPO copies this script to c:\scripts on the client computer during connection to wired ethernet cable
     2) GPO also copies the wifi XML config file to client computer
     3) At login, this script is run.
     4) Check is made to see if %WIFILOGSETUP% exists, if so, skip adding CorpWIFI profile
     5) When wifi profile is loaded, a file is created at %WIFILOGSETUP%
     6) remove morning pointe guest wifi

   Script Dependancies and files:
     1)  c:\scripts\wifi-CorpWIFI.xml
	 2)  c:\scripts\ihp-wifi-logfile.txt
	 3)  c:\scripts\ihp-wifi-setup.txt

#ce ----------------------------------------------------------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      ___   _   _    ____   _       _   _   ____    _____   ____
;     |_ _| | \ | |  / ___| | |     | | | | |  _ \  | ____| / ___|
;      | |  |  \| | | |     | |     | | | | | | | | |  _|   \___ \
;      | |  | |\  | | |___  | |___  | |_| | | |_| | | |___   ___) |
;     |___| |_| \_|  \____| |_____|  \___/  |____/  |_____| |____/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Date.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <_XMLDomWrapper.au3>
;#include <Inet.au3>




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      _____   _   _   _   _    ____   _____   ___    ___    _   _   ____
;     |  ___| | | | | | \ | |  / ___| |_   _| |_ _|  / _ \  | \ | | / ___|
;     | |_    | | | | |  \| | | |       | |    | |  | | | | |  \| | \___ \
;     |  _|   | |_| | | |\  | | |___    | |    | |  | |_| | | |\  |  ___) |
;     |_|      \___/  |_| \_|  \____|   |_|   |___|  \___/  |_| \_| |____/
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _GetDOSOutput($sCommand)
    Local $iPID, $sOutput = ""

    $iPID = Run('"' & @ComSpec & '" /c ' & $sCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
    While 1
        $sOutput &= StdoutRead($iPID, False, False)
        If @error Then
            ExitLoop
        EndIf
        Sleep(10)
    WEnd
    Return $sOutput
 EndFunc   ;==>_GetDOSOutput


Func DoesWifiConfigExist()
   ; The purpose of this function is to check if wifi config exists
   Local $iWifiConfigExists = FileExists($gWifiConfig)
   if $iWifiConfigExists Then
      MsgBox($MB_SYSTEMMODAL, "", "The file exists." & @CRLF & "FileExist returned: " & $gWifiConfig)
	  Return True
   Else
	  MsgBox($MB_SYSTEMMODAL, "", "The file doesn't exist." & @CRLF & "FileExist returned: " & $gWifiConfig)
	  Return False
   EndIf
EndFunc   ;==> DoesWifiConfigExist


; read xml   see: https://www.autoitscript.com/forum/topic/170199-read-xml-file/
Func GetSSIDfromConfigFile($sWifiConfigTMP)
   Local $oXML = ObjCreate("Microsoft.XMLDOM")
   $oXML.load("test.xml")
   $oParameters = $oXML.SelectNodes("//Event/Parameter")
   For $oParameter In $oParameters

       $oName = $oParameter.SelectSingleNode("./Name")
       If String($oName.text) = "HoursPoweredCount" Then
           $oValue = $oParameter.SelectSingleNode("./Value")
           ConsoleWrite(String($oValue.text) & @CRLF)
           Exit
       EndIf
   Next
EndFunc ;==> GetSSIDfromConfigFile

Func IsThisSSIDcurrentlyInUse($sConfigFileSSID)

   ; netsh wlan show profiles | find "CorpWIFI"
   ; this might be helpful:  http://stackoverflow.com/questions/15685816/how-can-i-remove-empty-lines-from-wmic-output

   Return True

EndFunc ;==> IsThisSSIDcurrentlyInUse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      __  __      _      ___   _   _
;     |  \/  |    / \    |_ _| | \ | |
;     | |\/| |   / _ \    | |  |  \| |
;     | |  | |  / ___ \   | |  | |\  |
;     |_|  |_| /_/   \_\ |___| |_| \_|
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; -----------------------------------------------------------------------------------------------
; Declairation of Globals and misc stuff to get things going
; -----------------------------------------------------------------------------------------------

; This is where we log stuff that failed.
Global $gWifiLogFile = "c:\scripts\wifi-logfile.txt"
Global $gWifiLogSetup = "c:\scripts\wifi-setup.txt"
Global $gWifiConfig = "c:\scripts\wifi-config.xml"

; This is the data structure that we save to before we write that to a file
Global $gSetupLogData = ""
Global $gSSID = ""

; -----------------------------------------------------------------------------------------------
; Step 1:  Join corporate wifi.
; -----------------------------------------------------------------------------------------------

; Check to see if XML config file exists
If DoesWifiConfigExist() Then
      ; if we are at this point, the wifi-config.xml file exists
   ; now, lets read the SSID name from the config File
   Local $iConfigFileSSID = GetSSIDfromConfigFile($gWifiConfig)

   ; now, lets check if the SSID from the config file is currently in use...return true or False
   Local $iIsSSIDinUse = IsThisSSIDcurrentlyInUse($iConfigFileSSID)

   ; if the ssid in the config file is not in use; let's put it in use
   If NOT $iIsSSIDinUse Then
	  $gSetupLogData &= _GetDOSOutput("Netsh wlan add profile filename="$gWifiConfig" user=all")
   EndIf
Else
   ; Looks like we couldn't find the wifi config file!!!
   ; Let's log that wifi config file wasn't found
   ; TODO
EndIf


; -----------------------------------------------------------------------------------------------
; Step 2:  Delete "CorpGUEST"
; -----------------------------------------------------------------------------------------------

;:deleteGuestWIFI
;netsh wlan delete profile name="CorpGUEST" >> %WIFILOGFILE%
;goto end


