# Bronson (c) 2018 This will download the Adobe Stuff

$ftp = "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/"

# We have to use .NET to read a directory listing from FTP, it is different than downloading a file.
# Original C# code at https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-list-directory-contents-with-ftp

$request = [System.Net.FtpWebRequest]::Create($ftp);
$request.Credentials = [System.Net.NetworkCredential]::new("anonymous", "password");
$request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails;
[System.Net.FtpWebResponse]$response = [System.Net.FtpWebResponse]$request.GetResponse();
[System.IO.Stream]$responseStream = $response.GetResponseStream();
[System.IO.StreamReader]$reader = [System.IO.StreamReader]::new($responseStream);
$DirList = $reader.ReadToEnd()
$reader.Close()
$response.close()

# Split into Lines, currently it is one big string.
$DirByLine = $DirList.split("`n")

# Get the token containing the folder name.
$folders = @()
foreach ($line in $DirByLine ) { 
    $endtoken = ($line.split(' '))[-1]
    #filter out non version folder names
    if ($endtoken -match "[0-9]") {
        $folders += $endtoken
    }
}

# Sort the folders by newest first, and select the first 1, and remove the newline whitespace at the end.
$currentfolder = ($folders | sort -Descending | select -First 1).trim()

# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Adobe"
$Product = "Reader DC"
$PackageName = "AcroRdrDC"
$Version = "$currentfolder"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/sAll /msi /norestart /quiet ALLUSERS=1 EULA_ACCEPT=YES'
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if ( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    $EXEDownload = "$($ftp)$($currentfolder)`/AcroRdrDC$($currentfolder)_en_US.exe"
    $filename = ($EXEDownload.split("/"))[-1]
    wget -uri $EXEDownload -outfile .\$filename
}
Else {
    Write-Verbose "File exists. Skipping Download." -Verbose
}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$filename" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
Unregister-ScheduledTask -TaskName "Adobe Acrobat Update Task" -Confirm:$false
cmd.exe /c "reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cWelcomeScreen" /f /v bShowWelcomeScreen /t REG_DWORD /d 0"
cmd.exe /c "reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" /f /v bUsageMeasurement /t REG_DWORD /d 0"
sc.exe config AdobeARMservice start= disabled

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
