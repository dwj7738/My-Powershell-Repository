##############################################################################
##
## New-GenericObject
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Creates an object of a generic type:

.EXAMPLE

PS >New-GenericObject System.Collections.ObjectModel.Collection System.Int32
Creates a simple generic collection

.EXAMPLE

PS >New-GenericObject System.Collections.Generic.Dictionary `
      System.String,System.Int32
Creates a generic dictionary with two types

.EXAMPLE

PS >$secondType = New-GenericObject System.Collections.Generic.List Int32
PS >New-GenericObject System.Collections.Generic.Dictionary `
      System.String,$secondType.GetType()
Creates a generic list as the second type to a generic dictionary

.EXAMPLE

PS >New-GenericObject System.Collections.Generic.LinkedListNode `
      System.String "Hi"
Creates a generic type with a non-default constructor

#>

param(
    ## The generic type to create
    [Parameter(Mandatory = $true)]
    [string] $TypeName,

    ## The types that should be applied to the generic object
    [Parameter(Mandatory = $true)]
    [string[]] $TypeParameters,

    ## Arguments to be passed to the constructor
    [object[]] $ConstructorParameters
)

Set-StrictMode -Version Latest

## Create the generic type name
$genericTypeName = $typeName + '`' + $typeParameters.Count
$genericType = [Type] $genericTypeName

if(-not $genericType)
{
    throw "Could not find generic type $genericTypeName"
}

## Bind the type arguments to it
[type[]] $typedParameters = $typeParameters
$closedType = $genericType.MakeGenericType($typedParameters)
if(-not $closedType)
{
    throw "Could not make closed type $genericType"
}

## Create the closed version of the generic type
,[Activator]::CreateInstance($closedType, $constructorParameters)
