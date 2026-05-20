# test_security_controls.py
import requests

TARGET_HOST = "http://localhost:8000" # Update to live exposed cluster endpoint IP during execution pipelines

def test_automated_security_baseline():
    print("Executing Security Controls Validation Assessment...")

    # 1. Verify Authentication & Token Issuance
    print("\n[Test 1] Testing JWT Authentication Flow...")
    auth_payload = {"username": "simar@securebank.com", "password": "securepassword"}
    res = requests.post(f"{TARGET_HOST}/api/v1/auth/token", data=auth_payload)
    assert res.status_code == 200, "Authentication sequence broken."
    token = res.json()["access_token"]
    print("Success: Token successfully generated.")

    # 2. Verify Data Validation and Input Whitelisting Bounds
    print("\n[Test 2] Testing Input Whitelisting Bounds (Payload Injection Protection)...")
    malicious_payload = {"recipient_account": "INVALID_CHARSETS_SQL_INJECT", "amount": 50.0}
    hdr = {"Authorization": f"Bearer {token}"}
    res_malicious = requests.post(f"{TARGET_HOST}/api/v1/transactions/transfer", json=malicious_payload, headers=hdr)
    assert res_malicious.status_code == 422, "Input validation flaw: Application vulnerable to parameter poisoning."
    print("Success: Application securely blocked invalid payloads (422 Unprocessable Entity).")

    # 3. Verify Fine-Grained Authorization Scopes (RBAC Verification)
    print("\n[Test 3] Testing Least Privilege Scopes Isolation Architecture...")
    res_audit = requests.get(f"{TARGET_HOST}/api/v1/audit/logs", headers=hdr)
    assert res_audit.status_code == 403, "Privilege Escalation bug: Customer bypassed scope limitations."
    print("Success: Core securely denied execution access to unauthorized endpoints (403 Forbidden).")
    
    print("\n*** ALL BASES SECURE: PASS ***")

if __name__ == "__main__":
    test_automated_security_baseline()