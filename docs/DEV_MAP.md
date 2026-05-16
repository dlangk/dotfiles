# Dev Folder Map

Reference for reproducing the folder structure on a new machine.
Run `./install.sh` and work through `SETUP_CHECKLIST.md` first, then use this to clone repos and restore Claude state.

## Claude State

These two repos must be cloned into the exact paths below — Claude Code reads them from there.

```bash
# Custom skills (powers /power, /maintain, /net, /mac-health-check, etc.)
git clone git@github.com:dlangk/claude-skills.git ~/.claude/skills

# Project memories (context Claude has built up per project)
git clone git@github.com:dlangk/claude-projects.git ~/.claude/projects
```

## ~/dev

Folder structure with git remotes. Dirs marked **[local]** have no remote — rsync or copy manually.

```
~/dev/
├── data-extraction/
│   ├── linkedin-summarizer   git@github.com:dlangk/linkedin-summarizer.git
│   ├── podScanner            https://github.com/dlangk/podScanner
│   ├── pdf2text              [local — no remote, copy manually]
│   ├── slack-summarizer      git@github.com:dlangk/slack-summarizer.git
│   └── transcription         [local — no remote, copy manually]
├── deployed-tools/
│   └── daniel-daily          git@github.com:dlangk/daniel-daily.git
├── games/
│   └── exodus                git@github.com:dlangk/exodus.git
├── learning/
│   └── machine-learning      [local — no remote, copy manually]
├── personal-tools/
│   ├── claude-sessions       [local — no remote, copy manually]
│   ├── domain-check          [local — no remote, copy manually]
│   ├── expense-management    https://github.com/dlangk/expense-management.git
│   ├── gif-maker             [local — no remote, copy manually]
│   ├── hacking               [local — no remote, copy manually]
│   ├── healthData            https://github.com/dlangk/healthData
│   ├── langkilde-corpus      https://github.com/dlangk/langkilde-corpus.git
│   ├── langkilde-knowledge   [local — no remote, copy manually]
│   ├── langkilde-rolodex     [local — no remote, copy manually]
│   ├── langkilde-style-pipeline  https://github.com/dlangk/langkilde-style-pipeline.git
│   ├── network-sniffer       [local — no remote, copy manually]
│   ├── personal-finances     https://github.com/dlangk/personal-finances.git
│   ├── prompts               https://github.com/dlangk/prompts.git
│   └── x-admin               https://github.com/dlangk/x-admin.git
├── photos/                   https://github.com/dlangk/photos.git
├── public/
│   ├── langkilde             https://github.com/dlangk/langkilde
│   ├── nginx-langkilde-se    https://github.com/dlangk/nginx-langkilde-se
│   └── yatzy                 https://github.com/dlangk/yatzy
└── random/
    ├── pareto                [local — no remote, copy manually]
    └── planets               https://github.com/dlangk/planets-animation.git
```

## ~/kognic

All have remotes. Clone into `~/kognic/`.

```
~/kognic/
├── ai-survey                 https://github.com/kognic-internal/ai-survey.git
├── board-materials           [not a git repo — documents folder, copy manually]
├── kognic-foundation         https://github.com/kognic-internal/kognic-foundation
├── management                https://github.com/dlangk/kognic-management.git
├── marketing-presentations   https://github.com/annotell/marketing-presentations/
├── strategic-survey          https://github.com/kognic-internal/strategic-survey
└── VLA-strategic-decisions   https://github.com/kognic-internal/VLA-strategic-decisions
```

## ~/dotfiles

```bash
git clone git@github.com:dlangk/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

## Other top-level dirs

These are not git repos — either auto-generated or manually managed:

- `~/go/` — Go workspace, auto-created by Go toolchain
- `~/IdeaProjects/` — IntelliJ projects, copy manually if needed
- `~/nltk_data/` — auto-downloaded by NLTK, skip

## Clone script

Paste this after `./install.sh` to clone all repos at once:

```bash
#!/bin/bash
# Clone all dev repos to correct locations

mkdir -p ~/dev/{data-extraction,deployed-tools,games,learning,personal-tools,photos,public,random}
mkdir -p ~/kognic

# dev/data-extraction
git clone git@github.com:dlangk/linkedin-summarizer.git ~/dev/data-extraction/linkedin-summarizer
git clone https://github.com/dlangk/podScanner ~/dev/data-extraction/podScanner
git clone git@github.com:dlangk/slack-summarizer.git ~/dev/data-extraction/slack-summarizer

# dev/deployed-tools
git clone git@github.com:dlangk/daniel-daily.git ~/dev/deployed-tools/daniel-daily

# dev/games
git clone git@github.com:dlangk/exodus.git ~/dev/games/exodus

# dev/personal-tools
git clone https://github.com/dlangk/expense-management.git ~/dev/personal-tools/expense-management
git clone https://github.com/dlangk/healthData ~/dev/personal-tools/healthData
git clone https://github.com/dlangk/langkilde-corpus.git ~/dev/personal-tools/langkilde-corpus
git clone https://github.com/dlangk/langkilde-style-pipeline.git ~/dev/personal-tools/langkilde-style-pipeline
git clone https://github.com/dlangk/personal-finances.git ~/dev/personal-tools/personal-finances
git clone https://github.com/dlangk/prompts.git ~/dev/personal-tools/prompts
git clone https://github.com/dlangk/x-admin.git ~/dev/personal-tools/x-admin

# dev/photos
git clone https://github.com/dlangk/photos.git ~/dev/photos

# dev/public
git clone https://github.com/dlangk/langkilde ~/dev/public/langkilde
git clone https://github.com/dlangk/nginx-langkilde-se ~/dev/public/nginx-langkilde-se
git clone https://github.com/dlangk/yatzy ~/dev/public/yatzy

# dev/random
git clone https://github.com/dlangk/planets-animation.git ~/dev/random/planets

# kognic
git clone https://github.com/kognic-internal/ai-survey.git ~/kognic/ai-survey
git clone https://github.com/kognic-internal/kognic-foundation ~/kognic/kognic-foundation
git clone https://github.com/dlangk/kognic-management.git ~/kognic/management
git clone https://github.com/annotell/marketing-presentations/ ~/kognic/marketing-presentations
git clone https://github.com/kognic-internal/strategic-survey ~/kognic/strategic-survey
git clone https://github.com/kognic-internal/VLA-strategic-decisions ~/kognic/VLA-strategic-decisions

# Claude state
git clone git@github.com:dlangk/claude-skills.git ~/.claude/skills
git clone git@github.com:dlangk/claude-projects.git ~/.claude/projects

echo "Done. Manually copy local-only dirs from old machine."
```
