#requires -Version 3 
<# 
 
        .NOTES   
 
        File Name       : Get-Local_Groups_And_Users_From_Remote.ps1   
        Version         : 0.01
        Author          : CARLJ@MSN.COM
        Reviewer        : SOME OTHER PERSON
        Requires        : PowerShell V 3.0
 
        .LINK   
 
        SOME URL
         
        .LINK   
 
        SOME OTHER URL
         
        .SYNOPSIS 
 
        THIS IS A SCRIPT THAT DOES SOMETHING 
 
        .DESCRIPTION 
 
        THIS SCRIPT DOES SOMETHING IMPORTANT AND HERE IS MORE DETAIL ON WHAT AND HOW
 
        .PARAMETER PARAMETER1
         THIS IS THE FIRST PARAMETER
         
        .PARAMETER PARAMETER2
         THIS IS THE NEXT PARAMETER
         
        .EXAMPLE  
         .\FILENAME.ps1 
         FIRST EXAMPLE USAGE
 
        .EXAMPLE  
         .\FILENAME.ps1 -PARAMETER1 
         SECOND EXAMPLE USAGE
 
#> 

$SystemUser      = @()
$SystemGroups    = @()
$AllSystemUser   = @()
$AllSystemGroups = @()
$AllDSUserInfo   = @()
$AllDSGroupInfo  = @()

$Systems = (Get-Content .\computers.txt)

Foreach($system in $Systems){
   Try {
    $SystemUser = Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" -Filter "LocalAccount='$True'" -ComputerName $system | Select-Object *
        $SystemUserInfo = New-Object PSCustomObject -Property @{
        'ComputerName'           = $SystemUser.PSComputerName;
        'LocalAccount'           = $SystemUser.LocalAccount;
        'Domain'                 = $SystemUser.Domain;
        'UserName'               = $SystemUser.Name;
        'UserSID'                = $SystemUser.SID;
        'Disabled'               = $SystemUser.Disabled;
        'AccountType'            = $SystemUser.AccountType;
        'Description'            = $SystemUser.Description;
        'PasswordRequired'       = $SystemUser.PasswordRequired;
        'PasswordExpires'        = $SystemUser.PasswordExpires;
        }
      $AllSystemUser += $SystemUserInfo; $SystemUserInfo = $null   
    } 
    Catch {
        Write-Warning -Message "$($_.Exception.Message)"
        }
}

Foreach($system in $Systems){
   Try {
   $SystemGroups = Get-WmiObject -Class Win32_Group -Namespace "root\cimv2" -Filter "LocalAccount='$True'" -ComputerName $system | Select-Object *
        $SystemGroupsInfo = New-Object PSCustomObject -Property @{
        'ComputerName'           = $SystemGroups.PSComputerName;
        'LocalGroupName'         = $SystemGroups.Name;       
        'Description'            = $SystemGroups.Description;
        'SID'                    = $SystemGroups.SID;
        }
      $AllSystemGroups += $SystemGroupsInfo; $SystemGroupsInfo = $null
    } 
    Catch {
    Write-Warning -Message "$($_.Exception.Message)"
        }
}

for ($i=0; $i -lt $AllSystemUser.length; $i++){
    for ($j = 0; $j -lt $AllSystemUser[$i].UserName.Count; $j++) {
    Try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
        $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $AllSystemUser[$i].domain[$j])
        $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($PrincipalContext, $AllSystemUser[$i].UserName[$j])
        $DSUserInfo = New-Object PSCustomObject -Property @{
        'ComputerName'                      = $AllSystemUser[$i].domain[$j]
        'Enabled'                           = $User.Enabled;
        'AccountLockoutTime'                = $User.AccountLockoutTime;
        'LastLogon'                         = $User.LastLogon;
        'PermittedWorkstations'             = $User.PermittedWorkstations;
        'PermittedLogonTimes'               = $User.PermittedLogonTimes;
        'AccountExpirationDate'             = $User.PasswordExpirationDate;
        'SmartcardLogonRequired'            = $User.SmartcardLogonRequired;
        'DelegationPermitted'               = $User.DelegationPermitted;
        'BadLogonCount'                     = $User.BadLogonCount;
        'LastPasswordSet'                   = $User.LastPasswordSet;
        'LastBadPasswordAttempt'            = $User.LastBadPasswordAttempt
        'PasswordNotRequired'               = $User.PasswordNotRequired
        'PasswordNeverExpires'              = $User.PasswordNeverExpires
        'UserCannotChangePassword'          = $User.UserCannotChangePassword
        'AllowReversiblePasswordEncryption' = $User.AllowReversiblePasswordEncryption
        'ContextType'                       = $User.ContextType
        'Description'                       = $User.Description
        'DisplayName'                       = $User.DisplayName
        'SamAccountName'                    = $User.SamAccountName
        'Sid'                               = $User.Sid
        'Name'                              = $User.Name
        }
        $AllDSUserInfo += $DSUserInfo; $DSUserInfo = $null  
    }
    Catch {
        Write-Warning -Message "$($_.Exception.Message)"
          }
        }
}

for ($i=0; $i -lt $AllSystemGroups.length; $i++){
    for ($j = 0; $j -lt $AllSystemGroups[$i].LocalGroupName.Count; $j++) {
    Try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
        $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $AllSystemGroups[$i].ComputerName[$j])
        $Group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($PrincipalContext, $AllSystemGroups[$i].LocalGroupName[$j])
        $GroupMembers = $Group.GetMembers().Members.Name
        $DSGroupInfo = New-Object PSCustomObject -Property @{
        'ComputerName'      = $AllSystemGroups[$i].ComputerName[$j]
        'GroupMembers'      = $GroupMembers
        'IsSecurityGroup'   = $Group.IsSecurityGroup
        'GroupScope'        = $Group.GroupScope
        'ContextType'       = $Group.ContextType
        'Description'       = $Group.Description
        'DisplayName'       = $Group.DisplayName
        'SamAccountName'    = $Group.SamAccountName
        'UserPrincipalName' = $Group.UserPrincipalName
        'Sid'               = $Group.Sid
        'Guid'              = $Group.Guid
        'DistinguishedName' = $Group.DistinguishedName
        }
        $AllDSGroupInfo += $DSGroupInfo; $DSGroupInfo = $null ; $GroupMembers = $null
    }
    Catch {
        Write-Warning -Message "$($_.Exception.Message)"
        }
    }
}

$AllDSUserInfo | 
Select-Object ComputerName,ContextType,Name,SamAccountName,DisplayName,Sid,Description,Enabled,LastLogon,PasswordNotRequired,PasswordNeverExpires,LastPasswordSet, `
              BadLogonCount,LastBadPasswordAttempt,AccountLockoutTime,PermittedWorkstations,PermittedLogonTimes,AccountExpirationDate,SmartcardLogonRequired, `
              DelegationPermitted,UserCannotChangePassword,AllowReversiblePasswordEncryption |
Out-GridView

$AllDSGroupInfo | 
Select-Object ComputerName,ContextType,SID,GroupScope,IsSecurityGroup,SamAccountName,Guid,DisplayName,DistinguishedName,Description,UserPrincipalName,GroupMembers  | 
Out-GridView