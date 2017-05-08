# PowerShell to collect MS Sql Server Basic Information

Many of projects I work on, involve collecting basic information about MS Sql Server, such as: Server and MS Sql Sever information, disk alignments and so one.

This script will collect basic informations from MS Sql Server and outputs to an HTML file. The data collected help us to verify best practices applied to the server.

Extra explanations:
SqlServerPerfCheck_v1.ps1

This script was designed to build a MS Sql Server inventory. This script collects MS Sql Server information and outputs to an html file.
	This script will get:
- Disk Alignment
- SQL Server Version
- xp_msver (MS Sql Server version, build and Server environment)
- Sql Server Configurations
- Last Good DBCC executed
- Database Properties
- Database Files Size Details
- Io Stall
- Last 24h Log
- Top 10 Waittypes
- Last Job History
- Cluster Node
- Sql Server Counters
- Top 10 Cache bloat --> Query created by Bart Duncan https://blogs.msdn.microsoft.com/bartd/2010/05/26/finding-procedure-cache-bloat/
	
	It can be executed on multiple servers, using a text file as a parameter.

	PARAMETER EXPLANATIONS:
	
	$serverList: Optional - If empty this script will consider the local server.

*Path to a text file with a list of servers name or IP address.

*You dont need to specify server and instance. Only the server name or Ip.

*For all servers provided you must execute under an user context with administration rights in Windows OS and Sql Server.
```
E.g.:
		File name: srvList.tx
		File content:
		Server_Name_Or_IP_01
		Server_Name_Or_IP_02
		Server_Name_Or_IP_03
		[...]
	
	> SqlServerPerfCheck_v1.ps1 ./srvList.txt
```
