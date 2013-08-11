
			Search-Wmi -ForName '*network*' -Namespace 'root\cimv2' |
				Update-WmiSpy -wmiViewName 'Search-Wmi -ForName ''*network*'' -Namespace ''root\cimv2'''
			
