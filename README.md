# ULMS RDP Setup

Connect to the **ULMS Windows server** by opening a terminal and typing
`rdp-work`. No password to type: it is stored in your computer's encrypted
password store. You still approve each login with Duo Mobile.

📖 **[Read the guide →](https://shunyakmr.github.io/ULMS-rdp/)**

*Shunya Kimura, SIBE Group, Lecturer in Analytics*

---

## In short

1. **Ask ULMS IT** for Remote Desktop access and the server's IP address.
2. **Set up `rdp-work`** once. The steps differ for Linux, macOS and Windows
   (only Linux is tested).
3. **Connect:** VPN (if off campus) → terminal → `rdp-work` → approve Duo.

## What's in here

| Path | |
|---|---|
| `index.qmd` | The guide (Quarto source) |
| `scripts/bootstrap.sh` | Linux one-time setup: packages, share folder, keyring entry |
| `scripts/rdp-work.sh` | Linux launcher: reads `config.env`, checks the VPN, connects |
| `config.env.example` | Template for your local settings (copy to `config.env`) |

`config.env` is git-ignored because it holds the internal server address. No
password is ever stored in this repository.

## Building the site locally

```bash
quarto preview     # live reload
quarto render      # static build into _site/
```

Pushing to `main` publishes to GitHub Pages via `.github/workflows/publish.yml`.

## Licence

[MIT](LICENSE). Not an official ULMS or University IT document.
