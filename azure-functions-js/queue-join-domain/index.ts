import { AzureFunction, Context } from "@azure/functions"
import { DefaultAzureCredential } from "@azure/identity";
import { ComputeManagementClient, VirtualMachineExtension } from '@azure/arm-compute';
import { AutomationClient } from "@azure/arm-automation";
import axios from 'axios'

const credentials = new DefaultAzureCredential();

const domainName = "lsolab.com";
const domainUser = "";
const domainPassword = "";

const storageAccountName = "staeusavd01";
const storageContainerName = "scripts";
const scriptFileName = "domainjoin.ps1"; // Replace with your script file name
const scriptUri = `https://${storageAccountName}.blob.core.windows.net/${storageContainerName}/${scriptFileName}`;
const scriptCommand = `bash ${scriptFileName}`;

const JoinDomain: AzureFunction = async function (context: Context, myQueueItem: string): Promise<void> {
    context.log('Queue trigger function processed work item', myQueueItem);
    try {
        const computeClient = new ComputeManagementClient(credentials, myQueueItem['subscriptionId']);
        const ext: VirtualMachineExtension = {
            location: myQueueItem['location'],
            publisher: "Microsoft.Compute",
            typeHandlerVersion: "1.1",
            autoUpgradeMinorVersion: true,
            settings: {
                Name: "your-domain-name",
                OUPath: "OU=your-organizational-unit,DC=your-domain,DC=com",
                User: "your-username",
                Restart: "true",
                Options: "3",
                Retry: "3",
                RetryInterval: "5",
                JoinOption: "3"
            }
        }
        const domainJoinExtension = {
            location: myQueueItem['location'],
            autoUpgradeMinorVersion: true,
            publisher: "Microsoft.Azure.NetworkWatcher",
            typePropertiesType: "NetworkWatcherAgentWindows",
            typeHandlerVersion: "1.4",
        };

        // const automationClient = new AutomationClient(credentials, myQueueItem['subscriptionId'], 'status');
        // const props = {
        //     'name': 'JoinDomain.ps1',
        //     'uri': 
        // }
        // const jobResult = await automationClient.beginLongRunningRequest()
        // Define the custom script extension settings
        // const ext: VirtualMachineExtension = {
        //     location: myQueueItem['location'],
        //     publisher: "Microsoft.Compute",
        //     typeHandlerVersion: "1.1",
        //     autoUpgradeMinorVersion: true,
        //     settings: {
        //         script: `Write-output "something"`
        //     }
        // }
        // const customScriptExtension = {
        //     location: myQueueItem['location'],
        //     publisher: "Microsoft.Compute",
        //     typeHandlerVersion: "1.1",
        //     autoUpgradeMinorVersion: true,
        //     settings: {
        //         script: `
        //             $DomainName = "lsolab.com"
        //             $DomainUser = ${domainUser}
        //             $DomainPassword = ConvertTo-SecureString ${domainPassword}) -AsPlainText -Force
        //             $Credential = New-Object System.Management.Automation.PSCredential ($DomainUser, $DomainPassword)
        //             Add-Computer -DomainName ${domainName} -Credential $Credential -OUPath "OU=AVDInfra,DC=lsolab,DC=com" -Restart -Force
        //         `,
        //     }
        // };
        // await computeClient.virtualMachineExtensions.beginCreateOrUpdate(
        //     myQueueItem['resourceGroupName'],
        //     myQueueItem['vmName'],
        //     "joindomainextension",
        //     ext
        // );
        // const customScriptExtension = {
        //     location: myQueueItem['location'],
        //     publisher: "Microsoft.Azure.Extensions",
        //     type: "CustomScript",
        //     typeHandlerVersion: "2.1",
        //     settings: {
        //         scriptUri: [scriptUri],
        //     }
        // };
        // const vm = await computeClient.virtualMachines.get(myQueueItem['resourceGroupName'], myQueueItem['vmName']);
        await computeClient.virtualMachineExtensions.beginCreateOrUpdate(
            myQueueItem['resourceGroupName'],
            myQueueItem['vmName'],
            "CustomScriptExtension",
            domainJoinExtension
        );
        context.log(`VM '${myQueueItem['vmName']}' joined to domain '${domainName}' successfully.`);
    } catch (error) {
        context.log(error)
        context.log(error.message);
    }
};

export default JoinDomain;
