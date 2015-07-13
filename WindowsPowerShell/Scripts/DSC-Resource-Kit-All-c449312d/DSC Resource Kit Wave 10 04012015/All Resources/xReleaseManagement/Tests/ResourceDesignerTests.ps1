# Hi Donovan – I just spoke with the lead Dev, and what’s broken is 
# Test-xDscResource.
# Apparently, Hashtable is supported as an embedded instance.  
#
# A bug has been filed on this, please continue to use it and we’ll ignore 
# that specific error in the test tool.
"Testing DSC Resource"
"Test-xDscResource has a bug. Hashtable is supported as an embedded instance."
Test-xDscResource ..\DSCResources\MSFT_xTokenize

"Testing DSC Schema"
Test-xDscSchema ..\DSCResources\MSFT_xTokenize\MSFT_xTokenize.schema.mof