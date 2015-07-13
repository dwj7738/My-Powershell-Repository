#============================================================================================================================#
#                                                                                                                            #
# MS-UPD-LOAD.psm1                                                                                                           #
# Microsoft Updates Downloader PowerShell Module                                                                             #
# Author: Alexander Krause                                                                                                   #
# Creation Date: 27.03.2013                                                                                                  #
# Modified Date: 07.01.2014                                                                                                  #
# Version: 0.7.14                                                                                                            #
#                                                                                                                            #
#============================================================================================================================#

function Invoke-UpdXML
{
param()
Start-BitsTransfer http://go.microsoft.com/fwlink/?LinkId=76054 .\wsusscn2.cab
expand wsusscn2.cab -F:package.cab .\ | Out-Null
del wsusscn2.cab
expand package.cab .\package.xml | Out-Null
del package.cab
[xml]$script:xml = gc .\package.xml -Encoding UTF8
del package.xml
}

function Get-UpdXML
{
param($Year = "*",$Month = "*",$Day = "*",$Product = "*",$ProductFamily = "*")
if($script:xml -eq $NULL){Invoke-UpdXML}
$mo = if($Month -ne "*"){"{0:D2}" -f $Month}else{$Month}
$da = if($Day -ne "*"){"{0:D2}" -f $Day}else{$Day}
$script:xml.SelectNodes("/*/*/*") | ?{$_.CreationDate -like "$Year-$mo-$da*" -and $_.DeploymentAction -ne "Bundle" -and $_.DeploymentAction -ne "Evaluate"} | %{
$cat = %{$_.Categories.Category}
New-Object PSObject -Property @{
   CreationDate          = $_.CreationDate.split("T")[0]
   CreationTime          = $_.CreationDate.split("T,Z")[1]
   #DefaultLanguage      = $_.DefaultLanguage
   UpdateId              = $_.UpdateId
   #DeploymentAction     = $_.DeploymentAction
   #IsLeaf               = $_.IsLeaf
   Company               = Set-ID ($cat | ?{$_.Type -eq "Company"}).id
   Product               = Set-ID ($cat | ?{$_.Type -eq "Product"}).id
   ProductFamily         = Set-ID ($cat | ?{$_.Type -eq "ProductFamily"}).id
   UpdateClassification  = Set-ID ($cat | ?{$_.Type -eq "UpdateClassification"}).id
}} | ?{$_.Product -like $Product -and $_.ProductFamily -like $ProductFamily}
}

function Set-ID
{
param($id)
if($id -eq "5c9376ab-8ce6-464a-b136-22113dd69801"){echo "Applications"}
elseif($id -eq "e6cf1350-c01b-414d-a61f-263d14d133b4"){echo "Critical Updates"}
elseif($id -eq "e0789628-ce08-4437-be74-2495b842f43b"){echo "Definition Updates"}
elseif($id -eq "ebfc1fc5-71a4-4f7b-9aca-3b9a503104a0"){echo "Drivers"}
elseif($id -eq "b54e7d24-7add-428f-8b75-90a396fa584f"){echo "Feature Packs"}
elseif($id -eq "0fa1201d-4330-4fa8-8ae9-b877473b6441"){echo "Security Updates"}
elseif($id -eq "68c5b0a3-d1a6-4553-ae49-01d3a7827828"){echo "Service Packs"}
elseif($id -eq "b4832bd8-e735-4761-8daf-37f882276dab"){echo "Tools"}
elseif($id -eq "28bc880e-0592-4cbf-8f95-c79b17911d5f"){echo "Update Rollups"}
elseif($id -eq "cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83"){echo "Updates"}
elseif($id -eq "fdcfda10-5b1f-4e57-8298-c744257e30db"){echo "Active Directory Rights Management Services Client 2.0"}
elseif($id -eq "57742761-615a-4e06-90bb-008394eaea47"){echo "Active Directory"}
elseif($id -eq "5d6a452a-55ba-4e11-adac-85e180bda3d6"){echo "Antigen for Exchange/SMTP"}
elseif($id -eq "116a3557-3847-4858-9f03-38e94b977456"){echo "Antigen"}
elseif($id -eq "b86cf33d-92ac-43d2-886b-be8a12f81ee1"){echo "Bing Bar"}
elseif($id -eq "2b496c37-f722-4e7b-8467-a7ad1e29e7c1"){echo "Bing"}
elseif($id -eq "34aae785-2ae3-446d-b305-aec3770edcef"){echo "BizTalk Server 2002"}
elseif($id -eq "86b9f801-b8ec-4d16-b334-08fba8567c17"){echo "BizTalk Server 2006R2"}
elseif($id -eq "b61793e6-3539-4dc8-8160-df71054ea826"){echo "BizTalk Server 2009"}
elseif($id -eq "61487ade-9a4e-47c9-baa5-f1595bcdc5c5"){echo "BizTalk Server 2013"}
elseif($id -eq "ed036c16-1bd6-43ab-b546-87c080dfd819"){echo "BizTalk Server"}
elseif($id -eq "83aed513-c42d-4f94-b4dc-f2670973902d"){echo "CAPICOM"}
elseif($id -eq "236c566b-aaa6-482c-89a6-1e6c5cac6ed8"){echo "Category for System Center Online Client"}
elseif($id -eq "ac615cb5-1c12-44be-a262-fab9cd8bf523"){echo "Compute Cluster Pack"}
elseif($id -eq "eb658c03-7d9f-4bfa-8ef3-c113b7466e73"){echo "Data Protection Manager 2006"}
elseif($id -eq "48ce8c86-6850-4f68-8e9d-7dc8535ced60"){echo "Developer Tools, Runtimes, and Redistributables"}
elseif($id -eq "f76b7f51-b762-4fd0-a35c-e04f582acf42"){echo "Dictionary Updates for Microsoft IMEs"}
elseif($id -eq "cb263e3f-6c5a-4b71-88fa-1706f9549f51"){echo "Dynamisches Installationsprogramm für Windows Internet Explorer 7"}
elseif($id -eq "5312e4f1-6372-442d-aeb2-15f2132c9bd7"){echo "Dynamisches Installationsprogramm für Windows Internet Explorer 8"}
elseif($id -eq "83a83e29-7d55-44a0-afed-aea164bc35e6"){echo "Exchange 2000 Server"}
elseif($id -eq "3cf32f7c-d8ee-43f8-a0da-8b88a6f8af1a"){echo "Exchange Server 2003"}
elseif($id -eq "ab62c5bd-5539-49f6-8aea-5a114dd42314"){echo "Exchange Server 2007 and Above Anti-spam"}
elseif($id -eq "26bb6be1-37d1-4ca6-baee-ec00b2f7d0f1"){echo "Exchange Server 2007"}
elseif($id -eq "9b135dd5-fc75-4609-a6ae-fb5d22333ef0"){echo "Exchange Server 2010"}
elseif($id -eq "d3d7c7a6-3e2f-4029-85bf-b59796b82ce7"){echo "Exchange Server 2013"}
elseif($id -eq "352f9494-d516-4b40-a21a-cd2416098982"){echo "Exchange"}
elseif($id -eq "fa9ff215-cfe0-4d57-8640-c65f24e6d8e0"){echo "Expression Design 1"}
elseif($id -eq "f3b1d39b-6871-4b51-8b8c-6eb556c8eee1"){echo "Expression Design 2"}
elseif($id -eq "18a2cff8-9fd2-487e-ac3b-f490e6a01b2d"){echo "Expression Design 3"}
elseif($id -eq "9119fae9-3fdd-4c06-bde7-2cbbe2cf3964"){echo "Expression Design 4"}
elseif($id -eq "5108d510-e169-420c-9a4d-618bdb33c480"){echo "Expression Media 2"}
elseif($id -eq "d8584b2b-3ac5-4201-91cb-caf6d240dc0b"){echo "Expression Media V1"}
elseif($id -eq "a33f42ac-b33f-4fd2-80a8-78b3bfa6a142"){echo "Expression Web 3"}
elseif($id -eq "3b1e1746-d99b-42d4-91fd-71d794f97a4d"){echo "Expression Web 4"}
elseif($id -eq "ca9e8c72-81c4-11dc-8284-f47156d89593"){echo "Expression"}
elseif($id -eq "d72155f3-8aa8-4bf7-9972-0a696875b74e"){echo "Firewall Client for ISA Server"}
elseif($id -eq "0a487050-8b0f-4f81-b401-be4ceacd61cd"){echo "Forefront Client Security"}
elseif($id -eq "a38c835c-2950-4e87-86cc-6911a52c34a3"){echo "Forefront Endpoint Protection 2010"}
elseif($id -eq "86134b1c-cf56-4884-87bf-5c9fe9eb526f"){echo "Forefront Identity Manager 2010 R2"}
elseif($id -eq "d7d32245-1064-4edf-bd09-0218cfb6a2da"){echo "Forefront Identity Manager 2010"}
elseif($id -eq "a6432e15-a446-44af-8f96-0475c472aef6"){echo "Forefront Protection Category"}
elseif($id -eq "f54d8a80-c7e1-476c-9995-3d6aee4bfb58"){echo "Forefront Server Security Category"}
elseif($id -eq "84a54ea9-e574-457a-a750-17164c1d1679"){echo "Forefront Threat Management Gateway, Definition Updates for HTTP Malware Inspection"}
elseif($id -eq "06bdf56c-1360-4bb9-8997-6d67b318467c"){echo "Forefront TMG MBE"}
elseif($id -eq "59f07fb7-a6a1-4444-a9a9-fb4b80138c6d"){echo "Forefront TMG"}
elseif($id -eq "f8c3c9a9-10de-4f09-bc16-5eb1b861fb4c"){echo "Forefront"}
elseif($id -eq "f0474daf-de38-4b6e-9ad6-74922f6f539d"){echo "Fotogalerie-Installation und -Upgrades"}
elseif($id -eq "d84d138e-8423-4102-b317-91b1339aa9c9"){echo "HealthVault Connection Center Upgrades"}
elseif($id -eq "2e068336-2ead-427a-b80d-5b0fffded7e7"){echo "HealthVault Connection Center"}
elseif($id -eq "0c6af366-17fb-4125-a441-be87992b953a"){echo "Host Integration Server 2000"}
elseif($id -eq "784c9f6d-959a-433f-b7a3-b2ace1489a18"){echo "Host Integration Server 2004"}
elseif($id -eq "eac7e88b-d8d4-4158-a828-c8fc1325a816"){echo "Host Integration Server 2006"}
elseif($id -eq "42b678ae-2b57-4251-ae57-efbd35e7ae96"){echo "Host Integration Server 2009"}
elseif($id -eq "3f3b071e-c4a6-4bcc-b6c1-27122b235949"){echo "Host Integration Server 2010"}
elseif($id -eq "5964c9f1-8e72-4891-a03a-2aed1c4115d2"){echo "HPC Pack 2008"}
elseif($id -eq "4f93eb69-8b97-4677-8de4-d3fca7ed10e6"){echo "HPC Pack"}
elseif($id -eq "d123907b-ba63-40cb-a954-9b8a4481dded"){echo "Installation von OneCare Family Safety"}
elseif($id -eq "b627a8ff-19cd-45f5-a938-32879dd90123"){echo "Internet Security and Acceleration Server 2004"}
elseif($id -eq "2cdbfa44-e2cb-4455-b334-fce74ded8eda"){echo "Internet Security and Acceleration Server 2006"}
elseif($id -eq "0580151d-fd22-4401-aa2b-ce1e3ae62bc9"){echo "Internet Security and Acceleration Server"}
elseif($id -eq "5cc25303-143f-40f3-a2ff-803a1db69955"){echo "Lokal veröffentlichte Pakete"}
elseif($id -eq "7c40e8c2-01ae-47f5-9af2-6e75a0582518"){echo "Lokaler Herausgeber"}
elseif($id -eq "00b2d754-4512-4278-b50b-d073efb27f37"){echo "Microsoft Application Virtualization 4.5"}
elseif($id -eq "c755e211-dc2b-45a7-be72-0bdc9015a63b"){echo "Microsoft Application Virtualization 4.6"}
elseif($id -eq "1406b1b4-5441-408f-babc-9dcb5501f46f"){echo "Microsoft Application Virtualization 5.0"}
elseif($id -eq "523a2448-8b6c-458b-9336-307e1df6d6a6"){echo "Microsoft Application Virtualization"}
elseif($id -eq "7e903438-3690-4cf0-bc89-2fc34c26422b"){echo "Microsoft BitLocker Administration and Monitoring v1"}
elseif($id -eq "c8c19432-f207-4d9d-ab10-764f3d29744d"){echo "Microsoft BitLocker Administration and Monitoring"}
elseif($id -eq "587f7961-187a-4419-8972-318be1c318af"){echo "Microsoft Dynamics CRM 2011 SHS"}
elseif($id -eq "2f3d1aba-2192-47b4-9c8d-87b41f693af4"){echo "Microsoft Dynamics CRM 2011"}
elseif($id -eq "0dbc842c-730f-4361-8811-1b048f11c09b"){echo "Microsoft Dynamics CRM"}
elseif($id -eq "e7ba9d21-4c88-4f88-94cb-a23488e59ebd"){echo "Microsoft HealthVault"}
elseif($id -eq "5e870422-bd8f-4fd2-96d3-9c5d9aafda22"){echo "Microsoft Lync 2010"}
elseif($id -eq "04d85ac2-c29f-4414-9cb6-5bcd6c059070"){echo "Microsoft Lync Server 2010"}
elseif($id -eq "01ce995b-6e10-404b-8511-08142e6b814e"){echo "Microsoft Lync Server 2013"}
elseif($id -eq "2af51aa0-509a-4b1d-9218-7e7508f05ec3"){echo "Microsoft Lync Server and Microsoft Lync"}
elseif($id -eq "935c5617-d17a-37cc-dbcf-423e5beab8ea"){echo "Microsoft Online Services"}
elseif($id -eq "b0247430-6f8d-4409-b39b-30de02286c71"){echo "Microsoft Online Services-Anmelde-Assistent"}
elseif($id -eq "a8f50393-2e42-43d1-aaf0-92bec8b60775"){echo "Microsoft Research AutoCollage 2008"}
elseif($id -eq "0f3412f2-3405-4d86-a0ff-0ede802227a8"){echo "Microsoft Research AutoCollage"}
elseif($id -eq "b567e54e-648b-4ac6-9171-149a19a73da8"){echo "Microsoft Security Essentials"}
elseif($id -eq "e9ece729-676d-4b57-b4d1-7e0ab0589707"){echo "Microsoft SQL Server 2008 R2 - PowerPivot for Microsoft Excel 2010"}
elseif($id -eq "56750722-19b4-4449-a547-5b68f19eee38"){echo "Microsoft SQL Server 2012"}
elseif($id -eq "fe324c6a-dac1-aca8-9916-db718e48fa3a"){echo "Microsoft SQL Server PowerPivot for Excel"}
elseif($id -eq "a73eeffa-5729-48d4-8bf4-275132338629"){echo "Microsoft StreamInsight V1.0"}
elseif($id -eq "4c1a298e-8dbd-5d8b-a52f-6c176fdd5904"){echo "Microsoft StreamInsight"}
elseif($id -eq "5ef2c723-3e0b-4f87-b719-78b027e38087"){echo "Microsoft System Center Data Protection Manager"}
elseif($id -eq "bf6a6018-83f0-45a6-b9bf-074a78ec9c82"){echo "Microsoft System Center DPM 2010"}
elseif($id -eq "29fd8922-db9e-4a97-aa00-ca980376b738"){echo "Microsoft System Center Virtual Machine Manager 2007"}
elseif($id -eq "7e5d0309-78dd-4f52-a756-0259f88b634b"){echo "Microsoft System Center Virtual Machine Manager 2008"}
elseif($id -eq "b790e43b-f4e4-48b4-9f0c-499194f00841"){echo "Microsoft Works 8"}
elseif($id -eq "e9c87080-a759-475a-a8fa-55552c8cd3dc"){echo "Microsoft Works 9"}
elseif($id -eq "56309036-4c77-4dd9-951a-99ee9c246a94"){echo "Microsoft"}
elseif($id -eq "6b9e8b26-8f50-44b9-94c6-7846084383ec"){echo "MS Security Essentials"}
elseif($id -eq "4217668b-66f0-42a0-911e-a334a5e4dbad"){echo "Network Monitor 3"}
elseif($id -eq "35c4463b-35dc-42ac-b0ba-1d9b5c505de2"){echo "Network Monitor"}
elseif($id -eq "8508af86-b85e-450f-a518-3b6f8f204eea"){echo "New Dictionaries for Microsoft IMEs"}
elseif($id -eq "6248b8b1-ffeb-dbd9-887a-2acf53b09dfe"){echo "Office 2002/XP"}
elseif($id -eq "1403f223-a63f-f572-82ba-c92391218055"){echo "Office 2003"}
elseif($id -eq "041e4f9f-3a3d-4f58-8b2f-5e6fe95c4591"){echo "Office 2007"}
elseif($id -eq "84f5f325-30d7-41c4-81d1-87a0e6535b66"){echo "Office 2010"}
elseif($id -eq "704a0a4a-518f-4d69-9e03-10ba44198bd5"){echo "Office 2013"}
elseif($id -eq "22bf57a8-4fe1-425f-bdaa-32b4f655284b"){echo "Office Communications Server 2007 R2"}
elseif($id -eq "e164fc3d-96be-4811-8ad5-ebe692be33dd"){echo "Office Communications Server 2007"}
elseif($id -eq "504ae250-57c5-484a-8a10-a2c35ea0689b"){echo "Office Communications Server And Office Communicator"}
elseif($id -eq "8bc19572-a4b6-4910-b70d-716fecffc1eb"){echo "Office Communicator 2007 R2"}
elseif($id -eq "03c7c488-f8ed-496c-b6e0-be608abb8a79"){echo "Office Live"}
elseif($id -eq "ec231084-85c2-4daf-bfc4-50bbe4022257"){echo "Office Live-Add-In"}
elseif($id -eq "477b856e-65c4-4473-b621-a8b230bb70d9"){echo "Office"}
elseif($id -eq "dd78b8a1-0b20-45c1-add6-4da72e9364cf"){echo "OOBE ZDP"}
elseif($id -eq "7cf56bdd-5b4e-4c04-a6a6-706a2199eff7"){echo "Report Viewer 2005"}
elseif($id -eq "79adaa30-d83b-4d9c-8afd-e099cf34855f"){echo "Report Viewer 2008"}
elseif($id -eq "f7f096c9-9293-422d-9be8-9f6e90c2e096"){echo "Report Viewer 2010"}
elseif($id -eq "9f9b1ace-a810-11db-bad5-f7f555d89593"){echo "SDK Components"}
elseif($id -eq "ce62f77a-28f3-4d4b-824f-0f9b53461d67"){echo "Search Enhancement Pack"}
elseif($id -eq "6cf036b9-b546-4694-885a-938b93216b66"){echo "Security Essentials"}
elseif($id -eq "9f3dd20a-1004-470e-ba65-3dc62d982958"){echo "Silverlight"}
elseif($id -eq "fe729f7e-3945-11dc-8e0c-cd1356d89593"){echo "Silverlight"}
elseif($id -eq "6750007f-c908-4f2c-8aff-48ca6d36add6"){echo "Skype for Windows"}
elseif($id -eq "1e602215-b397-46ca-b1a8-7ea0059517bc"){echo "Skype"}
elseif($id -eq "7145181b-9556-4b11-b659-0162fa9df11f"){echo "SQL Server 2000"}
elseif($id -eq "60916385-7546-4e9b-836e-79d65e517bab"){echo "SQL Server 2005"}
elseif($id -eq "bb7bc3a7-857b-49d4-8879-b639cf5e8c3c"){echo "SQL Server 2008 R2"}
elseif($id -eq "c5f0b23c-e990-4b71-9808-718d353f533a"){echo "SQL Server 2008"}
elseif($id -eq "7fe4630a-0330-4b01-a5e6-a77c7ad34eb0"){echo "SQL Server 2012 Product Updates for Setup"}
elseif($id -eq "c96c35fc-a21f-481b-917c-10c4f64792cb"){echo "SQL Server Feature Pack"}
elseif($id -eq "0a4c6c73-8887-4d7f-9cbe-d08fa8fa9d1e"){echo "SQL Server"}
elseif($id -eq "daa70353-99b4-4e04-b776-03973d54d20f"){echo "System Center 2012 - App Controller"}
elseif($id -eq "b0c3b58d-1997-4b68-8d73-ab77f721d099"){echo "System Center 2012 - Data Protection Manager"}
elseif($id -eq "bf05abfb-6388-4908-824e-01565b05e43a"){echo "System Center 2012 - Operations Manager"}
elseif($id -eq "ab8df9b9-8bff-4999-aee5-6e4054ead976"){echo "System Center 2012 - Orchestrator"}
elseif($id -eq "6ed4a93e-e443-4965-b666-5bc7149f793c"){echo "System Center 2012 - Virtual Machine Manager"}
elseif($id -eq "50d71efd-1e60-4898-9ef5-f31a77bde4b0"){echo "System Center 2012 SP1 - App Controller"}
elseif($id -eq "dd6318d7-1cff-44ed-a0b1-9d410c196792"){echo "System Center 2012 SP1 - Data Protection Manager"}
elseif($id -eq "80d30b43-f814-41fd-b7c5-85c91ea66c45"){echo "System Center 2012 SP1 - Operation Manager"}
elseif($id -eq "ba649061-a2bd-42a9-b7c3-825ce12c3cd6"){echo "System Center 2012 SP1 - Virtual Machine Manager"}
elseif($id -eq "ae4500e9-17b0-4a78-b088-5b056dbf452b"){echo "System Center Advisor"}
elseif($id -eq "d22b3d16-bc75-418f-b648-e5f3d32490ee"){echo "System Center Configuration Manager 2007"}
elseif($id -eq "23f5eb29-ddc6-4263-9958-cf032644deea"){echo "System Center Online"}
elseif($id -eq "9476d3f6-a119-4d6e-9952-8ad28a55bba6"){echo "System Center Virtual Machine Manager"}
elseif($id -eq "26a5d0a5-b108-46f1-93fa-f2a9cf10d029"){echo "System Center"}
elseif($id -eq "5a456666-3ac5-4162-9f52-260885d6533a"){echo "Systems Management Server 2003"}
elseif($id -eq "78f4e068-1609-4e7a-ac8e-174288fa70a1"){echo "Systems Management Server"}
elseif($id -eq "ae4483f4-f3ce-4956-ae80-93c18d8886a6"){echo "Threat Management Gateway Definition Updates for Network Inspection System"}
elseif($id -eq "cd8d80fe-5b55-48f1-b37a-96535dca6ae7"){echo "TMG Firewall Client"}
elseif($id -eq "4ea8aeaf-1d28-463e-8179-af9829f81212"){echo "Update zur Browserauswahl in Europa (nur Europa)"}
elseif($id -eq "c8a4436c-1043-4288-a065-0f37e9640d60"){echo "Virtual PC"}
elseif($id -eq "6d992428-3b47-4957-bb1a-157bd8c73d38"){echo "Virtual Server"}
elseif($id -eq "f61ce0bd-ba78-4399-bb1c-098da328f2cc"){echo "Virtual Server"}
elseif($id -eq "a0dd7e72-90ec-41e3-b370-c86a245cd44f"){echo "Visual Studio 2005"}
elseif($id -eq "e3fde9f8-14d6-4b5c-911c-fba9e0fc9887"){echo "Visual Studio 2008"}
elseif($id -eq "cbfd1e71-9d9e-457e-a8c5-500c47cfe9f3"){echo "Visual Studio 2010 Tools for Office Runtime"}
elseif($id -eq "c9834186-a976-472b-8384-6bb8f2aa43d9"){echo "Visual Studio 2010"}
elseif($id -eq "abddd523-04f4-4f8e-b76f-a6c84286cc67"){echo "Visual Studio 2012"}
elseif($id -eq "cf4aa0fc-119d-4408-bcba-181abb69ed33"){echo "Visual Studio 2013"}
elseif($id -eq "3b4b8621-726e-43a6-b43b-37d07ec7019f"){echo "Windows 2000"}
elseif($id -eq "bfe5b177-a086-47a0-b102-097e4fa1f807"){echo "Windows 7"}
elseif($id -eq "3e5cc385-f312-4fff-bd5e-b88dcf29b476"){echo "Windows 8 Language Interface Packs"}
elseif($id -eq "97c4cee8-b2ae-4c43-a5ee-08367dab8796"){echo "Windows 8 Language Packs"}
elseif($id -eq "405706ed-f1d7-47ea-91e1-eb8860039715"){echo "Windows 8.1 Drivers"}
elseif($id -eq "18e5ea77-e3d1-43b6-a0a8-fa3dbcd42e93"){echo "Windows 8.1 Dynamic Update"}
elseif($id -eq "14a011c7-d17b-4b71-a2a4-051807f4f4c6"){echo "Windows 8.1 Language Interface Packs"}
elseif($id -eq "01030579-66d2-446e-8c65-538df07e0e44"){echo "Windows 8.1 Language Packs"}
elseif($id -eq "6407468e-edc7-4ecd-8c32-521f64cee65e"){echo "Windows 8.1"}
elseif($id -eq "2ee2ad83-828c-4405-9479-544d767993fc"){echo "Windows 8"}
elseif($id -eq "393789f5-61c1-4881-b5e7-c47bcca90f94"){echo "Windows Consumer Preview Dynamic Update"}
elseif($id -eq "8c3fcc84-7410-4a95-8b89-a166a0190486"){echo "Windows Defender"}
elseif($id -eq "50c04525-9b15-4f7c-bed4-87455bcd7ded"){echo "Windows Dictionary Updates"}
elseif($id -eq "f14be400-6024-429b-9459-c438db2978d4"){echo "Windows Embedded Developer Update"}
elseif($id -eq "f4b9c883-f4db-4fb5-b204-3343c11fa021"){echo "Windows Embedded Standard 7"}
elseif($id -eq "a36724a5-da1a-47b2-b8be-95e7cd9bc909"){echo "Windows Embedded"}
elseif($id -eq "6966a762-0c7c-4261-bd07-fb12b4673347"){echo "Windows Essential Business Server 2008 Setup Updates"}
elseif($id -eq "e9b56b9a-0ca9-4b3e-91d4-bdcf1ac7d94d"){echo "Windows Essential Business Server 2008"}
elseif($id -eq "649f3e94-ed2f-42e8-a4cd-e81489af357c"){echo "Windows Essential Business Server Preinstallation Tools"}
elseif($id -eq "41dce4a6-71dd-4a02-bb36-76984107376d"){echo "Windows Essential Business Server"}
elseif($id -eq "470bd53a-c36a-448f-b620-91feede01946"){echo "Windows GDR-Dynamic Update"}
elseif($id -eq "5ea45628-0257-499b-9c23-a6988fc5ea85"){echo "Windows Live Toolbar"}
elseif($id -eq "0ea196ba-7a32-4e76-afd8-46bd54ecd3c6"){echo "Windows Live"}
elseif($id -eq "afd77d9e-f05a-431c-889a-34c23c9f9af5"){echo "Windows Live"}
elseif($id -eq "b3d0af68-8a86-4bfc-b458-af702f35930e"){echo "Windows Live"}
elseif($id -eq "e88a19fb-a847-4e3d-9ae2-13c2b84f58a6"){echo "Windows Media Dynamic Installer"}
elseif($id -eq "8c27cdba-6a1c-455e-af20-46b7771bbb96"){echo "Windows Next Graphics Driver Dynamic update"}
elseif($id -eq "2c62603e-7a60-4832-9a14-cfdfd2d71b9a"){echo "Windows RT 8.1"}
elseif($id -eq "0a07aea1-9d09-4c1e-8dc7-7469228d8195"){echo "Windows RT"}
elseif($id -eq "7f44c2a7-bc36-470b-be3b-c01b6dc5dd4e"){echo "Windows Server 2003, Datacenter Edition"}
elseif($id -eq "dbf57a08-0d5a-46ff-b30c-7715eb9498e9"){echo "Windows Server 2003"}
elseif($id -eq "fdfe8200-9d98-44ba-a12a-772282bf60ef"){echo "Windows Server 2008 R2"}
elseif($id -eq "ec9aaca2-f868-4f06-b201-fb8eefd84cef"){echo "Windows Server 2008 Server-Manager - Dynamic Installer"}
elseif($id -eq "ba0ae9cc-5f01-40b4-ac3f-50192b5d6aaf"){echo "Windows Server 2008"}
elseif($id -eq "26cbba0f-45de-40d5-b94a-3cbe5b761c9d"){echo "Windows Server 2012 Language Packs"}
elseif($id -eq "8b4e84f6-595f-41ed-854f-4ca886e317a5"){echo "Windows Server 2012 R2 Language Packs"}
elseif($id -eq "d31bd4c3-d872-41c9-a2e7-231f372588cb"){echo "Windows Server 2012 R2"}
elseif($id -eq "a105a108-7c9b-4518-bbbe-73f0fe30012b"){echo "Windows Server 2012"}
elseif($id -eq "eef074e9-61d6-4dac-b102-3dbe15fff3ea"){echo "Windows Server Solutions Best Practices Analyzer 1.0"}
elseif($id -eq "4e487029-f550-4c22-8b31-9173f3f95786"){echo "Windows Server-Manager - Windows Server Updates Services (WSUS) Dynamic Installer"}
elseif($id -eq "032e3af5-1ac5-4205-9ae5-461b4e8cd26d"){echo "Windows Small Business Server 2003"}
elseif($id -eq "7fff3336-2479-4623-a697-bcefcf1b9f92"){echo "Windows Small Business Server 2008 Migration Preparation Tool"}
elseif($id -eq "575d68e2-7c94-48f9-a04f-4b68555d972d"){echo "Windows Small Business Server 2008"}
elseif($id -eq "1556fc1d-f20e-4790-848e-90b7cdbedfda"){echo "Windows Small Business Server 2011 Standard"}
elseif($id -eq "68623613-134c-4b18-bcec-7497ac1bfcb0"){echo "Windows Small Business Server"}
elseif($id -eq "e7441a84-4561-465f-9e0e-7fc16fa25ea7"){echo "Windows Ultimate Extras"}
elseif($id -eq "90e135fb-ef48-4ad0-afb5-10c4ceb4ed16"){echo "Windows Vista Dynamic Installer"}
elseif($id -eq "a901c1bd-989c-45c6-8da0-8dde8dbb69e0"){echo "Windows Vista Ultimate Language Packs"}
elseif($id -eq "26997d30-08ce-4f25-b2de-699c36a8033a"){echo "Windows Vista"}
elseif($id -eq "a4bedb1d-a809-4f63-9b49-3fe31967b6d0"){echo "Windows XP 64-Bit Edition Version 2003"}
elseif($id -eq "4cb6ebd5-e38a-4826-9f76-1416a6f563b0"){echo "Windows XP x64 Edition"}
elseif($id -eq "558f4bc3-4827-49e1-accf-ea79fd72d4c9"){echo "Windows XP"}
elseif($id -eq "6964aab4-c5b5-43bd-a17d-ffb4346a8e1d"){echo "Windows"}
elseif($id -eq "81b8c03b-9743-44b1-8c78-25e750921e36"){echo "Works 6-9 Converter"}
elseif($id -eq "2425de84-f071-4358-aac9-6bbd6e0bfaa7"){echo "Works"}
elseif($id -eq "a13d331b-ce8f-40e4-8a18-227bf18f22f3"){echo "Writer-Installation und -Upgrades"}
else{echo $id}
}

function Get-Update
{
param($Year = "*",$Month = "*",$Day = "*",$Product = "*",$ProductFamily = "*",$KB = "*",$Architecture="*")
Get-UpdXML $Year $Month $Day $Product $ProductFamily | %{
$link = $_.UpdateId
$id = ($web = iwr "http://catalog.update.microsoft.com/v7/site/ScopedViewInline.aspx?updateid=$link") | %{$_.ParsedHtml}
if($web.BaseResponse.ResponseUri.AbsoluteUri -notlike "*Error*"){
New-Object PSObject -Property @{
   CreationDate           = $_.CreationDate
   CreationTime           = $_.CreationTime
   Company                = $_.Company
   Product                = $_.Product
   ProductFamily          = $_.ProductFamily
   UpdateClassification   = $_.UpdateClassification
   Title                  = $id.getElementById("titleDiv").innerText
   #"Last Modified"       = $id.getElementById("dateDiv").innerText.split(":")[1].trim()
   #Size                  = $id.getElementById("sizeDiv").innerText.split(":")[1].trim()
   #Description           = $id.getElementById("descDiv").innerText.split(":")[1].trim()
   #Architecture          = $id.getElementById("archDiv").innerText.split(":")[1].trim()
   #Classification        = $id.getElementById("classificationDiv").innerText.split(":")[1].trim()
   #"Supported products"  = $id.getElementById("productsDiv").innerText.split(":")[1].trim()
   #"Supported languages" = $id.getElementById("languagesDiv").innerText.split(":")[1].trim()
   #"MSRC number"         = $id.getElementById("securityBullitenDiv").innerText.split(":")[1].trim()
   #"MSRC severity"       = $id.getElementById("msrcSeverityDiv").innerText.split(":")[1].trim()
   "KB article number"    = $id.getElementById("kbDiv").innerText.split(":")[1].trim()
   #"More information"    = $id.getElementById("moreInfoDiv").innerText.split()[4].trim()
   Child                  = $id.getElementById("supersededbyInfo").innerText#| sls "KB?\d+" -a | %{$_.Matches} | %{$_.Value}
   #Parent                = $id.getElementById("supersedesInfo").innerText#| sls "KB?\d+" -a | %{$_.Matches} | %{$_.Value}
}}} | ?{$_."KB article number" -like $KB -and $_.Architecture -like $Architecture}
}

function Invoke-Update
{
param($Year = "*",$Month = "*",$Day = "*",$Product = "*",$ProductFamily = "*",$KB = "*",$Architecture="*",$Language = "German",$Child = "No")
Get-Update $Year $Month $Day $Product $ProductFamily $KB $Architecture | %{
$kb2 = $_."KB article number"
$bez = $_.Title
$pro = $_.Product
$pf = $_.ProductFamily
$na = $_.Child
$lk1 = iwr "http://www.bing.com/search?q=$bez" | %{$_.links.href} | ?{$_ -like "http://www.microsoft.com/en-us/download/details.aspx?id=*"} | select -f 1
if((iwr $lk1 | %{$_.ParsedHtml.getElementsByTagName("select")} | %{$_.textContent} | sls "\w+ *\(*\w+ *\w+ *\w+\)*" -a | %{$_.Matches} | %{$_.Value}) -contains $Language){$cc = Set-Lang $Language}else{$cc = "en-us"}
$nr = $lk1 | sls "\d+" | %{$_.Matches} | %{$_.Value}
$lk2 = iwr "http://www.microsoft.com/$cc/download/details.aspx?id=$nr" | %{$_.links.href} | ?{$_ -like "http://download.microsoft.com/download/*"}
$lk3 = iwr "http://www.microsoft.com/$cc/download/confirmation.aspx?id=$nr" | %{$_.links.href} | ?{$_ -like "http://download.microsoft.com/download/*"}
$lk2 + $lk3 | %{
$file = $_.split("/")[-1]
if((Test-Path .\$pf) -eq $false){mkdir .\$pf | Out-Null}
if((Test-Path .\$pf\$pro) -eq $false){mkdir .\$pf\$pro | Out-Null}
if((Test-Path .\$pf\$pro\$file) -eq $false -and ($file -like "*.exe" -or $file -like "*.msu" -or $file -like "*.cab")){
if($Child -eq "No"){if($na -notmatch "KB?\d+"){Start-BitsTransfer $_ .\$pf\$pro\$file}}else{Start-BitsTransfer $_ .\$pf\$pro\$file}}
New-Object PSObject -Property @{
   KB               = $kb2
   Title            = $bez
   Product          = $pro
   ProductFamily    = $pf
   Link             = $lk1.replace("en-us",$cc)
   Download         = $_
   Filename         = $file
   Child            = $na
}}}
}

function Set-Lang
{
param($lang)
if($lang -eq "Bulgarian"){echo "bg-bg"}
elseif($lang -eq "Chinese (Hong Kong SAR)"){echo "zh-hk"}
elseif($lang -eq "Chinese (Simplified)"){echo "zh-cn"}
elseif($lang -eq "Chinese (Traditional)"){echo "zh-tw"}
elseif($lang -eq "Croatian"){echo "hr-hr"}
elseif($lang -eq "Czech"){echo "cs-cz"}
elseif($lang -eq "Danish"){echo "da-dk"}
elseif($lang -eq "Dutch"){echo "nl-nl"}
elseif($lang -eq "English"){echo "en-us"}
elseif($lang -eq "Estonian"){echo "et-ee"}
elseif($lang -eq "Finnish"){echo "fi-fi"}
elseif($lang -eq "French"){echo "fr-fr"}
elseif($lang -eq "German"){echo "de-de"}
elseif($lang -eq "Greek"){echo "el-gr"}
elseif($lang -eq "Hungarian"){echo "hu-hu"}
elseif($lang -eq "Italian"){echo "it-it"}
elseif($lang -eq "Japanese"){echo "ja-jp"}
elseif($lang -eq "Korean"){echo "ko-kr"}
elseif($lang -eq "Latvian"){echo "lv-lv"}
elseif($lang -eq "Norwegian (Bokmål)"){echo "nb-no"}
elseif($lang -eq "Polish"){echo "pl-pl"}
elseif($lang -eq "Portuguese (Brazil)"){echo "pt-br"}
elseif($lang -eq "Portuguese (Portugal)"){echo "pt-pt"}
elseif($lang -eq "Romanian"){echo "ro-ro"}
elseif($lang -eq "Russian"){echo "ru-ru"}
elseif($lang -eq "Serbian (Cyrillic)"){echo ""}
elseif($lang -eq "Slovak"){echo "sk-sk"}
elseif($lang -eq "Slovenian"){echo "sl-si"}
elseif($lang -eq "Spanish"){echo "es-es"}
elseif($lang -eq "Swedish"){echo "sv-se"}
elseif($lang -eq "Thai"){echo "th-th"}
elseif($lang -eq "Turkish"){echo "tr-tr"}
elseif($lang -eq "Ukrainian"){echo "uk-ua"}
else{echo "en-us"}
}

function Get-UpdCommand
{
param($Command)
$cms = @{
"Get-UpdXML"="Get-UpdXML [-Year] <Int> [-Month] <Int> [-Day] <Int> [-Product] <String> [-ProductFamily] <String>";
"Get-Update"="Get-Update [-Year] <Int> [-Month] <Int> [-Day] <Int> [-Product] <String> [-ProductFamily] <String> [-KB] <Int> [-Architecture] <String>";
"Invoke-Update"="Invoke-Update [-Year] <Int> [-Month] <Int> [-Day] <Int> [-Product] <String> [-ProductFamily] <String> [-KB] <Int> [-Architecture] <String> [-Language] <String> [-Child] <String>";
"Get-UpdCommand"="Get-UpdCommand [-Command] <String>"
}
if($Command){
if($cms.keys -contains $Command){return $cms[$Command]}
else{echo "$Command is not a valid MS-UPD-Load Module Cmdlet."}}
else{$list = @()
foreach($cmd in $cms.keys){
$li = New-Object PSObject
$li | Add-Member NoteProperty Name($cmd)
$li | Add-Member NoteProperty Definition($cms[$cmd])
$list += $li}
return $list | sort {$_.Name}}
}

Export-ModuleMember Get-UpdXML,Get-Update,Invoke-Update,Get-UpdCommand