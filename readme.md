# 🚀 VScode-server with HTTPS (Self-Signed Cert) + Containerlab + Clab VSCode Extension Installation
> ✅ You can also use the [automated installation script](#automated-installation-script) below to install everything in one go!

---

## 🛠️ Manual Installation Steps

### ✅ 1. Install code-server

```bash
curl -fsSL https://code-server.dev/install.sh | sh
```

---

### 🔐 2. Generate a Self-Signed Certificate

```bash
mkdir -p ~/.config/code-server

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout ~/.config/code-server/self-signed.key \
  -out ~/.config/code-server/self-signed.crt \
  -subj "/CN=localhost"
```

---

### ⚙️ 3. Configure code-server to Use HTTPS

Edit the config file:

```bash
nano ~/.config/code-server/config.yaml
```

Example:

```yaml
bind-addr: 0.0.0.0:8443
auth: password
password: your-strong-password
cert: ~/.config/code-server/self-signed.crt
cert-key: ~/.config/code-server/self-signed.key
```

> 💡 Port 8443 avoids needing root permissions, unlike 443.

---

### ▶️ 4. Start code-server

```bash
code-server
# or as a service:
sudo systemctl enable --now code-server@$USER
```

---

### 🌐 5. Access Code Server

Open your browser and go to:

```
https://<your-server-ip>:8443
```

> ⚠️ **Self-signed certificate warning** will appear in your browser.

---

### ⚠️ 6. Browser Compatibility Note

⚠️ Self-signed certificates may not work reliably with **Google Chrome** or **Microsoft Edge**  
✅ It is recommended to use **Firefox**, which handles self-signed certs more gracefully.

More details here: https://github.com/coder/code-server/issues/3410

---

## 🧩 7. Fixing "stdout maxBuffer length exceeded" for Containerlab Extension

### Problem:

The VSCode containerlab extension executes:

```bash
containerlab inspect -r docker --all --format json
```

Internally using `child_process.exec`, which has a default buffer size (~1MB). For large labs, this leads to:

```
RangeError [ERR_CHILD_PROCESS_STDIO_MAXBUFFER]: stdout maxBuffer length exceeded
```

---

### ✅ Fix

#### 1. Find Extension Folder

```bash
cd ~/.local/share/code-server/extensions/srl-labs.vscode-containerlab-0.12.2-universal
```

---

#### 2. Edit `inspect.js`

File: `./out/commands/inspect.js`

Find lines like:

```js
const { stdout, stderr } = await execAsync(command);
```

Change to:

```js
const { stdout, stderr } = await execAsync(command, { timeout: 15000, maxBuffer: 10 * 1024 * 1024 });
```

---

#### 3. Edit `clabTreeDataProvider.js`

File: `./out/clabTreeDataProvider.js`

Find:

```js
const { stdout } = await execAsync(cmd);
```

Change to:

```js
const { stdout } = await execAsync(cmd, { timeout: 15000, maxBuffer: 10 * 1024 * 1024 });
```

---

## 📜 Automated Installation Script

Save and run this to install everything (code-server, self-signed certs, containerlab extension, and fixes):

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/install-code-server-with-containerlab.sh | bash
```

> 🛠 Replace the link with your actual raw script URL hosted in your repo.

This script:

- Installs `code-server`
- Generates a self-signed cert
- Sets up password-based auth
- Installs the Containerlab extension
- Patches the `maxBuffer` problem
- Starts the service

📌 **Also warns about Chrome/Edge certificate issues** and recommends **Firefox** instead.

---
