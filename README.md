# ERPnext
ERPnext installation in ubuntu

Here's a clean, ready-to-use `README.md` file for your ERPNext installer repo. It explains everything from prerequisites to execution using a single command.

# 🚀 ERPNext Full Automated Installer for Ubuntu 24.04

This script installs the **latest stable version of ERPNext (v15)** with all dependencies on a **fresh Ubuntu 24.04** system. It sets up a full **production environment** with MariaDB, Nginx, Supervisor, Redis, wkhtmltopdf, and more.

---

## ✅ Features

- Automatic installation of all required packages
- Uses **MariaDB** instead of MySQL for better scalability
- Installs and configures **Frappe Bench**
- Sets up site at `erp.local` with admin credentials
- Production-ready: includes **Nginx**, **Supervisor**, **wkhtmltopdf**
- One-line execution — no manual steps required

---

## ⚙️ Default Setup Details

| Item                   | Value                        |
|------------------------|------------------------------|
| **Ubuntu user**        | `jhon`                       |
| **MariaDB user**       | `mariadb`                    |
| **MariaDB password**   | `admin`                      |
| **ERPNext site name**  | `erp.local`                  |
| **Admin password**     | `erpadmin`                   |
| **Frappe version**     | Latest stable (v15)          |
| **Domain/SSL**         | Not configured (local only)  |

---

## 🧾 Prerequisites

- A **fresh installation** of Ubuntu 24.04
- Internet connection
- Run as **root user** or with `sudo`

---

## 🚀 One-Line Installation Command

Paste and run this command in your terminal:

```
curl -s https://raw.githubusercontent.com/zahirrayhanjhon/ERPnext/main/erp.sh | sudo bash

````

This will:

* Create user `jhon` if it doesn't exist
* Install and configure all dependencies
* Set up MariaDB and ERPNext site
* Configure Supervisor + Nginx for production use

---

## 🌐 Access ERPNext

After installation:

1. Add this to your local `/etc/hosts` file:

   ```bash
   echo "127.0.0.1 erp.local" | sudo tee -a /etc/hosts
   ```

2. Visit ERPNext in your browser:

   ```
   http://erp.local
   ```

3. Login credentials:

   * **Username**: `Administrator`
   * **Password**: `erpadmin`

---

## 🔧 Basic Usage Commands

After switching to `jhon` user:

```bash
sudo su - jhon
cd frappe-bench
```

Common `bench` commands:

```bash
bench restart
bench update
bench backup
bench --site erp.local console
```

---

## 📦 To-Do (Future Improvements)

* Add domain & Let's Encrypt SSL support
* Auto backup scripts
* Optional development mode

---

## 🛡 Disclaimer

> This script is intended for local or internal network use. Use caution before deploying in public or production environments without additional security measures.

---

## 📬 Questions?

Create an issue in this repo or message me on GitHub.

---

**Happy ERP-ing!** 🎉

```

---

Would you like me to push this to your GitHub repo as a `README.md` file?
```

