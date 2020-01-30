<#
.SYNOPSIS
	Set a random password on a list of accounts
.DESCRIPTION
	This script reads a list of accounts from a text file, generates a random password and then sets it on the AD user. The resulting password changes can be logged to a specified log file.
.PARAMETER Log
    Specifies that changes should be logged.
.PARAMETER LogFile
    Specifies the name of the log file. If not specified, a default name of SetRandomPassword_<DATE>.log is used.
.PARAMETER UsersFile
    Specifies the filename of the text file containing the list of users to set passwords for.
.EXAMPLE
	.\SetRandomPassword.ps1
	Shows the help screen
.EXAMPLE
	.\SetRandomPassword.ps1 -UsersFile users.txt
	Runs the script and sets random passwords for users listed in the users.txt file
.EXAMPLE
	.\SetRandomPassword.ps1 -UsersFile users.txt -Log
	Runs the script and sets random passwords for users listed in the users.txt file and logs changes to the default log file SetRandomPassword_<DATE>.log
.EXAMPLE
	.\SetRandomPassword.ps1 -UsersFile users.txt -Log -LogFile output.log
	Runs the script and sets random passwords for users listed in the users.txt file and logs changes to output.log
.NOTES
	Script:		SetRandomPassword.ps1
	Author:		Mike Daniels
	
	Changelog
		0.2		Updated script to add logging capability
		0.1		Initial rough version of the script that reads users file, generates a random password, and sets the password on the user account
.LINK
	https://blogs.technet.microsoft.com/meacoex/2011/08/04/how-to-generate-a-secure-random-password-using-powershell/
.LINK
	https://www.undocumented-features.com/2016/09/20/powershell-random-password-generator/
#>

[CmdletBinding()]

Param(
  [switch]$Log = $false,
  [string]$LogFile = "SetRandomPassword_" + (Get-Date).ToString('dd-MM-yy') + ".log",
  [string]$UsersFile = "users.txt"
)

#Set password length and minimum number of non-AlphaNumeric characters
$PWLength = 15
$PWNonAlphaNumeric = 2

#Load "System.Web" assembly in PowerShell console; necessary for using GeneratePassword functionality
$RandPassword = [Reflection.Assembly]::LoadWithPartialName("System.Web")

#If the users file exists, process changes; otherwise, show usage
If (Test-Path ($UsersFile))
{
  $Users = Get-Content -Path $UsersFile
  ForEach ($User in $Users)
  {
    #Generate random password based on set length and complexity variables
    $RandPassword = [system.web.security.membership]::GeneratePassword($PWLength,$PWNonAlphaNumeric)
    
    #Set AD account password to randomly generated password
    Set-ADAccountPassword -Identity $User -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $RandPassword -Force)
    
    #If logging is enabled, write change to log
    If ($Log)
    {
        If (Test-Path ($LogFile))
        {
            Write-Verbose "Append log entry to existing log file"
            Write-Output $User","$RandPassword | Out-File $LogFile -Append
        }
        Else
        {
            # Start new log file
            Write-Verbose "Start new log file and append log entry"
            Write-Output "AccountName,RandomPass" | Out-File $LogFile
            Write-Output $User","$RandPassword | Out-File $LogFile -Append
        }
    }
  }
}
Else
{
  Write-Host ".\SetRandomPassword.ps1 -UsersFile <users_text_file> [-Log] [-LogFile <log_file>]"
  Break
}