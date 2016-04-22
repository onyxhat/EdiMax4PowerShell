EdiMax4PowerShell
=================
PowerShell module to control EdiMax Smartplugs SP-1101W (and Higher) using object methods.


###Requirements
* [PowerShell v4.0+/WMF 4.0](http://www.microsoft.com/en-us/download/details.aspx?id=40855)


###Getting Started
Copy psm1/psd1 module files into your __$env:PSModulePath__ or directly import using [Import-Module](http://technet.microsoft.com/en-us/library/hh849725.aspx). Once imported the commands __Add-EdiMaxNode__ & __Get-EdiMaxNodes__ will be available.

Register nodes using __Add-EdiMaxNode__ -NodeAddress <FQDN or IP> -Username <Username [Default=admin]> -Password <Password [Default=1234]>

Nodes are added to the Object collection for retrieval using...

Retrieve registered nodes using __Get-EdiMaxNodes__ which will return the array of registered nodes.


###Object Definitions
|Name        |MemberType     |Definition|
|:----       |:----------    |:----------|
|Node        |NoteProperty   |System.string|
|State       |ScriptProperty |System.string [On/Off]|
|Uri         |NoteProperty   |System.string|
|Credential  |NoteProperty   |System.Security.SecureString|
|On          |NoteProperty   |System.Object On()|
|Off         |NoteProperty   |System.Object Off()|
|Toggle      |NoteProperty   |System.Object Toggle()|


###Control Methods
* On() - Change State() to "On"
* Off() - Change State() to "Off"
* Toggle() - Invert State(); On=>Off, Off=>On