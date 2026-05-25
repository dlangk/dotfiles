# Dev Folder Map

Reference for reproducing the folder structure on a new machine.
Run `./install.sh` and work through `SETUP_CHECKLIST.md` first, then use this to clone repos and restore Claude state.

## Claude State

These two repos must be cloned into the exact paths below — Claude Code reads them from there.

```bash
# Custom skills (powers /mac, /cloud, /network, /corpus, /repo, /rolodex)
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
│   ├── podScanner            git@github.com:dlangk/podScanner.git
│   ├── pdf2text              [local — no remote, copy manually]
│   ├── slack-summarizer      git@github.com:dlangk/slack-summarizer.git
│   └── transcription         https://github.com/dlangk/transcription.git
├── deployed-tools/
│   └── daniel-daily          git@github.com:dlangk/daniel-daily.git
├── games/
│   └── exodus                git@github.com:dlangk/exodus.git
├── learning/
│   └── machine-learning      [local — no remote, copy manually]
├── personal-tools/
│   ├── claude-sessions       [local — no remote, copy manually]
│   ├── domain-check          [local — no remote, copy manually]
│   ├── expense-management    git@github.com:dlangk/expense-management.git
│   ├── gif-maker             [local — no remote, copy manually]
│   ├── hacking               [local — no remote, copy manually]
│   ├── healthData            git@github.com:dlangk/healthData.git
│   ├── langkilde-corpus      git@github.com:dlangk/langkilde-corpus.git
│   ├── langkilde-knowledge   git@github.com:dlangk/langkilde-knowledge.git  (branch: scaffold)
│   ├── langkilde-rolodex     git@github.com:dlangk/langkilde-rolodex.git
│   ├── langkilde-style-pipeline  git@github.com:dlangk/langkilde-style-pipeline.git
│   ├── network-sniffer       [local — no remote, copy manually]
│   ├── personal-finances     git@github.com:dlangk/personal-finances.git
│   ├── prompts               git@github.com:dlangk/prompts.git
│   └── x-admin               git@github.com:dlangk/x-admin.git
├── photos/                   git@github.com:dlangk/photos.git
├── public/
│   ├── langkilde             git@github.com:dlangk/langkilde.git
│   ├── nginx-langkilde-se    git@github.com:dlangk/nginx-langkilde-se.git
│   └── yatzy                 git@github.com:dlangk/yatzy.git
└── random/
    ├── pareto                [local — no remote, copy manually]
    └── planets               git@github.com:dlangk/planets-animation.git
```

## ~/kognic

All have remotes. Clone into `~/kognic/`.

```
~/kognic/
├── ai-survey                 git@github.com:kognic-internal/ai-survey.git
├── board-materials           [not a git repo — documents folder, copy manually]
├── kognic-foundation         git@github.com:kognic-internal/kognic-foundation.git
├── management                git@github.com:dlangk/kognic-management.git
├── marketing-presentations   git@github.com:annotell/marketing-presentations.git
├── strategic-survey          git@github.com:kognic-internal/strategic-survey.git
├── the-kognic-way            git@github.com:kognic-internal/the-kognic-way.git
└── VLA-strategic-decisions   git@github.com:kognic-internal/VLA-strategic-decisions.git

Note: `kognic-internal` and `annotell` enforce SAML SSO. After uploading
your SSH key to GitHub, click "Configure SSO" next to the key and
authorize it for both orgs, otherwise clones will fail.
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
git clone git@github.com:dlangk/podScanner.git ~/dev/data-extraction/podScanner
git clone git@github.com:dlangk/slack-summarizer.git ~/dev/data-extraction/slack-summarizer
git clone https://github.com/dlangk/transcription.git ~/dev/data-extraction/transcription

# dev/deployed-tools
git clone git@github.com:dlangk/daniel-daily.git ~/dev/deployed-tools/daniel-daily

# dev/games
git clone git@github.com:dlangk/exodus.git ~/dev/games/exodus

# dev/personal-tools
git clone git@github.com:dlangk/expense-management.git ~/dev/personal-tools/expense-management
git clone git@github.com:dlangk/healthData.git ~/dev/personal-tools/healthData
git clone git@github.com:dlangk/langkilde-corpus.git ~/dev/personal-tools/langkilde-corpus
git clone git@github.com:dlangk/langkilde-knowledge.git ~/dev/personal-tools/langkilde-knowledge
git -C ~/dev/personal-tools/langkilde-knowledge checkout scaffold
git clone git@github.com:dlangk/langkilde-rolodex.git ~/dev/personal-tools/langkilde-rolodex
git clone git@github.com:dlangk/langkilde-style-pipeline.git ~/dev/personal-tools/langkilde-style-pipeline
git clone git@github.com:dlangk/personal-finances.git ~/dev/personal-tools/personal-finances
git clone git@github.com:dlangk/prompts.git ~/dev/personal-tools/prompts
git clone git@github.com:dlangk/x-admin.git ~/dev/personal-tools/x-admin

# dev/photos
git clone git@github.com:dlangk/photos.git ~/dev/photos

# dev/public
git clone git@github.com:dlangk/langkilde.git ~/dev/public/langkilde
git clone git@github.com:dlangk/nginx-langkilde-se.git ~/dev/public/nginx-langkilde-se
git clone git@github.com:dlangk/yatzy.git ~/dev/public/yatzy

# dev/random
git clone git@github.com:dlangk/planets-animation.git ~/dev/random/planets

# kognic (requires SAML SSO authorization for kognic-internal + annotell)
git clone git@github.com:kognic-internal/ai-survey.git ~/kognic/ai-survey
git clone git@github.com:kognic-internal/kognic-foundation.git ~/kognic/kognic-foundation
git clone git@github.com:dlangk/kognic-management.git ~/kognic/management
git clone git@github.com:annotell/marketing-presentations.git ~/kognic/marketing-presentations
git clone git@github.com:kognic-internal/strategic-survey.git ~/kognic/strategic-survey
git clone git@github.com:kognic-internal/the-kognic-way.git ~/kognic/the-kognic-way
git clone git@github.com:kognic-internal/VLA-strategic-decisions.git ~/kognic/VLA-strategic-decisions

# Claude state
git clone git@github.com:dlangk/claude-skills.git ~/.claude/skills
git clone git@github.com:dlangk/claude-projects.git ~/.claude/projects

echo "Done. Manually copy local-only dirs from old machine."
```
