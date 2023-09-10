import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { QueueServiceClient } from "@azure/storage-queue";

const connectionString = process.env.AzureWebJobsStorage; // Replace with your Azure Storage connection string

//const credential = new DefaultAzureCredential();
const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);

const Dispatcher: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');
    const name = (req.query.name || (req.body && req.body.name));
    const requestBody = req.body;
    const { subscriptionId, location, vmName, virtualNetworkName, virtualNetworkResourceGroup, subnetName, actionType } = requestBody
    console.log(requestBody)
    try {
        // Create a new message
        const locationShort = location.split(" ").length === 2 ? `${location.split(" ")[0][0]}${location.split(" ")[1].substr(0, 2)}` : location.substr(0, 3)
        switch (actionType) {
            case "CreateVm":
                const message = {
                    "subscriptionId": subscriptionId,
                    "resourceGroupName": `rg-${locationShort.toLowerCase()}-${vmName}`,
                    "location": location,
                    "virtualNetworkResourceGroup": virtualNetworkResourceGroup,
                    "virtualNetworkName": virtualNetworkName,
                    "subnetName": subnetName,
                    "vmName": vmName,
                    "nicName": `nic-${vmName}`,
                    "queueOrder": ["create-rg", "create-nic", "create-azvm", "join-domain"],
                    "ordersCompleted": []
                }
                let queueClient = queueServiceClient.getQueueClient(message['queueOrder'][0]);
                await queueClient.sendMessage(btoa(JSON.stringify(message)));

                console.log(`Message "${message}" added to the queue "${message['queueOrder'][0]}"`);
                context.res = {
                    // status: 200, /* Defaults to 200 */
                    body: `Message "${message}" added to the queue "${message['queueOrder'][0]}"`
                };
                break;
            case "DomainJoin":
                const domainMessage = {
                    "subscriptionId": subscriptionId,
                    "resourceGroupName": `rg-${locationShort.toLowerCase()}-${vmName}`,
                    "location": location,
                    "virtualNetworkResourceGroup": virtualNetworkResourceGroup,
                    "virtualNetworkName": virtualNetworkName,
                    "subnetName": subnetName,
                    "vmName": vmName,
                    "nicName": `nic-${vmName}`,
                    "queueOrder": ["join-domain"],
                    "ordersCompleted": []
                }
                let domainQueueClient = queueServiceClient.getQueueClient(domainMessage['queueOrder'][0]);
                await domainQueueClient.sendMessage(btoa(JSON.stringify(domainMessage)));

                console.log(`Message "${domainMessage}" added to the queue "${domainMessage['queueOrder'][0]}"`);
                context.res = {
                    // status: 200, /* Defaults to 200 */
                    body: `Message "${domainMessage}" added to the queue "${domainMessage['queueOrder'][0]}"`
                };
                break;
            default:
                context.res = {
                    // status: 200, /* Defaults to 200 */
                    body: `Nothing to perform`
                };
                break;
        }

    } catch (error) {
        console.error("Error adding message to the queue:", error.message);
        context.res = {
            // status: 200, /* Defaults to 200 */
            body: `"Error adding message to the queue:", ${error.message}"`
        };
    }


};

export default Dispatcher;