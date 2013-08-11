
  Add-Type –Path .\Interop.NETWORKLIST.dll
  $nlm = new-object NETWORKLIST.NetworkListManagerClass
  $nlm.GetNetworks("NLM_ENUM_NETWORK_ALL") | select @{n="Name";e={$_.GetName()}},@{n="Category";e={$_.GetCategory()}},IsConnected,IsConnectedToInternet
