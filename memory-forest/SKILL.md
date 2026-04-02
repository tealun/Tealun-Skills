---
name: memory-forest
description: "Structured memory management for AI agents using forest ecology metaphor. Supports multi-agent isolation, seasonal health decay, automatic archiving. Use when: agent needs persistent memory, multiple agents need isolated memories, automatic memory maintenance, recording corrections by scene. Triggers: remember, correction, reflect, 记住, 纠正, 反思."
homepage: https://github.com/openclaw/memory-forest
metadata: { "openclaw": { "emoji": "🌳", "requires": { "bins": ["bash", "date", "grep", "sed"] } } }
---

# Memory Forest

Structured memory management for AI agents using forest ecology metaphor.

## When to Use

✅ **USE this skill when:**

- Agent needs persistent memory across sessions
- Multiple agents need isolated but shareable memories
- Automatic memory maintenance and health tracking
- Recording corrections and learnings by scene

❌ **DON'T use when:**

- Simple one-time notes → use standard notes
- Large binary data → use database

## Quick Start

```bash
./install.sh
memory-forest init
memory-forest remember default corrections "Don't ask user" "Report generation"
memory-forest status
```

## Commands

| Command | Description |
|---------|-------------|
| `init [agent-id]` | Initialize forest |
| `remember <agent> <tree> <content> [context]` | Grow memory |
| `recall <agent> <scene>` | Recall by scene (error/morning/task) |
| `status [agent-id]` | Show forest health |
| `maintain [agent-id]` | Seasonal maintenance |

## Memory Format

```markdown
---
id: "abc123"
tree: "corrections"
level: leaf
health: 120
grown: "2026-03-31 17:52:54"
season: "spring"
---

# Memory Entry

**Context**: Report generation

Content here...
```

## License

MIT
