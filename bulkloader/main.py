# https://github.com/microsoft/simplechat/commit/a306adfc7d223b031855007db758a543e7b5552b
# POST https://web-8000.azurewebsites.us/api/group_bulk_documents/upload ^
#         -F "file=@Downloads/nospaces-VA.pdf" ^
#         -F "userId=e81deb4e-839d-40e2-b0fc-020a90ec5f60" ^
#         -F "activeGroupOid=496bd544-817a-4eb2-85da-576a0146b106"

import os
import requests
from msal import ConfidentialClientApplication
#import json
import logging

# --- Configuration ---
# Replace with your Azure App Service and Microsoft Entra ID details
TENANT_ID = "6bc5b33e-bc05-493c-b076-8f8ce1331515"  # Directory (tenant) ID
CLIENT_ID = "37d7a13d-a5b5-48a6-972f-428cbf316bd9"  # Application (client) ID for your client app
CLIENT_SECRET = ""  # Client secret for your client app (use certificates in production)
API_SCOPE = "api://37d7a13d-a5b5-48a6-972f-428cbf316bd9/.default" # Or a specific scope defined for your API, e.g., "api://<your-api-client-id>/.default" for application permissions
API_ENDPOINT_URL = "https://web-8000.azurewebsites.us/api/group_bulk_documents/upload" # Your custom API endpoint for document upload
UPLOAD_DIRECTORY = "./test-documents"  # Local directory containing files to upload
USER_ID = "e81deb4e-839d-40e2-b0fc-020a90ec5f60"  # User ID for the upload
ACTIVE_GROUP_OID = "496bd544-817a-4eb2-85da-576a0146b106"  # Active group OID for the upload

# Configure logging for better debugging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def get_access_token():
    """
    Acquires an access token from Microsoft Entra ID using the client credentials flow.
    """
    authority = f"https://login.microsoftonline.us/{TENANT_ID}"
    app = ConfidentialClientApplication(
        client_id=CLIENT_ID,
        client_credential=CLIENT_SECRET,
        authority=authority
    )

    try:
        # Acquire a token silently from cache if available
        result = app.acquire_token_silent(scopes=[API_SCOPE], account=None)
        if not result:
            # If no token in cache, acquire a new one using client credentials flow
            logger.info("No token in cache, acquiring new token using client credentials flow.")
            result = app.acquire_token_for_client(scopes=[API_SCOPE])

        if "access_token" in result:
            logger.info("Successfully acquired access token.")
            return result["access_token"]
        else:
            logger.error(f"Error acquiring token: {result.get('error')}")
            logger.error(f"Description: {result.get('error_description')}")
            logger.error(f"Correlation ID: {result.get('correlation_id')}")
            return None
    except Exception as e:
        logger.error(f"An unexpected error occurred during token acquisition: {e}")
        return None

def upload_document(file_path, access_token):
    """
    Uploads a single document to the custom API.

    Args:
        file_path (str): The full path to the file to upload.
        access_token (str): The Microsoft Entra ID access token.

    Returns:
        bool: True if the upload was successful, False otherwise.
    """
    file_name = os.path.basename(file_path)
    headers = {
        "Authorization": f"Bearer {access_token}"
    }
    data = {
        'userId': USER_ID,
        'activeGroupOid': ACTIVE_GROUP_OID
    }

    try:
        with open(file_path, 'rb') as f:
            files = {'file': (file_name, f)}
            logger.info(f"Attempting to upload: {file_name}")
            response = requests.post(API_ENDPOINT_URL, headers=headers, files=files, data=data, timeout=60) # Added timeout

            response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)

            logger.info(f"Successfully uploaded {file_name}. Status Code: {response.status_code}")
            logger.debug(f"Response: {response.text}")
            return True

    except requests.exceptions.HTTPError as e:
        logger.error(f"HTTP error occurred for {file_name}: {e}")
        logger.error(f"Response content: {e.response.text}")
        return False
    except requests.exceptions.ConnectionError as e:
        logger.error(f"Connection error occurred for {file_name}: {e}")
        return False
    except requests.exceptions.Timeout as e:
        logger.error(f"Request timed out for {file_name}: {e}")
        return False
    except requests.exceptions.RequestException as e:
        logger.error(f"An error occurred during the request for {file_name}: {e}")
        return False
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")
        return False
    except Exception as e:
        logger.error(f"An unexpected error occurred while processing {file_name}: {e}")
        return False

def main():
    """
    Main function to iterate through files and upload them.
    """
    if not os.path.isdir(UPLOAD_DIRECTORY):
        logger.error(f"Error: Directory '{UPLOAD_DIRECTORY}' not found.")
        return

    access_token = get_access_token()
    if not access_token:
        logger.critical("Failed to obtain access token. Aborting document upload.")
        return

    uploaded_count = 0
    failed_uploads = []

    for filename in os.listdir(UPLOAD_DIRECTORY):
        file_path = os.path.join(UPLOAD_DIRECTORY, filename)

        # Skip directories
        if os.path.isdir(file_path):
            continue

        # Optional: Filter by file extension if needed
        if not filename.lower().endswith(('.pdf', '.docx', '.txt')):
            logger.info(f"Skipping {filename}: Not a supported file type.")
            continue

        if upload_document(file_path, access_token):
            uploaded_count += 1
        else:
            failed_uploads.append(filename)

    logger.info("-" * 30)
    logger.info("Upload process completed.")

    #logger.info(f"Total files attempted: {len(os.listdir(UPLOAD_DIRECTORY) excluding subdirectories)}") # Adjusted for clarity
    
    logger.info(f"Successfully uploaded: {uploaded_count}")
    if failed_uploads:
        logger.warning(f"Failed uploads: {len(failed_uploads)} files: {', '.join(failed_uploads)}")
    else:
        logger.info("All files uploaded successfully!")

if __name__ == "__main__":
    main()