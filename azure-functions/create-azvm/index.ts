import { AzureFunction, Context, HttpRequest } from "@azure/functions"
const { DefaultAzureCredential } = require("@azure/identity");
const { ResourceManagementClient } = require("@azure/arm-resources");

const subscriptionId = "";
const resourceGroupName = "rg-node-test";
const location = "East US"; // Change to your desired location

// Authenticate using Managed Identity
const credentials = new DefaultAzureCredential();

// Create a Resource Management Client
const resourceClient = new ResourceManagementClient(credentials, subscriptionId);

// Define the resource group parameters
const resourceGroupParameters = {
    location: location,
};

const CreateAzureVm: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');
    const result = await resourceClient.resourceGroups.createOrUpdate(resourceGroupName, resourceGroupParameters);
    console.log(`Resource group "${result.name}" created.`);
    context.res = {
        // status: 200, /* Defaults to 200 */
        body: result
    };

};

export default CreateAzureVm;