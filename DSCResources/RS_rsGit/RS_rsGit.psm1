﻿Function Invoke-Process {
    Param($FileName,$Arguments,$timeout)
    if (!($timeout)) {$timeout = 60}
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $FileName
	    Arguments = $Arguments
	    CreateNoWindow = $true
	    RedirectStandardError = $true
	    RedirectStandardOutput = $true
	    UseShellExecute = $false
    }
    $proc.Start() | Out-Null
    if (!($proc.WaitForExit($timeout*1000))) {$proc.kill()}
    $stderr = $proc.StandardError.ReadToEnd()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $proc.close()
    $proc = $null
    $result = @()
    $result += New-Object psObject -Property @{
        'stdOut'=$stdout
        'stdErr'=$stderr
    } 
    return $result
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter(Mandatory = $true)]
        [string]
        $Source,
        [parameter(Mandatory = $true)]
        [string]
        $Destination,
        [parameter(Mandatory = $true)]
        [string]
        $Branch
    )
    @{
        Destination = $Destination
        Source = $Source
        Ensure = $Ensure
        Branch = $Branch
    }  
}

function Set-TargetResource
{
    param (
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,
        [parameter(Mandatory = $true)]
        [string]
        $Branch
    )
    try {
        Start-Service Browser
    }
    catch {
        Write-EventLog -LogName DevOps -Source RS_rsGit -EntryType Error -EventId 1002 -Message "Failed to Start Browser `n $_.Exception.Message"
    }
    if ($Ensure -eq "Present")
    {
        if(($Source.split("/.")[0]) -eq "https:") { $i = 5 } else { $i = 2 }
            if((test-path -Path (Join-Path $Destination -ChildPath ($Source.split("/."))[$i]) -PathType Container) -eq $false) {
                if((Test-Path -Path $Destination) -eq $false) { 
                    New-Item $Destination -ItemType Directory -Force 
                }
                chdir $Destination
                Write-Verbose "git clone $branch"
                Start -Wait "C:\Program Files (x86)\Git\bin\git.exe" -ArgumentList "clone $Source"
                Write-Verbose "git checkout $branch"
                Start -Wait "C:\Program Files (x86)\Git\bin\git.exe" -ArgumentList "checkout $Branch"
            }
        
        else {
            chdir (Join-Path $Destination -ChildPath ($Source.split("/."))[$i])
            Write-Verbose "git checkout $branch"
            Start "C:\Program Files (x86)\Git\bin\git.exe" -ArgumentList "checkout $Branch"
            Write-Verbose "git pull --rebase"
            Start -Wait "C:\Program Files (x86)\Git\bin\git.exe" -ArgumentList "pull --rebase"
            Write-Verbose "git reset --hard"
            Start -Wait "C:\Program Files (x86)\Git\bin\git.exe" -ArgumentList "reset --hard"
        }
    }
    if ($Ensure -eq "Absent")
    {
        if(($Source.split("/.")[0]) -eq "https:") { $i = 5 } else { $i = 2 }
        remove-item -Path (Join-Path $Destination -ChildPath ($Source.split("/."))[$i]) -Recurse -Force
    }
    try {
        Stop-Service Browser
    }
    catch {
        Write-EventLog -LogName DevOps -Source RS_rsGit -EntryType Error -EventId 1002 -Message "Failed to Stop Browser `n $_.Exception.Message"
    }
   } 

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter(Mandatory = $true)]
        [string]
        $Source,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,
        [parameter(Mandatory = $true)]
        [string]
        $Branch
    )
    if ($Ensure -eq "Present")
    {
        return $false
    }
    else
    {
        return $false
    }
}
Export-ModuleMember -Function *-TargetResource