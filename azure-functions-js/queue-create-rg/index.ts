import { AzureFunction, Context } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { ResourceManagementClient } from "@azure/arm-resources";
import { QueueServiceClient } from "@azure/storage-queue";

const connectionString = process.env.AzureWebJobsStorage; // Replace with your Azure Storage connection string
const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);

const credentials = new DefaultAzureCredential();

const CreateResourceGroup: AzureFunction = async function (context: Context, myQueueItem: string): Promise<void> {
    context.log('Queue trigger function processed work item', myQueueItem);
    //context.log(typeof myQueueItem)
    try {
        const resourceClient = new ResourceManagementClient(credentials, myQueueItem['subscriptionId']);
        const resourceGroupParameters = {
            location: myQueueItem['location'],
        };
        await resourceClient.resourceGroups.createOrUpdate(myQueueItem['resourceGroupName'], resourceGroupParameters);
        const message = myQueueItem
        const removedOrder = message['queueOrder'].shift();
        message['ordersCompleted'].push(removedOrder)
        context.log(message)
        const queueClient = queueServiceClient.getQueueClient(message['queueOrder'][0]);
        await queueClient.sendMessage(btoa(JSON.stringify(message)));
    } catch (error) {
        context.log(error.message)
        context.log(`Error when creating resource group ${myQueueItem['resourceGroupName']}`);
    }
};

export default CreateResourceGroup;
