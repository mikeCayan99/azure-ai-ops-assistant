from collections import defaultdict, deque
from time import monotonic
from fastapi import FastAPI, HTTPException, Request
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import os
from pydantic import BaseModel, Field

app = FastAPI()

RATE_LIMIT = 5
RATE_WINDOW_SECONDS = 60
request_history = defaultdict(deque)

class AnalyzeRequest(BaseModel):
    log: str = Field(min_length=1, max_length=4000)

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
def analyze(payload: AnalyzeRequest, request: Request):
    client_ip = request.client.host
    now = monotonic()

    timestamps = request_history[client_ip]

    while timestamps and now - timestamps[0] > RATE_WINDOW_SECONDS:
        timestamps.popleft()

    if len(timestamps) >= RATE_LIMIT:
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Try again later."
        )

    timestamps.append(now)

    response = client.responses.create(
        model="gpt-5.4-mini",
        input=f"Analyze this log: {payload.log}",
        max_output_tokens=300
    )

    return {"analysis": response.output_text}
