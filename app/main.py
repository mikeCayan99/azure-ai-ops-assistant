from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/analyze")
def analyze():
    return {"message": "Analysis endpoint is ready"}
    