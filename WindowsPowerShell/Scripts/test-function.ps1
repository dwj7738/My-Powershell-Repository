Function Test-Function
{
  param
  (
    [Parameter(ValueFromPipeline=$true)]
    [Int] $Number,

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Int] $Number2
  )

  Process
  {
    "Doing something with $Number and $Number2"
  }
} 
