# 🧠 code-server with HTTPS (Self-Signed Cert) on Ubuntu + Containerlab Extension Fix

This guide walks you through installing `code-server` with HTTPS on Ubuntu using a self-signed certificate and fixing the **`stdout maxBuffer length exceeded`** issue in the Containerlab VSCode extension.

---

## 🛠️ 1. Install `code-server`

```bash
curl -fsSL https://code-server.dev/install.sh | sh
```

---

## 🔐 2. Generate a Self-Signed Certificate

1. Create a directory to store your certificate:

```bash
mkdir -p ~/.config/code-server
```

2. Generate the certificate:

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout ~/.config/code-server/self-signed.key \
  -out ~/.config/code-server/self-signed.crt \
  -subj "/CN=localhost"
```

---

## ⚙️ 3. Configure `code-server` to Use HTTPS

Edit the config file:

```bash
nano ~/.config/code-server/config.yaml
```

Example configuration:

```yaml
bind-addr: 0.0.0.0:8443
auth: password
password: your-strong-password
cert: ~/.config/code-server/self-signed.crt
cert-key: ~/.config/code-server/self-signed.key
```

> ⚠️ Port `8443` is used to avoid permission issues with `443` (unless running as root).

---

## ▶️ 4. Start `code-server`

Start manually:

```bash
code-server
```

Or enable it as a service:

```bash
sudo systemctl enable --now code-server@$USER
```

---

## 🌐 5. Access code-server in Browser

Visit:

```
https://<your-server-ip>:8443
```

> You’ll see a warning about the self-signed certificate. Proceed manually or import the certificate into your browser's trust store.

---

## 🐞 6. Fix: `stdout maxBuffer length exceeded` in Containerlab Extension

### ❗ Problem

The extension runs:

```bash
containerlab inspect -r docker --all --format json
```

Internally using Node.js `child_process.exec`, which has a default `maxBuffer` of ~1MB. For large lab topologies, this causes:

```
RangeError [ERR_CHILD_PROCESS_STDIO_MAXBUFFER]: stdout maxBuffer length exceeded
```

---

### ✅ Solution

#### 1. Locate the extension:

```bash
~/.local/share/code-server/extensions/srl-labs.vscode-containerlab-0.12.2-universal
```

---

#### 2. Modify `inspect.js`

**File:** `./out/commands/inspect.js`

Find lines like:

```js
const { stdout, stderr } = await execAsync(command);
```

Update to:

```js
const { stdout, stderr } = await execAsync(command, { timeout: 15000, maxBuffer: 10 * 1024 * 1024 });
```

---

#### 3. Modify `clabTreeDataProvider.js`

**File:** `./out/clabTreeDataProvider.js`

Find:

```js
const { stdout } = await execAsync(cmd);
```

Update to:

```js
const { stdout } = await execAsync(cmd, { timeout: 15000, maxBuffer: 10 * 1024 * 1024 });
```

---

### 🔁 Restart `code-server`

```bash
sudo systemctl restart code-server@$USER
```

---

✅ Now, `containerlab inspect` can handle large outputs without crashing the extension.

---

## 📌 Notes

- You may increase the buffer size (e.g., `20 * 1024 * 1024`) if necessary.
- Restart the code-server after modifying extension files for changes to take effect.
