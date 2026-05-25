// public/js/portal-security.js
document.addEventListener("DOMContentLoaded", () => {
    let sessionToken = "";
    let csrfToken = "";
    const API_BASE = "http://localhost:8000/api/v1";

    function generateSecureRandomString(length = 32) {
        const array = new Uint8Array(length);
        window.crypto.getRandomValues(array);
        return Array.from(array, dec => dec.toString(16).padStart(2, '0')).join('').substring(0, length);
    }

    function displayAlert(message) {
        const alertBox = document.getElementById('globalAlert');
        alertBox.innerText = message;
        alertBox.classList.remove('hidden');
        setTimeout(() => { alertBox.classList.add('hidden'); }, 7000);
    }

    async function authenticateSession() {
        const formData = new URLSearchParams();
        formData.append('username', document.getElementById('username').value);
        formData.append('password', document.getElementById('password').value);

        try {
            const response = await fetch(`${API_BASE}/auth/token`, { method: 'POST', body: formData });
            
            if (response.status === 429) {
                throw new Error("SECURITY BLOCK: Too many login attempts generated from your IP. Please try again in one minute.");
            }
            if (!response.ok) throw new Error("Invalid terminal authorization credentials provided.");
            
            const data = await response.json();
            sessionToken = data.access_token;
            
            csrfToken = generateSecureRandomString();
            document.cookie = `X-CSRF-Token=${csrfToken}; path=/; SameSite=Lax`;

            const tokenBase64 = sessionToken.split('.')[1];
            const parsedData = JSON.parse(atob(tokenBase64));

            document.getElementById('authSection').classList.add('hidden');
            document.getElementById('dashboardSection').classList.remove('hidden');
            
            const badge = document.getElementById('roleBadge');
            badge.innerText = `ROLE: ${parsedData.role}`;
            badge.classList.remove('hidden');
        } catch (err) {
            displayAlert(err.message);
        }
    }

    async function executeTransferRequest() {
        const payload = {
            recipient_account: document.getElementById('targetAccount').value,
            amount: parseFloat(document.getElementById('amount').value)
        };

        try {
            const response = await fetch(`${API_BASE}/transactions/transfer`, {
                method: 'POST',
                credentials: 'include',
                headers: { 
                    'Content-Type': 'application/json', 
                    'Authorization': `Bearer ${sessionToken}`,
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify(payload)
            });
            
            const output = await response.json();
            
            // ROBUST STATUS CHECKING ENGINE
            if (!response.ok) {
                // Extract the error details regardless of whether it's a 403, 422, or 429 error
                let errorMessage = "An unknown security exception occurred.";
                
                if (output.detail) {
                    // If it's a standard FastAPI array-based validation error (422)
                    if (typeof output.detail === 'object' && Array.isArray(output.detail)) {
                        errorMessage = output.detail.map(err => `${err.loc[1]}: ${err.msg}`).join(', ');
                    } else {
                        // Standard string error message (403 or 429)
                        errorMessage = output.detail;
                    }
                }
                alert(`Access Denied [Status ${response.status}]: ${errorMessage}`);
                return;
            }
            
            // Handle a clean 200 OK success response payload
            alert(`Network Broadcast Response: ${output.message}`);

        } catch (err) {
            alert("Network communication anomaly encountered during verification transaction processing.");
        }
    }

    async function fetchAuditMetrics() {
        try {
            const response = await fetch(`${API_BASE}/audit/logs`, {
                method: 'GET',
                headers: { 'Authorization': `Bearer ${sessionToken}` }
            });
            
            if (response.status === 403) {
                document.getElementById('auditLogOutput').innerText = "CRITICAL ALERT: [403 Forbidden] Operation flagged as structural intrusion event.";
                return;
            }
            
            const output = await response.json();
            document.getElementById('auditLogOutput').innerText = JSON.stringify(output, null, 2);
        } catch (err) {
            document.getElementById('auditLogOutput').innerText = "Failed to pull data from compliance log analytics workspace.";
        }
    }

    function destroySession() {
        sessionToken = "";
        csrfToken = "";
        document.cookie = "X-CSRF-Token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Strict; Secure";
        location.reload();
    }

    // Event Bindings
    document.getElementById("btnAuthenticate").addEventListener("click", authenticateSession);
    document.getElementById("btnTransfer").addEventListener("click", executeTransferRequest);
    document.getElementById("btnAudit").addEventListener("click", fetchAuditMetrics);
    document.getElementById("btnDestroy").addEventListener("click", destroySession);
});