import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { QueueServiceClient, QueueClient } from "@azure/storage-queue";

const connectionString = ""; // Replace with your Azure Storage connection string
const queueName = "testing-queue";

//const credential = new DefaultAzureCredential();
const queueServiceClient = QueueServiceClient.fromConnectionString(connectionString);

// const queueClient = queueServiceClient.getQueueClient(queueName);

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
                const message = JSON.stringify({
                    "subscriptionId": subscriptionId,
                    "resourceGroupName": `rg-${locationShort.toLowerCase()}-${vmName}`,
                    "location": location,
                    "virtualNetworkResourceGroup": virtualNetworkResourceGroup,
                    "virtualNetworkName": virtualNetworkName,
                    "subnetName": subnetName,
                    "vmName": vmName,
                    "nicName": `nic-${vmName}`
                })
                const queueClient = queueServiceClient.getQueueClient('create-rg');
                await queueClient.sendMessage(btoa(message));

                console.log(`Message "${message}" added to the queue "${queueName}"`);
                context.res = {
                    // status: 200, /* Defaults to 200 */
                    body: `Message "${message}" added to the queue "${queueName}"`
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