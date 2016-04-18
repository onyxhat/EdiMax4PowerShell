[psobject[]]$global:EdiMaxNodes = $null

$GetState = @'
<?xml version="1.0" encoding="UTF8"?>
<SMARTPLUG id="edimax">
  <CMD id="get">
    <Device.System.Power.State></Device.System.Power.State>
  </CMD>
</SMARTPLUG>
'@

$On = @'
<?xml version="1.0" encoding="utf-8"?>
<SMARTPLUG id="edimax">
  <CMD id="setup">
    <Device.System.Power.State>ON</Device.System.Power.State>
  </CMD>
</SMARTPLUG>
'@

$Off = @'
<?xml version="1.0" encoding="utf-8"?>
<SMARTPLUG id="edimax">
  <CMD id="setup">
    <Device.System.Power.State>OFF</Device.System.Power.State>
  </CMD>
</SMARTPLUG>
'@

function Get-Credential() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

	$sPassword = ConvertTo-SecureString $Password -AsPlainText -Force
	$Credential = New-Object System.Management.Automation.PSCredential($User, $sPassword)

    return $Credential
}

function New-NodeObject() {
    [CmdletBinding()]
    Param (
        [string]$NodeAddress,
        [string]$Username,
        [string]$Password
    )

    $defaultProperties = @('Node','State')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    $Node = New-Object -TypeName psobject

    $Node | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $Node | Add-Member -MemberType NoteProperty -Name Node -Value $NodeAddress
    $Node | Add-Member -MemberType NoteProperty -Name Uri -Value "http://${NodeAddress}:10000/smartplug.cgi"
    $Node | Add-Member -MemberType NoteProperty -Name Credential -Value $(Get-Credential -User $Username -Password $Password)
    $Node | Add-Member -MemberType ScriptProperty -Name State -Value { Get-NodeState }
    $Node | Add-Member -MemberType ScriptMethod -Name On -Value { Set-NodeOn }
    $Node | Add-Member -MemberType ScriptMethod -Name Off -Value { Set-NodeOff }
    $Node | Add-Member -MemberType ScriptMethod -Name Toggle -Value { Toggle-NodeState }

    return $Node
}

function Add-EdiMaxNode() {
    [CmdletBinding()]
    Param (
        [ValidateScript({ Test-Connection $_ -Count 1 })]
        [string]$NodeAddress,
        [string]$Username = "admin",
        [string]$Password = "1234"
    )

    [psobject[]]$global:EdiMaxNodes += New-NodeObject -NodeAddress $NodeAddress -Username $Username -Password $Password

    return $global:EdiMaxNodes
}

function Get-EdiMaxNodes() {
    return $global:EdiMaxNodes
}

function Set-NodeOn() {
    [System.Net.ServicePointManager]::Expect100Continue = $false
    Invoke-WebRequest -Method Post -Uri $this.Uri -Body $On -ContentType 'text/xml' -Credential $this.Credential | Out-Null
}

function Set-NodeOff() {
    [System.Net.ServicePointManager]::Expect100Continue = $false
    Invoke-WebRequest -Method Post -Uri $this.Uri -Body $Off -ContentType 'text/xml' -Credential $this.Credential | Out-Null
}

function Get-NodeState() {
    [System.Net.ServicePointManager]::Expect100Continue = $false
    [xml]$State = $(Invoke-WebRequest -Method Post -Uri $this.Uri -Body $GetState -ContentType 'text/xml' -Credential $this.Credential).Content
    return $State.SMARTPLUG.CMD.'Device.System.Power.State'
}

function Toggle-NodeState() {
    Switch ($this.State) {
        "ON" { $this.Off() }
        "OFF" { $this.On() }
    }
}