@{
    # Node specific data
    AllNodes = @(    
        # Data  for all the nodes that will be created by the full production scenario.

            @{
            NodeName          = "localhost"           
            PSDscAllowPlainTextPassword = $true;
            PackageProductID = "{437AC169-780B-47A9-86F6-14D43C8F596B}"
                              
            };        
    );
}