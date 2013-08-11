Import-Module PSWorkflow

workflow Test-Workflow {
    
    $a = 1
    $a

    $a++
    $a

    $b = $a + 2
    $b

}

Test-Workflow
