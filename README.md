# Factor Mining Agent Key Demo

Demo Codex plugin for the direct Factor Mining Agent API Key flow.

This repository shows the traditional local-agent workflow:

1. Install the Codex plugin.
2. Enter a `vt_` Factor Mining Agent API Key locally.
3. Ask Codex to start from a public task or a custom factor idea.
4. Let Codex write `plugin.py`, upload it, run the backtest, fetch the factor card, and summarize the result.

The key is entered through a hidden terminal prompt or local browser setup page.
Do not paste the key into Codex chat.

## Install With Codex CLI

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/varsity-tech-product/factor-mining-agent-key-demo/main/install-codex.sh | bash
```

The installer adds the marketplace, installs the plugin, asks for the `vt_`
Agent API Key locally, validates it with Factor Mining, and starts Codex with a
demo workflow prompt.

To install without starting Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/varsity-tech-product/factor-mining-agent-key-demo/main/install-codex.sh | FACTOR_MINING_AGENT_KEY_DEMO_START_CODEX=0 bash
```

## Manual CLI Install

```bash
codex plugin marketplace add varsity-tech-product/factor-mining-agent-key-demo --ref main
codex plugin add factor-mining-agent-key-demo@factor-mining-agent-key-demo-marketplace
PLUGIN_ROOT="$(codex plugin list --marketplace factor-mining-agent-key-demo-marketplace | awk '$1 == "factor-mining-agent-key-demo@factor-mining-agent-key-demo-marketplace" { print $NF; exit }')" && python3 "$PLUGIN_ROOT/scripts/factor_setup.py" && codex "Use the Factor Mining Agent Key Demo plugin. Verify Factor Mining status, then show me the Factor Mining public task list. Do not create a session until I choose a public task or provide a custom idea. Then write a valid plugin.py locally, upload it, wait for the backtest, fetch the default factor card if available, and summarize the result."
```

## Codex Desktop Install

In Codex Desktop, add this marketplace:

- Source: `varsity-tech-product/factor-mining-agent-key-demo`
- Git ref: `main`
- Sparse paths: leave empty

Then install `Factor Mining Agent Key Demo` from the marketplace.

To configure the `vt_` Agent API Key before opening Desktop:

```bash
codex plugin marketplace add varsity-tech-product/factor-mining-agent-key-demo --ref main
codex plugin add factor-mining-agent-key-demo@factor-mining-agent-key-demo-marketplace
PLUGIN_ROOT="$(codex plugin list --marketplace factor-mining-agent-key-demo-marketplace | awk '$1 == "factor-mining-agent-key-demo@factor-mining-agent-key-demo-marketplace" { print $NF; exit }')" && python3 "$PLUGIN_ROOT/scripts/factor_setup.py"
```

Open Codex Desktop and start a new chat with:

```text
Use the Factor Mining Agent Key Demo plugin. Verify Factor Mining status, then show me the Factor Mining public task list. Do not create a session until I choose a public task or provide a custom idea. Then write a valid plugin.py locally, upload it, wait for the backtest, fetch the default factor card if available, and summarize the result.
```

## Switch Keys

Inside an active Codex CLI or Codex Desktop session, ask Codex to run:

```bash
python3 scripts/factor_setup.py --browser
```

The setup page opens on `127.0.0.1`. Paste the `vt_` Agent API Key into that
local page, not into chat.

## Local State

Configuration is stored at:

```text
~/.factor-mining-agent-key-demo/config.json
```

Run state is stored at:

```text
~/.factor-mining-agent-key-demo/runs/
```

## License

Apache License 2.0.
