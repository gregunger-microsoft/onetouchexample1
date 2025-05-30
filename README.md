# Simple Chat One-Touch Deployer to Azure

This project provides a one-click deployment for Simple Chat to Azure Commercial.

## SimpleChat

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgregunger-microsoft%2Fonetouchexample1%2Frefs%2Fheads%2Fmain%2Fmain.json)

[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgregunger-microsoft%2Fonetouchexample1%2Frefs%2Fheads%2Fmain%2Fmain.json)

## App Service

[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgregunger-microsoft%2Fonetouchexample1%2Frefs%2Fheads%2Fmain%2FAppServiceConfig.json)

## How to Use

1. Click the "Deploy to Azure" button above to deploy.
2. You will be redirected to the Azure portal.
3. Provide a argument names for the given parameters.
4. Review the settings and click "Create" to deploy.

az bicep build --file AppServiceConfig.bicep
