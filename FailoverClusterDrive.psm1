using namespace Microsoft.PowerShell.SHiPS

#Load support functions
. "$PSScriptRoot\FailoverClusterDrive.helper.ps1"

#FCRoot
#This is where the drive initializes
[SHiPSProvider()]
class FCRoot : SHiPSDirectory
{
    # static member to keep track of connected clusters
    static [System.Collections.Generic.List``1[Microsoft.FailoverClusters.PowerShell.Cluster]] $availableClusters
    
    # Default constructor
    FCRoot([string]$name):base($name)
    {
        
    }

    [object[]] GetChildItem()
    {
        $obj = @()

        if([FCRoot]::availableClusters)
        {
            [FCRoot]::availableClusters | ForEach-Object {
                $obj += [FCluster]::new($_.Name, $_)
            }
        }
        else
        {
            try
            {
                $clusterName = (Get-Cluster).Name
                $obj += [FCluster]::new($clusterName)
            }
            catch
            {
                Write-Warning -Message 'No local cluster found. Use Connect-Cluster to attach a cluster.'
            }
        }
        return $obj
    }
}

#FCluster
#This the top-level cluster container object
[SHiPSProvider()]
class FCluster : SHiPSDirectory
{
    [Microsoft.FailoverClusters.PowerShell.Cluster]$availableCluster = $null

    FCluster([string]$name):base($name)
    {
        $this.availableCluster = Get-Cluster -Name $name

        [FCRoot]::availableClusters += $this.availableCluster
    }

    FCluster([string]$name, [Microsoft.FailoverClusters.PowerShell.Cluster]$availableCluster):base($name)
    {
        $this.availableCluster = $availableCluster
    }

    [object[]] GetChildItem()
    {
        $obj = @()

        $obj += [Roles]::new('Roles', $this.name)
        $obj += [Nodes]::new('Nodes', $this.name)
        $obj += [Networks]::new('Networks', $this.name)
        return $obj
    }
}

#Roles
#Roles in a cluster as a container
[SHiPSProvider()]
class Roles : SHiPSDirectory
{
    [String] $ClusterName

    Roles([string]$name, [string]$clusterName):base($name)
    {
        $this.ClusterName = $clusterName
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        
        $roles = (Get-ClusterResource -Cluster $this.ClusterName).Name | Sort-Object
        foreach ($role in $roles) {
            $obj += [Role]::new($role, $this.ClusterName)
        }
        return $obj
    }
}

#Role
#Each role in the cluster as an object
[SHiPSProvider()]
class Role : SHiPSDirectory
{
    [String] $ClusterName

    Role([string]$name, [string] $ClusterName):base($name)
    {
        $this.ClusterName = $ClusterName
    }
     
    [object[]] GetChildItem()
    {
        try
        {
            return Get-ClusterResource -Cluster $this.ClusterName -Name $this.name -ErrorAction Stop
        }

        catch
        {
            throw $_
        } 
    }    
}

#Nodes
#Nodes in a cluster as a container
[SHiPSProvider()]
class Nodes : SHiPSDirectory
{
    [String] $ClusterName

    Nodes([string]$name, [string]$clusterName):base($name)
    {
        $this.clusterName = $clusterName
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        
        # Find all Cluster nodes
        $nodes = (Get-ClusterNode -Cluster $this.ClusterName).Name | Sort-Object
        foreach ($node in $nodes) {
            $obj += [Node]::new($node, $this.ClusterName)
        }
        return $obj
    }
}

#Node
#Each node object in a cluster
[SHiPSProvider()]
class Node : SHiPSDirectory
{
    [String] $ClusterName

    Node([string]$name, [string] $ClusterName):base($name)
    {
        $this.ClusterName = $ClusterName
    }
     
    [object[]] GetChildItem()
    {
        try
        {
            return Get-ClusterNode -Cluster $this.ClusterName -Name $this.name -ErrorAction Stop
        }

        catch
        {
            throw $_
        } 
    }    
}

#Networks
#Networks in a cluster as a container
[SHiPSProvider()]
class Networks : SHiPSDirectory
{
    [String] $ClusterName

    Networks([string]$name, [string]$clusterName):base($name)
    {
        $this.clustername = $clusterName
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        
        # Find all Cluster nodes
        $networks = (Get-ClusterNetwork -Cluster $this.clusterName).Name | Sort-Object
        foreach ($network in $networks) {
            $obj += [Network]::new($network, $this.ClusterName)
        }
        return $obj
    }
}

#Network
#Each Network in the cluster as an object
[SHiPSProvider()]
class Network : SHiPSDirectory
{
    [String] $ClusterName

    Network([string]$name, [string] $ClusterName):base($name)
    {
        $this.ClusterName = $ClusterName
    }
     
    [object[]] GetChildItem()
    {
        try
        {
            return Get-ClusterNetwork -Cluster $this.ClusterName -Name $this.name -ErrorAction Stop
        }

        catch
        {
            throw $_
        } 
    }    
}

Export-ModuleMember -Function *