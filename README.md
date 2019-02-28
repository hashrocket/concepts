

# Deploy

```
rsync -avz -e "ssh -F /Users/dev/.ssh/config" --exclude='/.git' --filter="dir-merge,- .gitignore" . concepts@do_lotho_concepts:~/
ssh do_lotho_concepts -C "./post_rsync.sh"
```

