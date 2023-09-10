import { AzureFunction, Context } from "@azure/functions"
import { DefaultAzureCredential } from "@azure/identity";
import { NetworkManagementClient } from "@azure/arm-network";
import { ComputeManagementClient } from '@azure/arm-compute';
import { QueueServiceClient } from "@azure/storage-queue";

const credentials = new DefaultAzureCredential();
const connectionString = process.env.AzureWebJobsStorage; // Replace with your Azure Storage connection string
const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);

const QueueCreateAzVm: AzureFunction = async function (context: Context, myQueueItem: string): Promise<void> {
    context.log('Queue trigger function processed work item', myQueueItem);
    try {
        const computeClient = new ComputeManagementClient(credentials, myQueueItem['subscriptionId']);
        const networkClient = new NetworkManagementClient(credentials, myQueueItem['subscriptionId']);

        const getNic = await networkClient.networkInterfaces.get(myQueueItem['resourceGroupName'], myQueueItem['nicName'])
        const vmConfig = {
            location: myQueueItem['location'],
            osProfile: {
                computerName: myQueueItem['vmName'],
                adminUsername: 'ls0-admin',
                adminPassword: 'Passw@rd1',
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
                    name: `${myQueueItem['vmName']}_osdisk`,
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
        await computeClient.virtualMachines.beginCreateOrUpdateAndWait(myQueueItem['resourceGroupName'], myQueueItem['vmName'], vmConfig);
        const message = myQueueItem
        const removedOrder = message['queueOrder'].shift();
        message['ordersCompleted'].push(removedOrder)
        context.log(message)
        const queueClient = queueServiceClient.getQueueClient(message['queueOrder'][0]);
        await queueClient.sendMessage(btoa(JSON.stringify(message)));
    } catch (error) {
        context.log(error.message)
        context.log(`Error when creating vm ${myQueueItem['vmName']}`);
    }
};

export default QueueCreateAzVm;
