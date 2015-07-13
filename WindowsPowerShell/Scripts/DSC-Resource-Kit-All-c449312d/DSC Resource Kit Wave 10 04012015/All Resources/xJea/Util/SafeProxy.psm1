# Copyright © 2014, Microsoft Corporation. All rights reserved.

<#
This Proxy for Sort-Object Does exactly 1 thing - it strongly types Property to STRING[]
which denudes it of the opportunity for exploits (can't take a scriptblock)
#>
function Sort-Object
{
[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113403', RemotingCapability='None')]
param(
    [switch]
    ${Descending},

    [switch]
    ${Unique},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(Position=0)]
    [System.String[]]
    ${Property},

    [string]
    ${Culture},

    [switch]
    ${CaseSensitive})

    begin
                                                        {
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Sort-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
    }

    process
                        {
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
    }

    end
                        {
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
    }
<#

.ForwardHelpTargetName Sort-Object
.ForwardHelpCategory Cmdlet

#>

}

function where-object
{
[CmdletBinding(DefaultParameterSetName='EqualSet', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113423', RemotingCapability='None')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(ParameterSetName='MatchSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='NotContainsSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='InSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveInSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='NotInSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveNotInSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='IsSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='LessOrEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='GreaterOrEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveMatchSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='NotMatchSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='NotLikeSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveContainsSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='LikeSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='ContainsSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='IsNotSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveLikeSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='EqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='NotEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='GreaterThanSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='LessThanSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Property},

    [Parameter(ParameterSetName='CaseSensitiveLikeSet', Position=1)]
    [Parameter(ParameterSetName='GreaterThanSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveMatchSet', Position=1)]
    [Parameter(ParameterSetName='NotInSet', Position=1)]
    [Parameter(ParameterSetName='LikeSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveNotInSet', Position=1)]
    [Parameter(ParameterSetName='IsSet', Position=1)]
    [Parameter(ParameterSetName='NotLikeSet', Position=1)]
    [Parameter(ParameterSetName='IsNotSet', Position=1)]
    [Parameter(ParameterSetName='LessOrEqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Position=1)]
    [Parameter(ParameterSetName='MatchSet', Position=1)]
    [Parameter(ParameterSetName='NotMatchSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Position=1)]
    [Parameter(ParameterSetName='ContainsSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveContainsSet', Position=1)]
    [Parameter(ParameterSetName='NotContainsSet', Position=1)]
    [Parameter(ParameterSetName='LessThanSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Position=1)]
    [Parameter(ParameterSetName='InSet', Position=1)]
    [Parameter(ParameterSetName='GreaterOrEqualSet', Position=1)]
    [Parameter(ParameterSetName='EqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveEqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Position=1)]
    [Parameter(ParameterSetName='NotEqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Position=1)]
    [Parameter(ParameterSetName='CaseSensitiveInSet', Position=1)]
    [System.Object]
    ${Value},

    [Parameter(ParameterSetName='EqualSet')]
    [Alias('IEQ')]
    [switch]
    ${EQ},

    [Parameter(ParameterSetName='CaseSensitiveEqualSet', Mandatory=$true)]
    [switch]
    ${CEQ},

    [Parameter(ParameterSetName='NotEqualSet', Mandatory=$true)]
    [Alias('INE')]
    [switch]
    ${NE},

    [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Mandatory=$true)]
    [switch]
    ${CNE},

    [Parameter(ParameterSetName='GreaterThanSet', Mandatory=$true)]
    [Alias('IGT')]
    [switch]
    ${GT},

    [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Mandatory=$true)]
    [switch]
    ${CGT},

    [Parameter(ParameterSetName='LessThanSet', Mandatory=$true)]
    [Alias('ILT')]
    [switch]
    ${LT},

    [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Mandatory=$true)]
    [switch]
    ${CLT},

    [Parameter(ParameterSetName='GreaterOrEqualSet', Mandatory=$true)]
    [Alias('IGE')]
    [switch]
    ${GE},

    [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Mandatory=$true)]
    [switch]
    ${CGE},

    [Parameter(ParameterSetName='LessOrEqualSet', Mandatory=$true)]
    [Alias('ILE')]
    [switch]
    ${LE},

    [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Mandatory=$true)]
    [switch]
    ${CLE},

    [Parameter(ParameterSetName='LikeSet', Mandatory=$true)]
    [Alias('ILike')]
    [switch]
    ${Like},

    [Parameter(ParameterSetName='CaseSensitiveLikeSet', Mandatory=$true)]
    [switch]
    ${CLike},

    [Parameter(ParameterSetName='NotLikeSet', Mandatory=$true)]
    [Alias('INotLike')]
    [switch]
    ${NotLike},

    [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Mandatory=$true)]
    [switch]
    ${CNotLike},

    [Parameter(ParameterSetName='MatchSet', Mandatory=$true)]
    [Alias('IMatch')]
    [switch]
    ${Match},

    [Parameter(ParameterSetName='CaseSensitiveMatchSet', Mandatory=$true)]
    [switch]
    ${CMatch},

    [Parameter(ParameterSetName='NotMatchSet', Mandatory=$true)]
    [Alias('INotMatch')]
    [switch]
    ${NotMatch},

    [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Mandatory=$true)]
    [switch]
    ${CNotMatch},

    [Parameter(ParameterSetName='ContainsSet', Mandatory=$true)]
    [Alias('IContains')]
    [switch]
    ${Contains},

    [Parameter(ParameterSetName='CaseSensitiveContainsSet', Mandatory=$true)]
    [switch]
    ${CContains},

    [Parameter(ParameterSetName='NotContainsSet', Mandatory=$true)]
    [Alias('INotContains')]
    [switch]
    ${NotContains},

    [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Mandatory=$true)]
    [switch]
    ${CNotContains},

    [Parameter(ParameterSetName='InSet', Mandatory=$true)]
    [Alias('IIn')]
    [switch]
    ${In},

    [Parameter(ParameterSetName='CaseSensitiveInSet', Mandatory=$true)]
    [switch]
    ${CIn},

    [Parameter(ParameterSetName='NotInSet', Mandatory=$true)]
    [Alias('INotIn')]
    [switch]
    ${NotIn},

    [Parameter(ParameterSetName='CaseSensitiveNotInSet', Mandatory=$true)]
    [switch]
    ${CNotIn},

    [Parameter(ParameterSetName='IsSet', Mandatory=$true)]
    [switch]
    ${Is},

    [Parameter(ParameterSetName='IsNotSet', Mandatory=$true)]
    [switch]
    ${IsNot})

    begin
                                                        {
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Where-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
    }

    process
                        {
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
    }

    end
                        {
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
    }
<#

.ForwardHelpTargetName Where-Object
.ForwardHelpCategory Cmdlet

#>

}

function format-table
{
[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113303')]
param(
    [switch]
    ${AutoSize},

    [switch]
    ${HideTableHeaders},

    [switch]
    ${Wrap},

    [Parameter(Position=0)]
    [string[]]
    ${Property},

    [string[]]
    ${GroupBy},

    [string]
    ${View},

    [switch]
    ${ShowError},

    [switch]
    ${DisplayError},

    [switch]
    ${Force},

    [ValidateSet('CoreOnly','EnumOnly','Both')]
    [string]
    ${Expand},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Format-Table', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
<#

.ForwardHelpTargetName Format-Table
.ForwardHelpCategory Cmdlet

#>
}

function format-list
{
[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113302')]
param(
    [Parameter(Position=0)]
    [string[]]
    ${Property},

    [string[]]
    ${GroupBy},

    [string]
    ${View},

    [switch]
    ${ShowError},

    [switch]
    ${DisplayError},

    [switch]
    ${Force},

    [ValidateSet('CoreOnly','EnumOnly','Both')]
    [string]
    ${Expand},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Format-List', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
<#

.ForwardHelpTargetName Format-List
.ForwardHelpCategory Cmdlet

#>


}

function Group-Object
{
[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113338', RemotingCapability='None')]
param(
    [switch]
    ${NoElement},

    [Parameter(ParameterSetName='HashTable')]
    [Alias('AHT')]
    [switch]
    ${AsHashTable},

    [Parameter(ParameterSetName='HashTable')]
    [switch]
    ${AsString},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(Position=0)]
    [string[]]
    ${Property},

    [string]
    ${Culture},

    [switch]
    ${CaseSensitive})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Group-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
<#

.ForwardHelpTargetName Group-Object
.ForwardHelpCategory Cmdlet

#>


}

function Select-Object
{
[CmdletBinding(DefaultParameterSetName='DefaultParameter', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113387', RemotingCapability='None')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(ParameterSetName='SkipLastParameter', Position=0)]
    [Parameter(ParameterSetName='DefaultParameter', Position=0)]
    [string[]]
    ${Property},

    [Parameter(ParameterSetName='SkipLastParameter')]
    [Parameter(ParameterSetName='DefaultParameter')]
    [string[]]
    ${ExcludeProperty},

    [Parameter(ParameterSetName='DefaultParameter')]
    [Parameter(ParameterSetName='SkipLastParameter')]
    [string[]]
    ${ExpandProperty},

    [switch]
    ${Unique},

    [Parameter(ParameterSetName='DefaultParameter')]
    [ValidateRange(0, 2147483647)]
    [int]
    ${Last},

    [Parameter(ParameterSetName='DefaultParameter')]
    [ValidateRange(0, 2147483647)]
    [int]
    ${First},

    [Parameter(ParameterSetName='DefaultParameter')]
    [ValidateRange(0, 2147483647)]
    [int]
    ${Skip},

    [Parameter(ParameterSetName='SkipLastParameter')]
    [ValidateRange(0, 2147483647)]
    [int]
    ${SkipLast},

    [Parameter(ParameterSetName='IndexParameter')]
    [Parameter(ParameterSetName='DefaultParameter')]
    [switch]
    ${Wait},

    [Parameter(ParameterSetName='IndexParameter')]
    [ValidateRange(0, 2147483647)]
    [int[]]
    ${Index})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Select-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
<#

.ForwardHelpTargetName Select-Object
.ForwardHelpCategory Cmdlet

#>
}
Export-ModuleMember Where-Object,Sort-Object,format-table,format-list, group-object, Select-object



