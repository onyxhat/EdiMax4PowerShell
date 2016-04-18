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
    $Node | Add-Member -MemberType NoteProperty -Name Credential -Value $(Get-Credential -User $Username -Password $Password)
    $Node | Add-Member -MemberType ScriptProperty -Name State -Value { Get-NodeState -Node $this }
    $Node | Add-Member -MemberType ScriptMethod -Name On -Value { Set-NodeOn -Node $this }
    $Node | Add-Member -MemberType ScriptMethod -Name Off -Value { Set-NodeOn -Node $this }

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
    [CmdletBinding()]
    Param (
        [psobject]$Node
    )

    [System.Net.ServicePointManager]::Expect100Continue = $false
    [xml]$State = $(Invoke-WebRequest -Method Post -Uri "http://$($Node.Node):10000/smartplug.cgi" -Body $On -ContentType 'text/xml' -Credential $Node.Credential).Content
    return $State.SMARTPLUG.CMD.'Device.System.Power.State'
}

function Set-NodeOff() {
    [CmdletBinding()]
    Param (
        [psobject]$Node
    )

    [System.Net.ServicePointManager]::Expect100Continue = $false
    [xml]$State = $(Invoke-WebRequest -Method Post -Uri "http://$($Node.Node):10000/smartplug.cgi" -Body $Off -ContentType 'text/xml' -Credential $Node.Credential).Content
    return $State.SMARTPLUG.CMD.'Device.System.Power.State'
}

function Get-NodeState() {
    [CmdletBinding()]
    Param (
        [psobject]$Node
    )

    [System.Net.ServicePointManager]::Expect100Continue = $false
    [xml]$State = $(Invoke-WebRequest -Method Post -Uri "http://$($Node.Node):10000/smartplug.cgi" -Body $GetState -ContentType 'text/xml' -Credential $Node.Credential).Content
    return $State.SMARTPLUG.CMD.'Device.System.Power.State'
}