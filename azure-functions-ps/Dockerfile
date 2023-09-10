# Use the official Azure Functions runtime base image for PowerShell
FROM mcr.microsoft.com/azure-functions/powershell:3.0

# Set environment variables if needed
# ENV MY_ENV_VARIABLE=value

# Copy the Azure Function code into the container
COPY . /home/site/wwwroot

# Set the Azure Functions entry point
CMD ["azure-functions", "start"]