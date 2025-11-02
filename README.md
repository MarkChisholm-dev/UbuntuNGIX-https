# ⚡️ Multi-Domain Nginx + Certbot Auto Setup

![Bash](https://img.shields.io/badge/Bash-4.0+-121011?style=flat-square&logo=gnu-bash&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-Auto_Config-green?style=flat-square&logo=nginx)
![Certbot](https://img.shields.io/badge/SSL-Let%27s_Encrypt-blue?style=flat-square&logo=letsencrypt)
**Fully automated Nginx + HTTPS provisioning for multiple domains — in one command.**  
Designed for simplicity, clarity, and repeatable server setups.

---

## 🚀 Overview

This Bash script automates the entire process of:

- Installing **Nginx** and **Certbot**
- Creating unique **document roots** for each domain
- Generating **Nginx configs** dynamically
- Issuing **Let's Encrypt SSL certificates**
- Setting up **auto-renewal** and **permissions**
- Testing and reloading Nginx — so you don’t have to

> Perfect for VPS and cloud environments where you need to deploy and secure multiple sites fast.

---

## 🧠 Author

**Mark Chisholm**  

---

## ⚙️ Features

✅ Handles **multiple domains** in one go  
✅ Auto-installs Nginx + Certbot if missing  
✅ Configures **UFW firewall** for HTTPS  
✅ Generates sample HTML landing pages  
✅ Verifies Nginx syntax at every step  
✅ Runs a **Certbot dry-run** to confirm renewals  
✅ Enforces clean **ownership & permissions**

---

## 🧩 Example Usage

```bash
git clone https://github.com/<your-username>/nginx-multi-domain-setup.git
cd nginx-multi-domain-setup
chmod +x setup.sh
sudo ./setup_ssl.sh
```
