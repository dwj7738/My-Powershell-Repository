############################################################
# DSC Tokenization Example - With Token File
#
# This script supports using the technique where you simply
# create a copy of your web.config and add .token to the file
# extension.  This will result in two files in your target 
# folder (web.config and web.config.token)
#
# Using this technique the resource is able to determine
# if the target file matches the currently used tokens.
# For example if I used this resource and the database
# token was replaced with db01 and needed to update it to
# db02 the resource could figure out it needs to be reapplied
# Whereas if you don't use a token file the resource can't 
# determine that. All the resource can do if a token file is
# not used is simply see if the token still exist in the target
# file.  If not it must assume it has been run even if the value
# of the token has been changed sense the last time it was run.
#
# Running this example will create a new subfolder in the
# examples folder where the transformation of the files will
# take place.

# Define configuration data to be used in the configuration.
# This is normally done in a separate file but included here
# for this example.
$ConfigData = @{
   AllNodes = @(
      @{
         NodeName = "localhost";
         SourcePath = "$($PSScriptRoot)\tokenfile_drop\";
         DestinationPath = "$($PSScriptRoot)\tokenfile_target\";
         Tokens = @{Database="db01"};
         SearchPattern = "*.config"
      }
   )
}

Configuration TokenizeFiles
{
   # You have to import the xReleaseManagement resource before
   # you can use it in your configuration
   Import-DscResource -ModuleName xReleaseManagement
    
   # Node is read from ConfigData defined above
   Node $AllNodes.NodeName
   {
      # Use the built in File resource to copy files
      File CopyBits
      {
         Ensure = "Present"
         Force = $true
         Recurse = $true
         Type = "Directory"
         SourcePath = $Node.SourcePath
         DestinationPath = $Node.DestinationPath
      }

      # Use the xTokenize resource to transform your web.config files
      xTokenize WebConfigs
      {
         dependsOn = "[File]CopyBits"
         recurse = $true
         useTokenFiles = $true
         tokens = $Node.Tokens           
         path = $Node.DestinationPath
         searchPattern = $Node.SearchPattern
      }
   }
}

TokenizeFiles -ConfigurationData $ConfigData

Start-DscConfiguration -Wait -Verbose -Path .\TokenizeFiles -Force