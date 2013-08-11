Function Get-ISEVariable
{
  $text = $psISE.CurrentFile.Editor.Text

  [System.Management.Automation.PSParser]::Tokenize($text, [ref]$null) |
  Where-Object { $_.Type -eq 'Variable' } |
  ForEach-Object {
    $rv = 1 | Select-Object -Property Line, Name, Code
    $rv.Name = $text.Substring($_.Start, $_.Length)
    $rv.Line = $_.StartLine

    $psISE.CurrentFile.Editor.SetCaretPosition($_.StartLine,1)
    $psISE.CurrentFile.Editor.SelectCaretLine()
    $rv.Code = $psISE.CurrentFile.Editor.SelectedText.Trim()

    $rv
  }
}