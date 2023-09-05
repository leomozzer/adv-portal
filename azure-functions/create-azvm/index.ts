import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { DefaultAzureCredential } from "@azure/identity";
import { ResourceManagementClient } from "@azure/arm-resources";
import { ComputeManagementClient } from '@azure/arm-compute';
import { NetworkManagementClient } from "@azure/arm-network";

const subscriptionId = "";
const resourceGroupName = "rg-node-test";
const location = "East US"; // Change to your desired location
const virtualNetworkResourceGroup = "rg-eus-dc-01"
const virtualNetworkName = "vnet-eus-dc-01";
const subnetName = "snet-dc-01";
const vmName = 'vm-test-02';
const nicName = `nic-${vmName}`

// Authenticate using Managed Identity
const credentials = new DefaultAzureCredential();

// Create a Resource Management Client
const resourceClient = new ResourceManagementClient(credentials, subscriptionId);
const networkClient = new NetworkManagementClient(credentials, subscriptionId);
const computeClient = new ComputeManagementClient(credentials, subscriptionId);

// Define the resource group parameters
const resourceGroupParameters = {
    location: location,
};

const nicParameters = {
    location: location,
    ipConfigurations: [
        {
            name: "ipconfig1",
            subnet: {
                id: `/subscriptions/${subscriptionId}/resourceGroups/${virtualNetworkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}`,
            },
        },
    ],
};

const CreateAzureVm: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');
    const resourceGroup = await resourceClient.resourceGroups.createOrUpdate(resourceGroupName, resourceGroupParameters);
    const nic = await networkClient.networkInterfaces.beginCreateOrUpdate(resourceGroupName, nicName, nicParameters);
    const getNic = await networkClient.networkInterfaces.get(resourceGroupName, nicName)
    console.log(getNic.id)
    const vmConfig = {
        location: location,
        osProfile: {
            computerName: vmName,
            adminUsername: '',
            adminPassword: '',
        },
        hardwareProfile: {
            vmSize: 'Standard_B2ms', // Choose an appropriate VM size
        },
        storageProfile: {
            imageReference: {
                publisher: 'MicrosoftWindowsDesktop',
                offer: 'Windows-10',
                sku: '20h2-evd', // Windows Server version
                version: 'latest',
            },
            osDisk: {
                createOption: 'FromImage',
                name: `${vmName}_osdisk`,
            },
        },
        networkProfile: {
            networkInterfaces: [
                {
                    id: getNic.id, // You'll need to create a network interface separately
                },
            ],
        },
        osType: 'Windows',
    };
    const vm = await computeClient.virtualMachines.beginCreateOrUpdateAndWait(resourceGroupName, vmName, vmConfig);

    // console.log(`Resource group "${result.name}" created.`);
    context.res = {
        // status: 200, /* Defaults to 200 */
        body: 'result'
    };

};

export default CreateAzureVm;