# CI Execution Instructions

## Trigger GitHub Actions Workflow

The build pipeline has been integrated into GitHub Actions and is ready to execute.

### Option 1: Manual Dispatch (Recommended)

1. Visit: https://github.com/tvu990034-create/os/actions
2. Click on "Router OS Build and Test" workflow
3. Click "Run workflow"
4. Select branch: phase-3-build-verification
5. Click "Run workflow"

### Option 2: Merge to Main

Merge phase-3-build-verification to main branch to trigger the workflow automatically.

### Option 3: Re-push

The workflow is already configured to trigger on pushes to phase-3-build-verification, but it was pushed before the workflow was finalized. Re-pushing will trigger it:

```bash
git commit --allow-empty -m "Trigger CI workflow"
git push origin phase-3-build-verification
```

## Workflow Steps

The workflow will execute:
1. Checkout Router OS repository
2. Install build dependencies
3. Run build-host tests
4. Fetch required sources (using source manifest)
5. Verify required sources (using source manifest)
6. Setup Router OS
7. Update OpenWrt feeds
8. Install custom packages
9. Configure x86-64 build
10. Build toolchain
11. Build custom packages
12. Build image
13. Validate outputs
14. Extract image for QEMU
15. QEMU boot test
16. Upload artifacts

## Expected Duration

- Build dependencies: ~2-3 minutes
- Source fetching: ~1-2 minutes (cached)
- Toolchain build: ~10-15 minutes
- Package build: ~2-5 minutes
- Image build: ~5-10 minutes
- QEMU boot: ~5 minutes

Total: ~25-35 minutes

## Artifacts

After successful build, artifacts will be available:
- build-logs (7-day retention)
- openwrt-images (7-day retention)
- custom-packages (7-day retention)

## Monitoring

Visit the workflow run page to monitor progress:
- View real-time logs
- Check for any failures
- Download artifacts after completion
