# Entitlements cleanup test

Create `activation-key` and `org-id` files with contents that allow activating `subscirption-manager`, then run

```bash
podman build -t entitlements-cleanup-test .

podman run --rm -it entitlements-cleanup-test
```

and examine files there.
