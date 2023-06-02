# Chaos-Samples

Samples & templates for using Azure Chaos Studio effectively ⚡

## Bicep
### VM Shutdown
This template assumes you have an existing resource group that includes a virtual machine.

To deploy the VM Shutdown Bicep template, open the Azure CLI, then run:
```
az deployment group create --resource-group exampleRG --template-file main.bicep
```

You'll be prompted to enter the following values:
* **targetName**: this is the name of an existing Virtual Machine within your resource group
* **experimentName**: the desired name for your Chaos Experiment
* **location**: the desired region for the experiment, targets, and capabilities

The template should deploy within a few minutes.

Once the deployment is complete, navigate to Chaos Studio in the Azure portal, select **Experiments**, and find the experiment created by the template. Select it, then **Start** the experiment.
