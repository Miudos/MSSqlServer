# MSSqlServer
PowerShell Sql Server Scripts

Many of projects I work on, involve to collect basic information about MS Sql Server, such as: Server and MS Sql Sever information, disk alignments and so one.

This script will collect basic informations from MS Sql Server and outputs to an HTML file. The data collected help us to verify best practices applied to the server.

Extra explanations:
SqlServerPerfCheck_v1.ps1

This script was designed to build a MS Sql Server inventory. This script collects MS Sql Server information and outputs to an html file.
	This script will get:
		Disk sector size,
		Server and databases properties and size,
		Sql Server Version and Infos,
		Io Stall,
		Top waittypes,
		Top 10 cache bloats,
		Current values for MS Sql Server counter Buffer Manager,
		Last dbcc checkdb executed,
		Last 24h log data.
	
	It can be executed on multiple servers, using a text file as a parameter.

	PARAMETER EXPLANATIONS:
	
	$serverList:
		*Path to a text file with server list to scan.
		*You dont need to specify server and instance. Only the server name or Ip.
		*For all servers provided you must execute under an user context with administration rights in Windows OS and Sql Server.

		File name sample: srvList.tx
		File content:
		Server_Name_Or_IP_01
		Server_Name_Or_IP_02
		Server_Name_Or_IP_03
		[...]
	
	> SqlServerPerfCheck_v1.ps1 ./srvList.txt


