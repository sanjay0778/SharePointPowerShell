
## check to ensure Microsoft.SharePoint.PowerShell is loaded if not using the SharePoint Management Shell 
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'} 
if ($snapin -eq $null) 
{    
	Write-Host "Loading SharePoint Powershell Snapin"    
	Add-PSSnapin "Microsoft.SharePoint.Powershell" 
}

function main
{
# provide name of your wsp file 
$sol_name = "MyWSPSolution";
#provide url of web application where you want to deploy wsp.
$web_app = "https://myintranet.test.net/";
# delete, retract,  install and deploy the site definitions
DeleteSolution -solutionID "$sol_name.wsp" -solutionPath "$PWD" -webApplication "$web_app"
DeploySolution -solutionID "$sol_name.wsp" -solutionPath "$PWD" -webApplication "$web_app"

}

## this method will delete and retract the solution. You will need to call it
## with the solution id and the webapplication. If it is globally deployed just
## leave the web application empty
function DeleteSolution
{
	param ([string]$solutionID, [string]$webApplication)

	$farm = Get-SPFarm

	$sol = $farm.Solutions[$solutionID]

	if($sol)
	{
		Write-Host -f Yellow "Going to uninstall $solutionID"

		if( $sol.Deployed -eq $TRUE ) 
		{
			if ( $webApplication -eq "" )
			{
				Uninstall-SPSolution -Identity $solutionID -Confirm:0
			}
			else 
			{
				Uninstall-SPSolution -Identity $solutionID -Confirm:0 -Webapplication $webApplication
			}

			while( $sol.JobExists ) 
			{
				Write-Host "waiting for retraction."
				sleep 3
			}
		}

		Write-Host -f Yellow "Going to Remove $solutionID"
		Remove-SPSolution -Identity $solutionID -Force -Confirm:0

		Write-Host -f Green $solutionID is deleted from this Farm
	}
	else
	{
		Write-Host -f Yellow "Solution $solutionID not found"
	}
}

## This method installs and deploys a solution based on its solution id, path and web application.
## If the solution should be deployed globally just leave the web application empty
function DeploySolution
{
	param ([string]$solutionID, [string]$solutionPath, [string]$webApplication)

	$filename = $solutionPath + "\" + $solutionID

	Write-Host -f White "Deploy solution $solutionID from $filename to webapplication $webApplication"

	Add-SPSolution $filename

	Write-Host -f Green "Solution $solutionID added"

	Write-Host -f Yellow "Installing $solutionID into web application"

	if ( $webApplication -eq "" )
	{
		Install-SPSolution -Identity $solutionID -GACDeployment -Force
	}
	else
	{
		Install-SPSolution -Identity $solutionID -WebApplication $webApplication -GACDeployment -Force
	}

	$farm = Get-SPFarm

	$sol = $farm.Solutions[$solutionID]

	if($sol)
	{
		Write-Host -f Yellow "Going to install $solutionID"

		while( $sol.Deployed -eq $FALSE )
		{
			Write-Host "waiting for installation."
			sleep 3
		}

		Write-Host -f Green "Solution $solutionID is installed"
	}
	else
	{
		Write-Host -f Red "Installing $solutionID has failed. Solution is not found."
	}
}

main
pause