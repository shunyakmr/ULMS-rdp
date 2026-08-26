# ULMS RDP Setup

Connect from **Ubuntu (or WSL2)** to the **ULMS Windows server** over RDP with a
single command — clipboard shared, a local folder mounted inside Windows, and
your password encrypted in the system keyring instead of sitting in `~/.bashrc`.

📖 **[Read the guide →](https://shunyakmr.github.io/ULMS-rdp/)**

---

## Quick start

```bash
git clone https://github.com/shunyakmr/ULMS-rdp.git
cd ULMS-rdp

# Installs FreeRDP + keyring tools, creates ~/rdp_share, stores your password
./scripts/bootstrap.sh

# Edit the host and username it created, then re-run bootstrap
$EDITOR config.env

# Add the launcher to your shell
echo "alias rdp-work='$PWD/scripts/rdp-work.sh'" >> ~/.bashrc
source ~/.bashrc
```

Then, with the VPN up:

```bash
rdp-work
```

## What's in here

| Path | |
|---|---|
| `index.qmd`, `setup.qmd`, `hacks.qmd`, `troubleshooting.qmd` | Quarto source for the guide |
| `scripts/bootstrap.sh` | One-shot setup: packages, share folder, keyring entry |
| `scripts/rdp-work.sh` | The launcher — reads `config.env`, checks the VPN, connects |
| `config.env.example` | Template for your local settings (copy to `config.env`) |

The guide is deliberately split in two:

- **[Core Setup](https://shunyakmr.github.io/ULMS-rdp/setup.html)** — the five
  steps everyone needs. No security trade-offs.
- **[Tips & Hacks](https://shunyakmr.github.io/ULMS-rdp/hacks.html)** — optional
  shortcuts, including skipping the keyring prompt and (as a last resort)
  putting the password inline. Each one states plainly what it costs you.

## File transfer

Anything in `~/rdp_share` on Linux appears at `\\tsclient\share` inside the
Windows session, and vice versa. No sync step.

## Building the site locally

```bash
quarto preview     # live reload at http://localhost:xxxx
quarto render      # static build into _site/
```

Pushing to `main` renders and publishes to GitHub Pages via
`.github/workflows/publish.yml`. Enable it once under
**Settings → Pages → Source → GitHub Actions**.

## Security notes

- `config.env` is git-ignored — it holds the internal server address.
- No password is ever stored in this repository. `secret-tool` keeps it in the
  GNOME keyring; the launcher reads it at connect time and feeds it to FreeRDP
  on stdin so it does not show up in `ps aux`.
- If you follow the inline-password hack, **do not commit your dotfiles**.
  Should a password ever reach a git history, rotate it — deleting it in a later
  commit does not remove it.

## Contributing

Corrections and additions welcome. Please redact server addresses, usernames,
and hostnames from anything you paste into an issue.

## Licence

[MIT](LICENSE). Community write-up — not an official ULMS or University IT
document.
