# Migration Instructions

Since this project was created inside the `ai_scratchpad` workspace, you need to move it to its own directory and initialize it as a git repository.

Run the following commands from the `ai_scratchpad` directory:

```bash
# 1. Move the directory to your projects folder (sibling to ai_scratchpad)
mv claude-switcher ../claude-switcher

# 2. Navigate to the new project
cd ../claude-switcher

# 3. Initialize a new Git repository
git init
git branch -M main

# 4. Create the initial commit
git add .
git commit -m "Initial commit of claude-switcher"

# 5. Create a GitHub repository (requires GitHub CLI)
# gh repo create claude-switcher --public --source=. --remote=origin --push
```

## Post-Migration

1.  **Setup Secrets**: Run `./setup.sh` if you haven't already.
2.  **Update Secrets**: Edit `~/.claude-switcher/secrets.sh` with your keys.
3.  **Add to PATH**: Add the `scripts` directory to your PATH.
