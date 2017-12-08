#NoTrayIcon
#RequireAdmin
#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#pragma compile(Out, Release\UID Extractor.exe)
#pragma compile(Icon, Resources\Icon.ico)
#pragma compile(Console, true)
#pragma compile(CompanyName, www.FaridAghili.ir)
#pragma compile(FileDescription, UID Extractor)
#pragma compile(FileVersion, 1.1.0.0)
#pragma compile(InternalName, UID Extractor)
#pragma compile(LegalCopyright, Copyright © 2016 www.FaridAghili.ir. All rights reserved.)
#pragma compile(OriginalFilename, UID Extractor.exe)
#pragma compile(ProductName, UID Extractor)
#pragma compile(ProductVersion, 1.1.0.0)

#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /sf=1 /sv=1 /rm /rsln

#AutoIt3Wrapper_Res_Remove=RT_ICON, 1, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 7, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 8, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 9, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 10, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 11, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 12, 2057
#AutoIt3Wrapper_Res_Remove=RT_STRING, 313, 2057
#AutoIt3Wrapper_Res_Remove=RT_GROUPICON, 169, 2057

AutoItSetOption('MustDeclareVars', 1)
AutoItSetOption('WinWaitDelay', 50)

#include <APIErrorsConstants.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>

Global Const $APP_NAME = 'UID Extractor'
Global Const $APP_VERSION = 1.1

Global $hMutex = CreateMutex(Null, True, $APP_NAME & ': Running')

If GetLastError() = $ERROR_ALREADY_EXISTS Then
	CloseHandle($hMutex)
	Exit
EndIf

SetConsoleTitle($APP_NAME)
ConsoleWrite(StringFormat('%s v%.1f by Farid Aghili\n\nwww.FaridAghili.ir', $APP_NAME, $APP_VERSION))

OnAutoItExitRegister(OnExit)

Main()
MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), $APP_NAME, 'All UID(s) successfully extracted.')

Func Main()
	Local $sStart = IniRead('Config.ini', $APP_NAME, 'Start', '0')
	Local $sEnd = IniRead('Config.ini', $APP_NAME, 'End', '0')
	Local $sMembership = IniRead('Config.ini', $APP_NAME, 'Membership', '')
	Local $sLocation = IniRead('Config.ini', $APP_NAME, 'Location', '')

	Local $iStart = Int($sStart, 1)
	Local $iEnd = Int($sEnd, 1)

	If $iStart And $iEnd Then
		If $iStart > $iEnd Then
			MsgBox(BitOR($MB_OK, $MB_ICONERROR), $APP_NAME, 'End UID cannot be less than Start UID.')
			Exit
		EndIf
	Else
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), $APP_NAME, 'Start and/or End UID not specified.')
		Exit
	EndIf

	Local $hWnd = WinGetHandle('[Class:GG_GUIDE_WIN]')
	If @error Then
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), $APP_NAME, 'Unable to find Garena window.')
		Exit
	EndIf

	Local $iCounter = 0
	Local $iTotal = $iEnd - $iStart + 1

	Local $mMap[]
	For $iUid = $iStart To $iEnd
		$iCounter += 1
		SetConsoleTitle(StringFormat('%s - %d/%d', $APP_NAME, $iCounter, $iTotal))

		$mMap = GetInfoByUid($hWnd, $iUid)
		If IsMap($mMap) Then
			If $sMembership And StringInStr($mMap['Membership'], $sMembership, $STR_NOCASESENSEBASIC) = 0 Then
				ContinueLoop
			EndIf

			If $sLocation And StringCompare($mMap['Location'], $sLocation, $STR_NOCASESENSEBASIC) <> 0 Then
				ContinueLoop
			EndIf

			FileWrite('Full Info.txt', $mMap['UID'] & @CRLF & $mMap['Username'] & @CRLF & $mMap['Membership'] & @CRLF & $mMap['Location'] & @CRLF & @CRLF)
			FileWrite('Usernames.txt', $mMap['Username'] & @CRLF)
		EndIf
	Next
EndFunc

Func GetInfoByUid($hWnd, $iUid)
	ControlClick($hWnd, '', 1004, 'Primary') ; Search User

	Local $hSearchUser = WinWait('Search User', 'By ID', 5)
	If $hSearchUser = 0 Then
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), $APP_NAME, 'Unable to find Search User window.')
		Exit
	EndIf

	WinMove($hSearchUser, '', 0, 0, 1, 1)

	ControlClick($hSearchUser, '', 1174, 'Primary') ; By Id
	ControlSetText($hSearchUser, '', 1145, $iUid)
	ControlClick($hSearchUser, '', 1, 'Primary') ; OK

	Local $hUserProfile = 0

	Local $hTimer = TimerInit()
	Do
		If TimerDiff($hTimer) > 5000 Then
			MsgBox(BitOR($MB_OK, $MB_ICONERROR), $APP_NAME, 'Unable to find User Profile window.')
			Exit
		EndIf

		If ControlGetText($hSearchUser, '', 1176) = StringFormat("Sorry, %d can't be found!", $iUid) Then
			ControlClick($hSearchUser, '', 2, 'Primary') ; Cancel
			Return Null
		EndIf

		$hUserProfile = WinWait('User Profile', 'Fitting Room', 1)
	Until $hUserProfile

	WinMove($hUserProfile, '', 0, 0, 1, 1)

	Local $mAccountInfo[]
	$mAccountInfo['UID'] = $iUid
	$mAccountInfo['Username'] = ControlGetText($hUserProfile, '', 1098)
	$mAccountInfo['Membership'] = ControlGetText($hUserProfile, '', 1197)
	$mAccountInfo['Location'] = ControlGetText($hUserProfile, '', 1198)

	WinClose($hUserProfile)

	Return $mAccountInfo
EndFunc

Func OnExit()
	CloseHandle($hMutex)
EndFunc

Func CreateMutex($tMutexAttributes, $bInitialOwner, $sName)
	Return DllCall('kernel32.dll', 'HANDLE', 'CreateMutexA', _
			'STRUCT*', $tMutexAttributes, _
			'BOOL', $bInitialOwner, _
			'STR', $sName)[0]
EndFunc

Func CloseHandle($hObject)
	DllCall('kernel32.dll', 'BOOL', 'CloseHandle', _
			'HANDLE', $hObject)
EndFunc

Func GetLastError()
	Return DllCall('kernel32.dll', 'DWORD', 'GetLastError')[0]
EndFunc

Func SetConsoleTitle($sConsoleTitle)
	DllCall('kernel32.dll', 'BOOL', 'SetConsoleTitleA', _
			'STR', $sConsoleTitle)
EndFunc