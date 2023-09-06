import { AzureFunction, Context } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { NetworkManagementClient } from "@azure/arm-network";
import { QueueServiceClient } from "@azure/storage-queue";

const credentials = new DefaultAzureCredential();
const connectionString = ""; // Replace with your Azure Storage connection string
const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);

const CreateNic: AzureFunction = async function (context: Context, myQueueItem: string): Promise<void> {
    context.log('Queue trigger function processed work item', myQueueItem);
    try {
        const networkClient = new NetworkManagementClient(credentials, myQueueItem['subscriptionId']);
        const nicParameters = {
            location: myQueueItem['location'],
            ipConfigurations: [
                {
                    name: "ipconfig1",
                    subnet: {
                        id: `/subscriptions/${myQueueItem['subscriptionId']}/resourceGroups/${myQueueItem['virtualNetworkResourceGroup']}/providers/Microsoft.Network/virtualNetworks/${myQueueItem['virtualNetworkName']}/subnets/${myQueueItem['subnetName']}`,
                    },
                },
            ],
        };
        await networkClient.networkInterfaces.beginCreateOrUpdate(myQueueItem['resourceGroupName'], myQueueItem['nicName'], nicParameters);
        const message = myQueueItem
        const removedOrder = message['queueOrder'].shift();
        message['ordersCompleted'].push(removedOrder)
        context.log(message)
        const queueClient = queueServiceClient.getQueueClient(message['queueOrder'][0]);
        await queueClient.sendMessage(btoa(JSON.stringify(message)));
    } catch (error) {
        context.log(error.message)
        context.log(`Error when creating nic ${myQueueItem['nicName']}`);
    }
};

export default CreateNic;
