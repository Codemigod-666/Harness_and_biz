@AGENTS.md

## Claude Code
- Skills and the context-guard hook come from the global `devkit` plugin (~/dev-playbook/devkit):
  `/devkit:supervise`, `/devkit:work`, `/devkit:brief`, `/devkit:land`, `/devkit:handover`, `/devkit:resume`,
  `/devkit:backlog`, `/devkit:conventions`, `/devkit:fleet`. Don't disable the hook.
- Subagents (Agent tool) only for read-only fan-out searches; they never own a lane.
