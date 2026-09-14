from fastapi import FastAPI
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import os

app = FastAPI()

token_provider = get_bearer_token_provider(
    DefaultAzureCredential(
        managed_identity_client_id=os.getenv("AZURE_CLIENT_ID")
    ),
    "https://ai.azure.com/.default"
)

client = OpenAI(
    base_url="https://aiopscognitiveacct-subdomain.services.ai.azure.com/openai/v1",
    api_key=token_provider
)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/analyze")
def analyze():
    response = client.responses.create(
        model="gpt-5.4-mini",
        input="Analyze this log: ERROR database connection timeout after 30 seconds."
    )

    return {"analysis": response.output_text}