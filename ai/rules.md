# AI Agent Rules & Guidelines

## About Me (as of Feb 2026)

I am a hobbyist developer who enjoys creating programming projects in my free time. My work falls into several categories:

### Web Development
- Building websites for sole traders and individuals doing business work
- Developing a Core API as a central monolithic backend for all web projects
- Focus on professional, maintainable solutions

### Homelab & Infrastructure
- Self-hosted server running various services
- Continuous work-in-progress adding new functionality
- Media services, home automation, and development tools (e.g., PostgreSQL)
- Heavy use of NixOS and systemd

### Data Analysis
- Occasional data analysis projects leveraging my data professional background

---

## Version Control

**NEVER use git commands or any version control commands.**

- I use Jujutsu (jj) as my VCS and manage it manually
- If there's a VCS-related issue, prompt me instead of attempting to fix it
- You should never run `git`, `jj`, or any other VCS commands

---

## Development Stack

### Environment Management
- **Nix flakes + direnv** for devshell setup
- These are managed by me - don't break them!
- DO reference them to understand the environment and available tools
- Respect the constraints and dependencies defined in `flake.nix`

### Backend Development & CLI Tools
- **Golang** is the primary language
- Write clean, easy-to-maintain Go code
- **Key rule: Don't make Go look like Java!**
  - Avoid excessive abstraction layers
  - Keep interfaces simple and purposeful
  - Prefer composition over complex type hierarchies
  - Use Go idioms, not OOP patterns from other languages

### Python (Limited Use)
- Managed with **UV** always
- Only use when I specifically request it, with two exceptions:
  
  **Exception 1 - Simple Development Tools:**
  - Automated tasks and development tools are acceptable
  - Must be limited to a single, simple file
  - Should be easily understandable
  - Nothing web-facing, only development tools
  
  **Exception 2 - Data Science:**
  - Always use Python with UV for data science tasks
  - This is the preferred tooling for data analysis work

### Frontend Development
- **Astro + React + Shadcn**
- Lean heavily on Shadcn for consistent, nice styles
- I care about typography - I'll usually specify details
- When unsure about design choices:
  - Go for simple, clean designs
  - Or ask me for guidance

---

## Infrastructure Stack

- **NixOS** for server deployments
- **Systemd** for service management
- Create **Nix modules** in projects that can be used on NixOS servers
- Keep infrastructure declarative and reproducible

---

## Testing Philosophy

I prefer light, pragmatic testing:

### Go Testing
- Unit tests only for complex functions where they add value
- Avoid big testing frameworks
- Keep tests simple and maintainable

### E2E Testing
- Use **Nix flake checks**
- Can run QEMU VMs on macOS
- Tests written in Python in a clean way
- Interactive sessions available via QEMU client when needed

---

## Documentation Guidelines

**I write the documentation - not you.**

- **DO NOT create random markdown documents in the project**
- No README files, no architecture docs, no random .md files
- I will handle all user-facing and project documentation

### Exception: .agents Folder

If a `.agents/` folder exists in the project root, you may write to these specific subdirectories:

**`.agents/backlog/`**
- Catalog of backlog items and feature requests
- Move completed items to `.agents/backlog/completed/`
- **DO NOT read from here unless explicitly told to**

**`.agents/docs/`**
- General documentation useful for future AI agent sessions
- Information about project architecture, decisions, patterns
- **Avoid reading these into context** unless:
  - I specifically request it
  - The filename clearly indicates it's relevant to the current task

**`.agents/todos/`**
- Save any todo lists here after task completion
- Helps track what's been done and what's pending
- **DO NOT read from here unless explicitly told to**

These folders are for agent-to-agent communication across sessions, not project documentation.

---

## Programming Style Mantras

These are guiding principles, not hard rules:

### 1. Emergent Design Patterns
- Design patterns should arise from the code and use-case
- They should be **descriptive, not prescriptive**
- The pattern used should reflect the best way to solve the task at hand
- Don't force patterns where they don't fit

### 2. Functional Over Object-Oriented (But Pragmatic)
- Prefer FP approaches over OOP
- Don't be dogmatic about it
- **Strong stance: I hate object inheritance**
- Avoid class hierarchies and inheritance chains

### 3. Separation of Concerns by Feature
- Organize code by **feature**, not by programming abstraction
- High-level concepts should be separated by what they do, not by technical role
- Example: prefer `user/` over `models/`, `controllers/`, `services/`

### 4. Simple is Always Better
- Favor simplicity over complexity
- Even if I ask for a complex solution, suggest simpler alternatives if appropriate
- Question complexity and propose cleaner approaches

### 5. Top-Down Development

- Think interface-first, then drill down into implementation
- Follow this progression:
  1. **Define the outcomes** - What are we trying to achieve?
  2. **Design the interface** - How should users/systems interact with this? What API endpoints are needed?
  3. **Map internal functions** - What functions do those endpoints need to call?
  4. **Consider persistence** - Do we need storage? How does it fit into the current or new schema?

- Start with the "what" and "how it's used" before diving into the "how it works"
- This helps ensure we're solving the right problem before investing in implementation details

### 6. Avoid Premature Optimization

- Don't optimize before there's a proven need
- Measure first, optimize second
- **When unsure about an implementation approach, ask questions**
- Simple, working code that can be optimized later > complex, "optimized" code from the start
- Performance concerns should be addressed when they become real problems, not hypothetical ones

---

## Working Together

### What I'll Provide
- Architecture guidance and decisions
- Tooling choices and preferences
- Project structure requirements
- Technology stack selections

### What You Should Do
- **Ask if you're unsure** about architecture, tooling, or project structure
- **Avoid running CLI commands** unless explicitly requested
  - I prefer to run commands myself
  - I'm using LLMs primarily as a code automation tool
  - Testing and execution I'll handle manually
- **Be collaborative**
  - Identify potential improvements
  - Ask questions about design decisions
  - Suggest simpler alternatives when appropriate
  - Challenge complexity when you see it
- **Respect documentation boundaries**
  - Never create markdown documentation files in the project
  - Exception: `.agents/` folder (if it exists) for backlog, internal docs, and todos
  - I handle all user-facing documentation

### Communication Style
- Be direct and honest about tradeoffs
- Point out when something seems unnecessarily complex
- Ask clarifying questions rather than making assumptions
- Suggest best practices that align with my stated preferences

---

## Summary

I value:
- **Simplicity** over cleverness
- **Pragmatism** over dogma
- **Maintainability** over feature-richness
- **Collaboration** over assumptions

When in doubt, ask! I'd rather discuss the approach than have you guess.
