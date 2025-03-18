# WP Docker LEMP Stack

## 📌 Project Overview
WP Docker LEMP Stack is a fully automated Docker-based environment for deploying and managing multiple WordPress websites efficiently. It is optimized for performance and security, integrating **NGINX Proxy, PHP-FPM, MariaDB**, and **Let's Encrypt SSL**. The system dynamically configures **PHP-FPM and MariaDB** based on the available system resources to maximize efficiency.

## 🖥️ System Requirements
Before installing WP Docker LEMP Stack, ensure that your server meets the following requirements:

### **Supported Operating Systems**
- **Linux** (Ubuntu, Debian, CentOS, RHEL)
- **macOS**

### **Software Requirements**
- **Docker** (20.10 or later)
- **Docker Compose** (v2.0 or later)
- **bash** shell (for running management scripts)
- **openssl** (for generating SSL certificates)
- **curl, awk, sed, grep** (used in scripts)

### **Hardware Requirements**
- **Minimum**:
  - 2 CPU Cores
  - 2GB RAM
  - 10GB Disk Space
- **Recommended**:
  - 4+ CPU Cores
  - 8GB RAM
  - SSD Storage (for better performance)

## 🚀 Features
- **Multi-Site Support**: Host multiple WordPress websites with isolated configurations.
- **Automatic SSL**: Self-signed SSL certificates for local testing or real SSL via Let's Encrypt.
- **NGINX Proxy**: Handles HTTPS termination and routes traffic efficiently.
- **Dynamic PHP-FPM Configuration**: Adjusts PHP-FPM settings based on system resources.
- **Optimized MariaDB Configuration**: Uses available CPU, RAM, and storage type to tune database settings.
- **Customizable Deployment**: Configurations are generated dynamically per website.
- **Dockerized Environment**: Ensures consistency across different environments.

## 📥 Installation

### 1️⃣ **Clone the Repository**
```bash
# Clone the repository to your server
git clone https://github.com/your-username/wp-docker-lemp.git
cd wp-docker-lemp
```

### 2️⃣ **Set Up Configuration**
```bash
# Copy the example config file and edit as needed
cp shared/config/config.example.sh shared/config/config.sh
nano shared/config/config.sh
```
Modify the configuration file to match your system setup.

### 3️⃣ **Install Dependencies**
Ensure that **Docker** and **Docker Compose** are installed. If not, install them:

#### **For Ubuntu/Debian**
```bash
sudo apt update && sudo apt install -y docker.io docker-compose
```

#### **For CentOS/RHEL**
```bash
sudo yum install -y docker docker-compose
```

#### **For macOS**
Install **Docker Desktop** from [Docker's official website](https://www.docker.com/products/docker-desktop/).

### 4️⃣ **Start NGINX Proxy**
```bash
cd nginx-proxy
docker-compose up -d
```

### 5️⃣ **Create a New WordPress Website**
```bash
./scripts/create-website.sh
```
Follow the prompts to set up your WordPress site.

### 6️⃣ **Access Your Website**
After setup, your website should be accessible at:
```
https://yourdomain.dev
```

## 🛠️ Management Commands
Once installed, you can manage websites using the provided scripts:

- **List websites:** `ls sites/`
- **Delete a website:** `./scripts/delete-website.sh`
- **Restart NGINX Proxy:** `./scripts/utils.sh restart_nginx_proxy`

## 🔥 Next Steps
- [ ] Add step-by-step usage guide.
- [ ] Implement automatic Let's Encrypt SSL support.
- [ ] Improve monitoring tools for PHP and MariaDB performance.

## 📜 License
This project is licensed under the **MIT License**.

---

**Contributors**: @your-username

