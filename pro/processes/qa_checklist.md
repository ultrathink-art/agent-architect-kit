# QA Checklist
#
# WHY THIS EXISTS: "It works on my machine" is not QA. This checklist catches
# the failures that slip through automated tests — visual regressions, mobile
# breakage, missing images, and deployment-specific issues.
#
# MANDATORY: Run after ANY production change before declaring "done."

## After Product Changes

- [ ] Visit [YOUR_SITE] and verify products display
- [ ] Check each modified product has images
- [ ] Check products are in correct categories
- [ ] Click product to verify detail page loads
- [ ] Verify image gallery works (click thumbnails)
- [ ] Check "Add to Cart" button works

## After Code Deploys

- [ ] Wait for CI/CD to complete
- [ ] Visit [YOUR_SITE] - page loads without errors
- [ ] Check browser console for JS errors
- [ ] Test on mobile viewport
- [ ] Verify any changed functionality works

## After Design Uploads

**Run automated QA first:**
```bash
bin/design-qa <image_path> <product_type>
```

- [ ] `bin/design-qa` passes (no errors)
- [ ] Transparent background verified (apparel only)
- [ ] Dimensions match product spec
- [ ] Text is legible and has no typos
- [ ] Mockup images show design correctly on product
- [ ] Sync images from fulfillment provider

## Quick Verification
# WHY: A single command that checks all visible products saves time and catches
# issues that manual browsing misses (like products with zero images).

```bash
# Adapt this to your data model:
bin/[YOUR_DEPLOY_TOOL] app exec 'bin/rails runner "
Item.where(hidden: false, available: true).each do |item|
  status = item.images.count > 0 ? \"OK\" : \"NO IMAGES\"
  puts \"#{status}: #{item.name} (#{item.images.count} images)\"
end
"'
```

## Failure Mode

If QA reveals issues:
1. Fix immediately before moving on
2. Document what went wrong
3. Add check to this list if it's a new failure mode
# WHY: This checklist grows from failures. Every item here was added because
# something slipped through without it. If you find a new failure mode,
# add it — that's how the checklist stays effective.
