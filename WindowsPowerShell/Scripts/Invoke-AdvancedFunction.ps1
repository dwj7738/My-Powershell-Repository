param(
    [Parameter(Mandatory = $true)]
    [ScriptBlock] $Scriptblock
    )

## Invoke the scriptblock supplied by the user.
& $scriptblock
