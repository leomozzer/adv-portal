import { AzureFunction, Context } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { ResourceManagementClient } from "@azure/arm-resources";

const credentials = new DefaultAzureCredential();

const queueTrigger: AzureFunction = async function (context: Context, myQueueItem: string): Promise<void> {
    context.log('Queue trigger function processed work item', myQueueItem);
    //context.log(typeof myQueueItem)
    try {
        const resourceClient = new ResourceManagementClient(credentials, myQueueItem['subscriptionId']);
        const resourceGroupParameters = {
            location: myQueueItem['location'],
        };
        await resourceClient.resourceGroups.createOrUpdate(myQueueItem['resourceGroupName'], resourceGroupParameters);
    } catch (error) {
        context.log("Error adding message to the queue:", error.message);
    }
};

export default queueTrigger;
