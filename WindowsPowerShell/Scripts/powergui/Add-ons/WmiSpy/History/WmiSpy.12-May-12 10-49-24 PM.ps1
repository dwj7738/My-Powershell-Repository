
			Search-Wmi -ForName '*computer*' -Namespace 'root\cimv2' |
				Update-WmiSpy -wmiViewName 'Search-Wmi -ForName ''*computer*'' -Namespace ''root\cimv2'''
			
