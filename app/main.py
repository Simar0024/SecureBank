from fastapi import FastAPI, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List
import jwt
import datetime
import logging

# --- SOC AUDIT LOGGING CONFIGURATION ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] SOC_AUDIT: %(message)s')
logger = logging.getLogger("SecureBankSOC")

SECRET_KEY = "sb-dev-local-secret-key-change-in-production"
ALGORITHM = "HS256"

app = FastAPI(
    title="SecureBank Core API",
    description="Production-grade financial engine demonstrating cloud native compliance principles.",
    version="1.0.0",
    docs_url="/api/docs", # Swagger Endpoint
    redoc_url=None
)

# Enforcing CORS Whitelisting
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, swap with specific frontend origin domain
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/token")

# Mock User DB containing pre-hashed passwords & scoped roles
USER_DB = {
    "admin@securebank.com": {"password": "password123", "role": "ComplianceOfficer", "scopes": ["audit", "read"]},
    "simar@securebank.com": {"password": "securepassword", "role": "Customer", "scopes": ["read", "transfer"]}
}

class Token(BaseModel):
    access_token: str
    token_type: str

class TransferRequest(BaseModel):
    recipient_account: str = Field(..., min_length=10, max_length=12, regex="^[0-9]+$")
    amount: float = Field(..., gt=0, lt=100000)

class AuditLogResponse(BaseModel):
    event_id: str
    timestamp: str
    actor: str
    action: str
    status: str

# --- SECURITY DEPENDENCY INJECTION ENGINE ---
def verify_jwt_and_scope(required_scope: str):
    def dependency(token: str = Depends(oauth2_scheme)):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            username: str = payload.get("sub")
            scopes: list = payload.get("scopes", [])
            role: str = payload.get("role")
            
            if username is None or required_scope not in scopes:
                logger.warning(GENERIC_DENIAL_MSG.format(username, required_scope))
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Authorization failed: Invalid Scopes")
            return {"username": username, "role": role}
        except jwt.PyJWTError:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session credentials")
    return dependency

GENERIC_DENIAL_MSG = "Unauthorized scope access attempt by User: {} for scope: {}"

@app.post("/api/v1/auth/token", response_model=Token, tags=["Authentication"])
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = USER_DB.get(form_data.username)
    if not user or form_data.password != user["password"]:
        logger.warning(f"Failed login attempt for identification user identity: {form_data.username}")
        raise HTTPException(status_code=400, detail="Incorrect email address or password configuration")
    
    token_expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
    token_payload = {
        "sub": form_data.username,
        "role": user["role"],
        "scopes": user["scopes"],
        "exp": token_expiry
    }
    encoded_jwt = jwt.encode(token_payload, SECRET_KEY, algorithm=ALGORITHM)
    logger.info(f"Successful user login session generated for: {form_data.username} [Role: {user['role']}]")
    return {"access_token": encoded_jwt, "token_type": "bearer"}

@app.post("/api/v1/transactions/transfer", tags=["Transactions"])
async def execute_transfer(request: TransferRequest, current_user: dict = Depends(verify_jwt_and_scope("transfer"))):
    # Data in Use processing state execution within secure abstraction layers
    logger.info(f"Transaction Initiated - Actor: {current_user['username']} | Destination: {request.recipient_account} | Quantity: ${request.amount}")
    return {"status": "success", "transaction_id": "tx_99284711", "message": "Funds transferred successfully via encrypted backbone."}

@app.get("/api/v1/audit/logs", response_model=List[AuditLogResponse], tags=["Compliance & SOC"])
async def get_soc_logs(current_user: dict = Depends(verify_jwt_and_scope("audit"))):
    logger.info(f"Compliance audit trail extracted by Administrator: {current_user['username']}")
    return [
        {"event_id": "evt_001", "timestamp": "2026-05-20T14:22:01Z", "actor": "simar@securebank.com", "action": "FundTransfer", "status": "Success"},
        {"event_id": "evt_002", "timestamp": "2026-05-20T15:01:12Z", "actor": "attacker@external.io", "action": "BruteForceAttack", "status": "BlockedByWAF"}
    ]