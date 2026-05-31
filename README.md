# SecureBank

SecureBank is a sample secure banking web application designed to demonstrate best practices in application security, DevSecOps, and cloud-native deployment. The project includes a Python backend, a modern frontend, and infrastructure-as-code for containerized and cloud deployments. It also features automated security testing and compliance reporting.

---

## Project Structure

```text
securebank/
├── app/
│   ├── main.py                # Python backend (FastAPI/Flask)
│   └── requirements.txt       # Python dependencies
├── public/
│   ├── index.html             # Main HTML page
│   ├── css/
│   │   └── tailwind.css       # Tailwind CSS for styling
│   └── js/
│       └── security.js        # Frontend JS (security features)
├── Dockerfile                 # Docker build for backend
├── docker-compose.yaml        # Multi-container orchestration
├── deploy.yaml                # Kubernetes deployment manifest
├── ingress.yaml               # Kubernetes ingress configuration
├── service.yaml               # Kubernetes service definition
├── main.tf                    # Terraform IaC for cloud resources
├── secure-pipeline.sh         # CI/CD pipeline script
├── test_security.py           # Automated security tests (e.g., pytest, ZAP)
├── zap_compliance_report.html # ZAP security compliance report
└── README.md                  # Project documentation (this file)
```

---

## Features

- **Secure Python Backend**: Implements secure coding practices, authentication, and API endpoints.
- **Modern Frontend**: Responsive UI with Tailwind CSS and security-focused JavaScript.
- **Containerization**: Dockerfile and docker-compose for local and multi-service development.
- **Kubernetes Ready**: Manifests for deployment, service, and ingress.
- **Infrastructure as Code**: Terraform for cloud resource provisioning.
- **DevSecOps Pipeline**: Automated security testing and compliance reporting.

---

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)
- [Python 3.8+](https://www.python.org/downloads/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://www.terraform.io/downloads.html)
- [Node.js & npm](https://nodejs.org/) (for frontend development, if needed)

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Simar0024/SecureBank.git
cd SecureBank
```

### 2. Backend Setup

```bash
cd app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

The backend will start on the default port (e.g., 8000).

### 3. Frontend Setup

Open `public/index.html` in your browser. For advanced workflows, use a static server:

```bash
cd public
python -m http.server 8080
```

### 4. Run with Docker

Build and run the backend container:

```bash
docker build -t securebank-backend .
docker run -p 8000:8000 securebank-backend
```

Or use Docker Compose for multi-service setup:

```bash
docker-compose up --build
```

### 5. Kubernetes Deployment

Apply manifests to your cluster:

```bash
kubectl apply -f deploy.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

### 6. Infrastructure as Code (Terraform)

Initialize and apply Terraform configuration:

```bash
terraform init
terraform apply
```

Follow prompts to provision cloud resources.

### 7. Security Testing

Run automated security tests:

```bash
pytest test_security.py
```

Review the ZAP compliance report in `zap_compliance_report.html`.

### 8. CI/CD Pipeline

Run the secure pipeline script:

```bash
./secure-pipeline.sh
```

---

## Security Best Practices

- Use strong authentication and input validation.
- Keep dependencies up to date.
- Review and address findings in `zap_compliance_report.html`.
- Use infrastructure-as-code for reproducible environments.
- Automate security testing in your CI/CD pipeline.

---

## License

This project is for educational and demonstration purposes only.

---

## Contact

For questions or contributions, open an issue or pull request on [GitHub](https://github.com/Simar0024/SecureBank).
