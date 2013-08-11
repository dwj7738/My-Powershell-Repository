Set-StrictMode -Version Latest

$lastError = $error[0]
Set-PsBreakpoint $lastError.InvocationInfo.ScriptName `
    $lastError.InvocationInfo.ScriptLineNumber
