$var = 'hello!'

function My-Function {
    Write-Host "In the function; var contains '$var'"
    $var = 'goodbye!'
    Write-Host "In the function; var is now '$var'"
}

Write-Host "In the script; var is '$var'"
Write-Host "Running the function"
My-Function
Write-Host "Function is done"
Write-Host "In the script; var is now '$var'"
