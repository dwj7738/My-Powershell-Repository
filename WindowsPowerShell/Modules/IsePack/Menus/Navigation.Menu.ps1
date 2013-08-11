@{
    "Push-CurrentFileLocation" = {Push-CurrentFileLocation} | 
        Add-Member NoteProperty ShortcutKey "CONTROL+ALT+D" -PassThru
    "Close-AllOpenedFiles" = { Close-AllOpenedFiles } |
        Add-Member NoteProperty ShortcutKey "CONTROL+SHIFT+F4" -PassThru		
}    
