############################################################
# DSC Tokenization Example - No Token File
#
# This script supports using the technique described in this
# blog post http://tinyurl.com/tokenization which uses the 
# XML transform functionality of Web Deploy to create a 
# tokenized version of the web.config.  This technique does
# not require a .token file to be in the target folder.
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
         SourcePath = "$($PSScriptRoot)\noTokenfile_drop\";
         DestinationPath = "$($PSScriptRoot)\noTokenfile_target\";
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
         tokens = $Node.Tokens         
         useTokenFiles = $false
         path = $Node.DestinationPath
         searchPattern = $Node.SearchPattern
      }
   }
}

TokenizeFiles -ConfigurationData $ConfigData

Start-DscConfiguration -Wait -Verbose -Path .\TokenizeFiles -Force