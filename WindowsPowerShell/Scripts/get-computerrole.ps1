$a = gwmi -Class win32_ComputerSystem 
switch ($a.DomainRole)
    {
    0 {$b = "StandAlone Workstation"}
    1 { $b = "Member Workstation"}
    2 { $b = "Standalone Server" }
    3 { $b = "Member Server" }
    4 { $b = "Backup Domain Controller"}
    5 { $b = "Primary Domainn Controller"}
    Default {$b = "Comupter typer Could not be Determinied"}
    }
$b
