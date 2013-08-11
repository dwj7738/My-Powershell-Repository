<#
Created by: Tome Tanasovski
Version: 1.0
Date: 11/2/2012

This module provides two functions:

Get-MetroApp - This cmdlet reads the registry for the keys that have the launcher id and the entry point (interesting for xaml apps, but not so much for html5 apps)

Start-MetroApp - This cmdlet uses one of the ids returned by Get-metroapp to launch an app in the win8 metro interface

Apologies for the lack of get-help documentation, but I'll be doing a blog post about this shortly:
http://powertoe.wordpress.com

Original C# code modified slightly from here - also the registry info is on this page too:
http://stackoverflow.com/questions/12925748/iapplicationactivationmanageractivateapplication-in-c
#>

$code = @"
using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
namespace Win8 {
    public enum ActivateOptions
    {
        None = 0x00000000,  // No flags set
        DesignMode = 0x00000001,  // The application is being activated for design mode, and thus will not be able to
        // to create an immersive window. Window creation must be done by design tools which
        // load the necessary components by communicating with a designer-specified service on
        // the site chain established on the activation manager.  The splash screen normally
        // shown when an application is activated will also not appear.  Most activations
        // will not use this flag.
        NoErrorUI = 0x00000002,  // Do not show an error dialog if the app fails to activate.                                
        NoSplashScreen = 0x00000004,  // Do not show the splash screen when activating the app.
    }

    [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IApplicationActivationManager
    {
        // Activates the specified immersive application for the "Launch" contract, passing the provided arguments
        // string into the application.  Callers can obtain the process Id of the application instance fulfilling this contract.
        IntPtr ActivateApplication([In] String appUserModelId, [In] String arguments, [In] ActivateOptions options, [Out] out UInt32 processId);
        IntPtr ActivateForFile([In] String appUserModelId, [In] IntPtr /*IShellItemArray* */ itemArray, [In] String verb, [Out] out UInt32 processId);
        IntPtr ActivateForProtocol([In] String appUserModelId, [In] IntPtr /* IShellItemArray* */itemArray, [Out] out UInt32 processId);
    }

    [ComImport, Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C")]//Application Activation Manager
    public class ApplicationActivationManager : IApplicationActivationManager
    {
        [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)/*, PreserveSig*/]
        public extern IntPtr ActivateApplication([In] String appUserModelId, [In] String arguments, [In] ActivateOptions options, [Out] out UInt32 processId);
        [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
        public extern IntPtr ActivateForFile([In] String appUserModelId, [In] IntPtr /*IShellItemArray* */ itemArray, [In] String verb, [Out] out UInt32 processId);
        [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
        public extern IntPtr ActivateForProtocol([In] String appUserModelId, [In] IntPtr /* IShellItemArray* */itemArray, [Out] out UInt32 processId);
    }
}
"@

add-type -TypeDefinition $code
$appman = new-object Win8.ApplicationActivationManager

function Get-MetroApp {
    $entry = 'HKCU:\Software\Classes\ActivatableClasses\Package'
    foreach ($appkey in (dir $entry |select -ExpandProperty pspath)) {        
        #$id = ((dir (join-path $appkey 'Server')) |Get-ItemProperty).appusermodelid
        $id = (dir (Join-Path $appkey server) |?{$_.pspath -notmatch 'BackgroundTransferHost.1'} |Get-ItemProperty).appusermodelid
        if ($id) {
            $possibleclassidkeys = dir (join-path $appkey 'ActivatableClassID') |select -ExpandProperty pspath             
            # we look for the app key first, then app.wwa, and then any other key if neither returns an entrypoint
            $key = $possibleclassidkeys |?{$_ -match 'app$'}
            $entrypoint=$null
            if ($key) {
                if (Test-Path (join-path $key CustomAttributes)) {
                    $entrypoint = (Get-ItemProperty (join-path $key CustomAttributes)).('appobject.entrypoint')
                }
            }
            if (!$entrypoint) {
                $key = $possibleclassidkeys |?{$_ -match 'app.wwa$'}
                if ($key) {
                    if (Test-Path (join-path $key CustomAttributes)) {
                        $entrypoint = (Get-ItemProperty (join-path $key CustomAttributes)).('appobject.entrypoint')
                    }
                }
            }
            if (!$entrypoint) {
                foreach ($key in $possibleclassidkeys) {
                    if (Test-Path (join-path $key CustomAttributes)) {
                        $entrypoint = (Get-ItemProperty (join-path $key CustomAttributes)).('appobject.entrypoint')
                        break
                    }
                }
            }
            new-object psobject -Property ([ordered] @{
                EntryPoint = $entrypoint                
                ID = $id
            })
         }
    }
}

function Start-MetroApp {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string] $ID
    )
    $appman.ActivateApplication($ID,$null,[Win8.ActivateOptions]::None,[ref]0)
}