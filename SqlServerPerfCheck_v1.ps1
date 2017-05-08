<#
	SqlServerPerfCheck_v1.ps1

	This script was designed to build a MS Sql Server inventory. This script collects MS Sql Server information and outputs to an html file.
	This script will get:
		Disk Alignment
		SQL Server Version
		xp_msver (MS Sql Server version, build and Server environment)
		Sql Server Configurations
		Last Good DBCC executed
		Database Properties
		Database Files Size Details
		Io Stall
		Last 24h Log
		Top 10 Waittypes
		Last Job History
		Cluster Node
		Sql Server Counters
		Top 10 Cache bloat --> Query created by Bart Duncan https://blogs.msdn.microsoft.com/bartd/2010/05/26/finding-procedure-cache-bloat/
	
	It can be executed on multiple servers, using a text file as a parameter.

	PARAMETER EXPLANATIONS:
	
	$serverList:
		*Path to a text file with server list to scan.
		*You dont need to specify server and instance. Only the server name or Ip.
		*For all servers provided you must execute under an user context with administration rights in Windows OS and Sql Server.

		For example:
			*File Name: srvList.tx
			*File content:
				Server_Name_Or_IP_01
				Server_Name_Or_IP_02
				Server_Name_Or_IP_03
				[...]
	
	> SqlServerPerfCheck_v1.ps1 ./srvList.txt

	MIT License

	Copyright (c) 2017 Dobereiner Miller Unlimited

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

#>

param([string] $serverList)

<#
	We start creating the header of HTML generated as a result from the script.
#>

#region Variables
	[string] $Targets
	[string] $Report
	[int] $idTab
	[int] $idAccordion
#endregion

#region Java Script added to the footer of html
function jScript(){
	$tempStr = @"
	(function(){
		var d = document,
		accordionToggles = d.querySelectorAll('.js-accordionTrigger'),
		setAria,
		setAccordionAria,
		switchAccordion,
		touchSupported = ('ontouchstart' in window),
		pointerSupported = ('pointerdown' in window);
	  
	  skipClickDelay = function(e){
		e.preventDefault();
		e.target.click();
	  }
			setAriaAttr = function(el, ariaType, newProperty){
			el.setAttribute(ariaType, newProperty);
		};
		setAccordionAria = function(el1, el2, expanded){
			switch(expanded) {
		  case "true":
			setAriaAttr(el1, 'aria-expanded', 'true');
			setAriaAttr(el2, 'aria-hidden', 'false');
			break;
		  case "false":
			setAriaAttr(el1, 'aria-expanded', 'false');
			setAriaAttr(el2, 'aria-hidden', 'true');
			break;
		  default:
			break;
			}
		};
	switchAccordion = function(e) {
	  console.log("triggered");
		e.preventDefault();
		var tChildElement = e.target.parentNode.nextElementSibling;
		var tParentElement = e.target;
		if(tChildElement.classList.contains('is-collapsed')) {
			setAccordionAria(tParentElement, tChildElement, 'true');
		} else {
			setAccordionAria(tParentElement, tChildElement, 'false');
		}
		tParentElement.classList.toggle('is-collapsed');
		tParentElement.classList.toggle('is-expanded');
			tChildElement.classList.toggle('is-collapsed');
			tChildElement.classList.toggle('is-expanded');
		
		tChildElement.classList.toggle('aCol');
		};
		for (var i=0,len=accordionToggles.length; i<len; i++) {
			if(touchSupported) {
		  accordionToggles[i].addEventListener('touchstart', skipClickDelay, false);
		}
		if(pointerSupported){
		  accordionToggles[i].addEventListener('pointerdown', skipClickDelay, false);
		}
		accordionToggles[i].addEventListener('click', switchAccordion, false);
	  }
	})
	();
"@
return $tempStr
}
#endregion

#region Css Builder
function cssScript(){
$tempStr = @"
		*{box-sizing:border-box;}
		@import url(http://fonts.googleapis.com/css?family=Lato:400,700);
		body{font-family:'Lato';}
		.heading-primary{font-size:2em;padding:2em;text-align:center;}
        dl {display: block;-webkit-margin-before: 2px;-webkit-margin-after: 0;-webkit-margin-start: 0px;-webkit-margin-end: 0px;}
		.expandedDiv dl,.accordion-list {border:1px solid #ddd;&:after {content: "";display:block;height:1em;width:100%;background-color:#073269;}}
		.expandedDiv dd,.accordion__panel {background-color:#eee;font-size:1em;}
		.expandedDiv p {padding-right:2em;}
		.expandedDiv {position:relative;background-color:#eee;}
		.expandedDiv dl dt{border:1px solid #fff;}
		.container {max-width:1100px; padding:0 0 2em 0;}
		.accordionTitle,.accordion__Heading {background-color:#073269;text-align:center;font-weight:700;padding:5px 2em 5px 2em;display:block;text-decoration:none;color:#fff;transition:background-color 0.5s ease-in-out;border-bottom:1px solid darken(#38cc70, 5%);&:before {content: "+";font-size:1.5em;line-height:0.5em;float:left;transition: transform 0.3s ease-in-out;}&:hover {background-color:darken(#38cc70, 10%);}}
		.accordionTitleActive,.accordionTitle.is-expanded {background-color#073269;&:before {transform:rotate(-225deg);}}
		.accordionItem{height:auto;overflow:hidden;@media screen and (min-width:48em) {max-height:15em;transition:max-height 0.5s}}
		.accordionItem.is-collapsed{max-height:0;}
		.no-js .accordionItem.is-collapsed{max-height: auto;}
		.aCol{animation: aCollapse 0.45s normal ease-in-out both 1;}
		@keyframes aCollapse {0% {opacity: 0;trnsform:scale(0.9) rotateX(-60deg);transform-origin: 50% 0;}100% {opacity:1;transform:scale(1);}}
		@keyframes aExpand {0% {opacity: 1;transform:scale(1);}100% {opacity:0;transform:scale(0.9) rotateX(-60deg);}}

		.tabs {position: relative;clear: both;margin: 35px 0 25px;background: white;}
		.tab {float: left;}
		.tab label {background: #eee;padding: 10px;border: 1px solid #ccc;margin-left: -1px;position: relative;left: 1px;top: -29px;-webkit-transition: background-color .17s linear;}
		.tab [type=radio] {display: none;}
		.content {position: absolute;top: -1px;left: 0;background: white;right: 0;bottom: 0;border: 1px solid #ccc;-webkit-transition: opacity .6s linear;opacity: 0;}
		[type=radio]:checked ~ label {background: white;border-bottom: 1px solid white;z-index: 2;}
		[type=radio]:checked ~ label ~ .content {z-index: 1;opacity: 1;}

        th, td {padding: 15px;text-align: left;border: 1px solid #ccc}
        td {overflow:hidden;}
"@
	return $tempStr
}
#endregion

#region html Header
function htmlHeaderDeclaration(){
$tempStr = @"
	<html lang="en">
	<head>
	  <meta charset="utf-8">
	  <meta name="viewport" content="width=device-width, initial-scale=1">
	  <title>Sql Server Report</title>
	  <style>
"@

$tempStr += cssScript

$tempStr += @"
	</style>
	</head>
	<html>
		<body>
		<div class="container">
				<div class="tabs">		
"@

return $tempStr
}
#endregion

#region html tab header and footer
function htmlTabHeader(){
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[string] $currentServerName
			)
	$tempStr = @"
					<div class="tab">
						<input type="radio" id="tab-$idTab" name="tab-group-1" checked />
						<label for="tab-$idTab">$currentServerName</label>
						<div class="content">
"@

	return $tempStr
}

function htmlTabFooter(){
	return "
						</div>
					</div>
		"
}
#endregion

#region html accordion header and footer
function htmlAccordionHeader(){
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[string] $nodeTitle
			)
$tempStr = @"

							<div class="accordion">
								<dl>
									<dt>
										<a href="#$idAccordion" aria-expanded="false" aria-controls="$idAccordion" class="accordion-title accordionTitle js-accordionTrigger">$nodeTitle</a>
									</dt>
									<dd class="accordion-content accordionItem is-collapsed" id="$idAccordion" aria-hidden="true">

"@

	return $tempStr
}

function htmlAccordionFooter(){

	return "
									</dd>
								</dl>
							</div>
	"
}

#enregion

#region DATA BASE
function ConnectToDb(){
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[object] $target,
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=1)]
			[string] $sqlCommand
		)
	$connectionDetails = "Provider=sqloledb; " +
						"Data Source=$target; " +
						"Initial Catalog=master; " +
						"Integrated Security=SSPI;"

	$connection = New-Object System.Data.OleDb.OleDbConnection $connectionDetails
	$command = New-Object System.Data.OleDb.OleDbCommand $sqlCommand,$connection
	$command.CommandTimeout = 0
	$connection.Open()

	$dataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
	$dataSet = New-Object System.Data.DataSet
	$dataAdapter.Fill($dataSet) | Out-Null

	$connection.Close()
	return $dataSet
}

function parseColumnsName(){
	[CmdletBinding()]
	[OutputType([string])]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.Data.DataSet] $dataSet	
    )
	$x =0
	$dataitem = $dataSet.Tables
	
	$tempStr = "<tr>"
	foreach($col in $dataitem.Columns){
		$tempStr += "<th><b>$($col.ColumnName)</b></th>"
	}
	$tempStr+= "</tr>"
	
	return $tempStr	
}

function parseDataset(){
	[CmdletBinding()]
	[OutputType([string])]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.Data.DataSet] $dataSet
    )
	$tempStr=""
	$dataitem = $dataSet.Tables
	foreach ($item in $dataitem.Rows)
	{
		$tempStr+= "<tr>"
		foreach($col in $item.ItemArray){
			if ($col -like "*|*"){
				$r = $col.Split("|")
				$tempStr += "<td bgcolor='$($r[1])'>$($r[0])</td>"
			}else{
				$tempStr += "<td>$($col)</td>"
			}
			$x++
		}
		$tempStr+= "</tr>"
	}
	return $tempStr
}

function collectData(){
	[CmdletBinding()]
	[OutputType([string])]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string] $currentServer,	
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string] $sqlCommand,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string] $title
    )

	$tempStr = htmlAccordionHeader $title

		$tempStr += "<table>"

		$dataSet = ConnectToDb $currentServer $sqlCommand
		try{
			$tempStr+= parseColumnsName $dataSet	
		}
		catch{}

		try{
			$tempStr1 = parseDataset $dataSet
			$tempStr+= $tempStr1
		}
		catch{}
		
		$tempStr += "</table>"

	$tempStr += htmlAccordionFooter
	
	return $tempStr
}
#endregion

#region Get Sql Instances Name
Function Get-SqlInstances() {
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[object] $currentServerName
			)
  $localInstances = @()
  [array]$captions = gwmi win32_service -computerName $currentServerName | ?{$_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe"} | %{$_.Caption}
  foreach ($caption in $captions) {
    if ($caption -like "*MSSQLSERVER*") {
      $localInstances += ""
    } else {
      $temp = $caption | %{$_.split(" ")[-1]} | %{$_.trimStart("(")} | %{$_.trimEnd(")")}
      $localInstances += "\$temp"
    }
  }
  return $localInstances
}
#endregion

#region Get Disk Bytes Per Cluster
function GetDiskBytesPerCluster()
{
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[string] $drive,
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=1)]
			[string] $currentServerName
			)

    $wql = "SELECT BlockSize FROM Win32_Volume " + `
           "WHERE DriveLetter = '" + $drive + "'"
    $BytesPerCluster = Get-WmiObject -Query $wql -ComputerName $currentServerName `
                        | Select-Object BlockSize

    #$BytesPerCluster  = Get-WmiObject -Class Win32_Volume | ? DriveLetter -EQ "$drive" |  Select-Object BlockSize

    return $BytesPerCluster.BlockSize /1024;
}
#endregion Get Disk Bytes Per Cluster

#region Disk Alignment
function Get-DiskAlignment(){
	[CmdletBinding()]
	[OutputType([System.Data.DataSet])]
	Param(
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=0)]
			[string] $currentServerName,
			[Parameter(Mandatory=$true,
				ValueFromPipelineByPropertyName=$true,
				Position=1)]
			[string] $title
			)

    	$tempStr = htmlAccordionHeader $title


		$drives = Get-WmiObject Win32_DiskDrive -ComputerName $currentServerName

		$s = New-Object System.Management.ManagementObjectSearcher
		$s.Scope = "\\$Target\root\cimv2"
		$s2 = New-Object System.Management.ManagementObjectSearcher
		$s2.Scope = "\\$Target\root\cimv2"

		$qPartition = new-object System.Management.RelatedObjectQuery 
		$qPartition.RelationshipClass = 'Win32_DiskDriveToDiskPartition' 

		$qLogicalDisk = new-object System.Management.RelatedObjectQuery 
		$qLogicalDisk.RelationshipClass = 'Win32_LogicalDiskToPartition' 

		$tempStr += "
			<table>
				<tr>
					<th width='10%'><b>Name</b></th>
					<th width='5%'><b>Drive Letter</b></th>
					<th width='10%'><b>Label</b></th>
					<th width='5%'><b>Size(GB)</b></th>
					<th width='10%'><b>File System</b></th>
					<th width='10%'><b>BlockSize</b></th>
					<th width='10%'><b>Offset</b></th>
					<th width='5%'><b>Index</b></th>
					<th width='5%'><b>IsPrimary</b></th>
					<th width='10%'><b>Disk Free Space</b></th>
					<th width='10%'><b>% Free Space</b></th>
				</tr>"
			
		$drives | Sort-Object DeviceID | % { 
		   $qPartition.SourceObject = $_ 
		   $s.Query= $qPartition
		   $s.Get()| where {$_.Type -ne 'Unknown'} |% {
		   
		   $partition = $_;
		   
		   $partitionSize = ([math]::round(($($_.Size)/1GB),1))
			   $qLogicalDisk.SourceObject = $_ 
			   $s2.Query= $qLogicalDisk.QueryString
			   $s2.Get()|% { 
			   
				$disksize = [math]::round(($_.size / 1048576))
				$freespace = [math]::round(($_.FreeSpace / 1048576))
				$percFreespace=[math]::round(((($_.FreeSpace / 1048576)/($_.size / 1048676)) * 100),0)

				$bytesPerCluster = GetDiskBytesPerCluster $_.DeviceID $currentServerName

			   $tempStr += "
					<tr>
						<td width='15%'>$($partition.Name)</td>
						<td width='10%'>$($_.DeviceID)</td>
						<td width='10%'>$($_.VolumeName)</td>
						<td width='5%'>$PartitionSize GB</td>
						<td width='10%'>$($_.FileSystem)</td>
						<td width='10%'>$bytesPerCluster KB</td>
						<td width='10%'>$($partition.StartingOffset)</td>
						<td width='5%'>$($partition.DiskIndex)</td>
						<td width='5%'>$($partition.PrimaryPartition)</td>
						<td width='10%'>$Freespace MB</td>
						<td width='10%'>$percFreespace%</td>
					</tr>"
				}
			} 
		}

		$tempStr+= "
			</table>
		"
        
        $tempStr += htmlAccordionFooter
    return $tempStr
}
#endregion

#region Script Summary
Write-Host "#######################################################################################"
Write-Host "## Script: SqlServerPerfCheck_v1.ps1                                                 ##"
Write-Host "## Version: 1                                                                        ##"
Write-Host "## Copyright (c) 2017 Dobereiner Miller Unlimited                                    ##"
Write-Host "## Under MIT license                                                                 ##"
Write-Host "## https://github.com/Miudos/MSSqlServer                                             ##"
Write-Host "#######################################################################################"
Write-Host ""
Write-Host ""
#endregion

$date = Get-Date
$idTab = 0

$Filename_ = "\Sql_DiskAlignment_Report_" + $date.Hour + $date.Minute + "_" + $date.Day + "-" + $date.Month + "-" + $date.Year + ".htm"
$Filename = "." + $Filename_

$Report = htmlHeaderDeclaration

#region Parse Scripts params
	if ($serverList -eq ""){
		Write-Host "No list specified, using $env:computername"
		$Targets = $env:computername
	}
	else
	{
		if ((Test-Path $serverList) -eq $false)
		{
			Write-Host "Please provide a path where are a text file with servers name list, separated by break line: $auditlist"
			exit
		}
		else
		{
			Write-Host "Using server list: $serverList"
			$Targets = Get-Content $serverList
		}
	}
#endregion


Foreach ($Target in $Targets)
{
	$currentServerName = $Target
	$Instances = Get-SqlInstances $currentServerName
	$idAccordion = 0
	
	foreach($instance in $Instances){
		$currentServer = $Target + $instance
		write-host "Server: $currentServer"
		
		$idTab = $idTab + 1
		
		$Report += htmlTabHeader $currentServer

		$idAccordion = $idAccordion + 1
        $Report += Get-DiskAlignment $currentServerName "Disk Alignment"

		$sqlCommand = "SELECT @@version AS 'version'"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "SQL Server Version"

		$sqlCommand = "EXEC xp_msver"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "xp_msver"

		$sqlCommand = "select name, value_in_use FROM sys.configurations"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Sql Server Configurations"

		$sqlCommand = "Declare @DBINFO Table(ParentObject nvarchar(255),[object] nvarchar(255), field nvarchar(255), value nvarchar(255)) 
			INSERT INTO @DBINFO 
			exec sp_MSforeachdb 'DBCC DBINFO(?) WITH tableRESULTS' 
			SELECT field, value FROM @DBINFO where field in ('dbi_dbname', 'dbi_dbccLastKnownGood')"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Last Good DBCC executed"

		$sqlCommand = "DECLARE @dbCols VARCHAR(MAX) = STUFF((SELECT DISTINCT ',' + 'convert(nvarchar(max),' + QUOTENAME(name) + ') as ' + QUOTENAME(name)
				FROM sys.syscolumns
				WHERE
					id = OBJECT_ID('sys.databases')
					and name not like '%_desc'
					and name != 'name'
				FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)')
				,1,1,'')

				DECLARE @listCols VARCHAR(MAX) = STUFF((SELECT DISTINCT ',' + QUOTENAME(name)
						FROM sys.syscolumns
						WHERE
							id = OBJECT_ID('sys.databases')
							and name not like '%_desc'
							and name != 'name'
						FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)')
						,1,1,'')
				declare @sql nvarchar(max)

				SET  @sql  =  'SELECT col,value 
							   FROM  (SELECT convert(nvarchar(max), name) as name, '+@dbCols+' FROM  sys.databases)  p
							   UNPIVOT (value FOR  col  IN  (name,'+@listCols+'))  as  unpvt
							  '

				exec (@sql)"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Database Properties"

		$sqlCommand = "Create Table #dbFileSpaceUsed (
			[dbid] smallint, dbname sysname, filegroupID smallint NULL, 
			[filename] varchar(520) NULL, size_MB decimal(10,2) null, 
			used_MB decimal(10,2) null, free_MB decimal(10,2) null, 
			percentused decimal(10,2) null, percentfree decimal(10,2) null, maxSize_GB decimal(10,2) null)

			Declare @sSql varchar(1000)
			Set @sSql = 'Use [?];
			insert #dbFileSpaceUsed ([dbid], dbname, filegroupID, [filename], size_MB, used_MB, maxSize_GB)
			select db_id(), db_name(), groupid, filename, Cast(size/128.0 As Decimal(10,2)), 
			cast(Fileproperty(name, ''SpaceUsed'')/128.0 As Decimal(10,2)), convert(decimal(10,2),round((sysfiles.maxsize/128.000)/1024,2)) from dbo.sysfiles Order By groupid Desc;'

			Exec sp_MSforeachdb @sSql
			Update #dbFileSpaceUsed Set free_MB = size_MB - used_MB, percentused = (used_MB/size_MB)*100, percentfree = ((size_MB-used_MB)/size_MB)*100

			select dbname, filegroupID, [size_MB], [used_MB], [free_MB], [percentused], [percentfree], maxSize_GB from #dbFileSpaceUsed

			if (OBJECT_ID('tempdb..#dbFileSpaceUsed') is not null) drop table #dbFileSpaceUsed"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Database Files Size Details"

		$sqlCommand = "SELECT [database_id], [file_id],
					case when [io_stall_read_ms] <1 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Excelent' + '|' + '00FFB9'
							when [io_stall_read_ms] >=1 and [io_stall_read_ms] <=4 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Very Good' + '|' + 'C9FFA8'
							when [io_stall_read_ms] >=5 and [io_stall_read_ms] <=9 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Good' + '|' + '149ACC'
							when [io_stall_read_ms] >=10 and [io_stall_read_ms] <=19 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Poor' + '|' + 'FFFE67'
							when [io_stall_read_ms] >=20 and [io_stall_read_ms] <=99 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Bad' + '|' + 'CC5459'
							when [io_stall_read_ms] >=100 and [io_stall_read_ms] <=499 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Very Bad' + '|' + 'FF4D3E'
							when [io_stall_read_ms] >=500 then cast([io_stall_read_ms] as varchar(6)) + 'ms - Critical' + '|' + 'CC123B' end [io_stall_read_ms]
				, case when [io_stall_write_ms] <1 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Excelent' + '|' + '00FFB9'
							when [io_stall_write_ms] >=1 and [io_stall_write_ms] <=4 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Very Good'+ '|' + 'C9FFA8'
							when [io_stall_write_ms] >=5 and [io_stall_write_ms] <=9 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Good'+ '|' + '149ACC'
							when [io_stall_write_ms] >=10 and [io_stall_write_ms] <=19 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Poor'+ '|' + 'FFFE67'
							when [io_stall_write_ms] >=20 and [io_stall_write_ms] <=99 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Bad'+ '|' + 'CC5459'
							when [io_stall_write_ms] >=100 and [io_stall_write_ms] <=499 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Very Bad'+ '|' + 'FF4D3E'
							when [io_stall_write_ms] >=500 then cast([io_stall_write_ms] as varchar(6)) + 'ms - Critical'+ '|' + 'CC123B' end [io_stall_write_ms]
				, [physical_name]
							  FROM (SELECT
				divfs.[database_id],divfs.[file_id],
				[io_stall_read_ms] =
					CASE WHEN divfs.[num_of_reads] = 0
						THEN 0 ELSE (divfs.[io_stall_read_ms] / divfs.[num_of_reads]) END,
				[io_stall_write_ms] =
					CASE WHEN divfs.[num_of_writes] = 0
						THEN 0 ELSE (divfs.[io_stall_write_ms] / divfs.[num_of_writes]) END,
				mf.physical_name
			FROM
			sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
				JOIN sys.master_files AS mf ON
			mf.database_id = divfs.database_id
				AND mf.file_id = divfs.file_id) iostall"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "IO Stall"

		$sqlCommand = "DECLARE @logs table (LogDate DATETIME, ProcessInfo VARCHAR(255), [Text] VARCHAR(MAX))
			declare @texto varchar(max)

			set @texto = 'xp_readerrorlog 0, 1, N'''', N'''', ' + '''' + convert(varchar(8), getdate()-2, 112) + ' 07:01' + ''', ''' +  convert(varchar(8), getdate(), 112) + ' 07:00' + ''', ''DESC'''

			INSERT INTO @logs exec(@texto)
			select LogDate, ProcessInfo, Text from @logs where ProcessInfo like 'error:%' or ProcessInfo like '%state: 1.%' or ProcessInfo like '%backup%'
"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Last 24h Log"

		$sqlCommand = "SELECT TOP 10 wait_type, max_wait_time_ms, signal_wait_time_ms, signal_wait_time_ms - signal_wait_time_ms resource_wait_time_ms,
			(100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( )) percent_total_waits, (100.0 * signal_wait_time_ms / SUM(signal_wait_time_ms) OVER ( )) percent_total_signal_waits,
			(100.0 * ( wait_time_ms - signal_wait_time_ms ) / SUM(wait_time_ms) OVER ( )) percent_total_resource_waits FROM sys.dm_os_wait_stats
		WHERE wait_time_ms > 0 AND wait_type NOT IN 
			('SLEEP_TASK', 'BROKER_TASK_STOP', 'BROKER_TO_FLUSH', 'SQLTRACE_BUFFER_FLUSH',
			  'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 'LAZYWRITER_SLEEP', 'SLEEP_SYSTEMTASK',
			  'SLEEP_BPOOL_FLUSH', 'BROKER_EVENTHANDLER', 'XE_DISPATCHER_WAIT',
			  'FT_IFTSHC_MUTEX', 'CHECKPOINT_QUEUE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
			  'BROKER_TRANSMITTER', 'FT_IFTSHC_MUTEX', 'KSOURCE_WAKEUP',
			  'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
			  'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BAD_PAGE_PROCESS',
			  'DBMIRROR_EVENTS_QUEUE', 'BROKER_RECEIVE_WAITFOR',
			  'PREEMPTIVE_OS_GETPROCADDRESS', 'PREEMPTIVE_OS_AUTHENTICATIONOPS', 'WAITFOR',
			  'DISPATCHER_QUEUE_SEMAPHORE', 'XE_DISPATCHER_JOIN', 'RESOURCE_QUEUE' )
		ORDER BY wait_time_ms DESC"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Top 10 Waittypes"

		$sqlCommand = "SELECT SysJobs.name,
		Job.run_status, CONVERT(VARCHAR,DATEADD(ms,Job.run_duration,0),114) run_duration, exec_date exec_date_mm_dd_yyyy
		FROM (SELECT Instance.instance_id, DBSysJobHistory.job_id, DBSysJobHistory.step_id, DBSysJobHistory.sql_message_id
			,DBSysJobHistory.sql_severity, DBSysJobHistory.message
			,(CASE DBSysJobHistory.run_status
				WHEN 0 THEN 'Failed|CC123B'
				WHEN 1 THEN 'Succeeded'
				WHEN 2 THEN 'Retry'
				WHEN 3 THEN 'Canceled|FFFE67'
				WHEN 4 THEN 'In progress'
			END) as run_status
			,((SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 5, 2) + '/'
			+ SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 7, 2) + '/'
			+ SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 1, 4) + ' '
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS varchar)))
			+ CAST(DBSysJobHistory.run_time AS VARCHAR)), 1, 2) + ':'
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS VARCHAR)))
			+ CAST(DBSysJobHistory.run_time AS VARCHAR)), 3, 2) + ':'
			+ SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time as varchar)))
			+ CAST(DBSysJobHistory.run_time AS VARCHAR)), 5, 2))) AS 'exec_date'
			,DBSysJobHistory.run_duration
			,DBSysJobHistory.retries_attempted
			,DBSysJobHistory.server
			FROM msdb.dbo.sysjobhistory DBSysJobHistory
			JOIN (SELECT DBSysJobHistory.job_id
				,DBSysJobHistory.step_id
				,MAX(DBSysJobHistory.instance_id) as instance_id
				FROM msdb.dbo.sysjobhistory DBSysJobHistory
				GROUP BY DBSysJobHistory.job_id
				,DBSysJobHistory.step_id
				) AS Instance ON DBSysJobHistory.instance_id = Instance.instance_id
			WHERE DBSysJobHistory.run_status <= 1
			) AS Job
		JOIN msdb.dbo.sysjobs SysJobs
		   ON (Job.job_id = SysJobs.job_id)
		JOIN msdb.dbo.sysjobsteps SysJobSteps
		   ON (Job.job_id = SysJobSteps.job_id AND Job.step_id = SysJobSteps.step_id)
		order by convert(datetime, exec_date, 102) desc"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Last Job History"

		$sqlCommand = "SELECT NodeName FROM sys.dm_os_cluster_nodes"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Cluster Nodes"

		$sqlCommand = "select
			object_name, counter_name, instance_name, cntr_value, cntr_type
		from sys.dm_os_performance_counters
		where object_name like '%Buffer Manager%'"
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Sql Server Counters"
		
		$sqlCommand = "
		WITH duplicated_plans AS (
		SELECT TOP 10
			query_hash,
			(SELECT TOP 1 [sql_handle] FROM sys.dm_exec_query_stats AS s2 WHERE s2.query_hash = s1.query_hash ORDER BY [sql_handle]) AS sample_sql_handle,
			(SELECT TOP 1 statement_start_offset FROM sys.dm_exec_query_stats AS s2 WHERE s2.query_hash = s1.query_hash ORDER BY [sql_handle]) AS sample_statement_start_offset,
			(SELECT TOP 1 statement_end_offset FROM sys.dm_exec_query_stats AS s2 WHERE s2.query_hash = s1.query_hash ORDER BY [sql_handle]) AS sample_statement_end_offset,
			CAST (pa.value AS INT) AS dbid,
			COUNT(*) AS plan_count 
			FROM sys.dm_exec_query_stats AS s1
			OUTER APPLY sys.dm_exec_plan_attributes (s1.plan_handle) AS pa 
			WHERE pa.attribute = 'dbid'
			GROUP BY query_hash, pa.value
			ORDER BY COUNT(*) DESC
			)
			SELECT
				plan_count,
				CONVERT (NVARCHAR(80), REPLACE (REPLACE (
					LTRIM (
						SUBSTRING (
							sql.[text],
							(sample_statement_start_offset / 2) + 1,
							CASE
								WHEN sample_statement_end_offset = -1 THEN DATALENGTH (sql.[text])
								ELSE sample_statement_end_offset 
							END - (sample_statement_start_offset / 2)
						)
					),
					CHAR(10), ''), CHAR(13), '')) AS qry,
				OBJECT_NAME (sql.objectid, sql.[dbid]) AS [object_name],
				DB_NAME (duplicated_plans.[dbid]) AS [database_name]
			FROM duplicated_plans 
			CROSS APPLY sys.dm_exec_sql_text (duplicated_plans.sample_sql_handle) AS sql
			WHERE ISNULL (duplicated_plans.[dbid], 0) != 32767 --ignore queries from Resource DB 
			AND plan_count > 1;
			"		
		$idAccordion = $idAccordion + 1
		$Report+= collectData $currentServer $sqlCommand "Top 10 Cache Bloat"
			
		$Report += htmlTabFooter
	}
	
}

$Report += $("<script>" + (jScript) + "</script>")

$Report+= @"
		</body>
	</html>
"@

$Report | out-file -encoding ASCII -filepath $Filename | out-null
Write-Host ""
$date = Get-Date
Write-Host "File Created... " $date

