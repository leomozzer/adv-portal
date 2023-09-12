function CheckLocationShort {
    param (
        [object]$body
    )
    if (($body.location -split " ").Count -eq 2) {
        $locationShort = ($body.location -split " ")[0][0] + ($body.location -split " ")[1].Substring(0, 2)
    }
    else {
        $locationShort = $body.location.Substring(0, 3)
    }
    return $locationShort.ToLower()
}

function CreateResourceGroupName {
    param (
        [object]$body
    )
    if ($body.resourceGroupName) {
        return $body.resourceGroupName
    }
    else {
        $locationShort = CheckLocationShort -body $body
        return "rg-$($locationShort.ToLower())-$($body.appName)"
    }
}

function CreateQueueOrder {
    param (
        [object]$body
    )
    Write-Host $body
    $queueOrder = @()
    switch ($body.actionType) {
        "CreateAzVm" {
            $rgName = CreateResourceGroupName -body $body
            if (!(Get-AzResourceGroup -Name $rgName)) {
                Write-Host "rg new"
                $queueOrder.Add("create-rg")
            }
            return $queueOrder
        }
    }
}

$jsonData = '{
    "subscriptionId": "955daeae-7823-41f8-a648-a19777bcb4ef",
    "location": "East US",
    "virtualNetworkResourceGroup": "rg-eus-dc-01",
    "virtualNetworkName": "vnet-eus-dc-01",
    "subnetName": "snet-dc-01",
    "appName": "vm-test-10",
    "actionType": "CreateAzVm",
    "resourceGroupName": "rg-eus-avd-01"
}'

# Convert the JSON data to a PowerShell variable
$myVariable = $jsonData | ConvertFrom-Json

function CreateMessage {
    param (
        [object]$body
    )
    $message = @{}
    switch ($body.actionType) {
        "CreateAzVm" { 
            $message = @{
                "vmName"                      = $body.appName
                "location"                    = $body.location
                "locationShort"               = CheckLocationShort -body $body
                "resourceGroupName"           = CreateResourceGroupName -body $body
                "virtualNetworkResourceGroup" = $body.virtualNetworkResourceGroup
                "virtualNetworkName"          = $body.virtualNetworkName
                "subnetName"                  = $body.subnetName
                "nicName"                     = "nic-$($body.appName)"
                "queueOrder"                  = @("create-nic", "create-azvm", "join-domain")
                "ordersCompleted"             = @()
                "actionType"                  = $body.actionType
            }
            return $message
        }
        Default {
            return $null
        }
    }
    
    #Write-Output $message
}

CreateMessage -body $myVariable
#CreateQueueOrder -body $myVariable
