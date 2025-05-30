# ReadMe.md

pip freeze > requirements.txt
pip install -r requirements.txt

## .env file

Create a .env file to put environment variables in.

### .env file format

AZURE_PLATFORM=azure # azure or azuregov
AZURE_TENANT_ID=[YOUR TENANT ID]
AZURE_CLIENT_ID=[YOUR CLIENT ID]
AZURE_CLIENT_SECRET=[YOUR SECRET]
API_SCOPE=api://37d7a13d-a5b5-48a6-972f-428cbf316bd9/.default (Example only)
API_BASE_URL=<https://web-8000.azurewebsites.us> (Example only)
UPLOAD_DIRECTORY=./test-documents (Example only)
