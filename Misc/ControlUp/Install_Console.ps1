# https://github.com/BronsonMagnan/SoftwareUpdate/blob/master/ControlUpAgent.ps1

function Get-CurrentControlUpAgentVersion {
    [cmdletbinding()]
    [outputType([version])]
    param()
    $agentURL = "http://www.controlup.com/products/controlup/agent/"
    #ControlUP forces TLS 1.2 and rejects TLS 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webrequest = wget -Uri $agentURL -UseBasicParsing
    $content = $webrequest.Content
    #clean up the code into paragraph blocks
    $paragraphSections = $content.replace("`n","").replace("  ","").replace("`t","").replace("<p>","#$%^<p>").split("#$%^").trim()
    #now we are looking for the pattern <p><strong>Current agent version:</strong> 7.2.1.6</p>
    $versionLine = $paragraphSections  | where {$_ -like "*Current*agent*"}
    $splitlines = ($versionLine.replace('<','#$%^<').replace('>','>#$%^').split('#$%^')).trim()
    $pattern = "(\d+\.){3}\d+"
    $version = [Version]::new(($splitlines | select-string -Pattern $pattern).tostring())
    Write-Output $version
}

function Get-CurrentControlUpAgentURL {
    [cmdletBinding()]
    [outputType([string])]
    param(
        [validateSet("net45","net35")]
        [string]$netversion = "net45",
        [validateSet("x86","x64")]
        [string]$architecture = "x64"
    )
    $version = Get-CurrentControlUpAgentVersion
    $DownloadURL = "https://downloads.controlup.com/agent/$($version.tostring())/ControlUpAgent-$($netversion)-$($architecture)-$($version).msi"
    Write-Output $DownloadURL
}

function Get-CurrentControlUpConsoleURL {
    [cmdletBinding()]
    [outputType([string])]
    param(
        [validateSet("net45","net35")]
        [string]$netversion = "net45",
        [validateSet("x86","x64")]
        [string]$architecture = "x64"
    )
    $version = Get-CurrentControlUpAgentVersion
    $DownloadURL = "https://downloads.controlup.com/console/$($version.tostring())/ControlUp.zip"
    Write-Output $DownloadURL
}

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

$Vendor = "SmartX"
$Product = "ControlUp Console x64"
$Version = "$(Get-CurrentControlUpAgentVersion)"
$PackageName = "ControlUpConsole"
$InstallerType = "zip"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
$url = "$(Get-CurrentControlUpConsoleURL)"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version | Out-Null
    }

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source
    Expand-Archive -Path "$PackageName.$InstallerType" -DestinationPath .
    Copy-Item "ControlUpConsole.exe" -Destination 'C:\Program Files\Smart-X'
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
            Copy-Item "ControlUpConsole.exe" -Destination "C:\Program Files\Smart-X"
            CD..
            Copy-Item "ControlUp Console.lnk" -Destination "C:\Users\Public\Desktop"
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
