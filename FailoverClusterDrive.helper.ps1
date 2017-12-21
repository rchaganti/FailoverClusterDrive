#Supporting functions
function Connect-Cluster
{
    param(
        [Parameter(Mandatory)]
        [string] $ClusterName
    )
    
    $null = [FCluster]::New($ClusterName)
}

