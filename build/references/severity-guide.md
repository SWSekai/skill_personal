# Severity Guide & Implementation Review Reference

## Risk Severity Definitions

- **High**: Could cause data loss, crashes, or security vulnerabilities
- **Medium**: Could cause incorrect behavior or degraded performance
- **Low**: Code smell or minor inconsistency

## Implementation Review (5c) Verification

After implementation is complete and before commit, perform a full end-to-end flow review on each modified code path:

1. **Re-read the modified code**: Do not rely on memory — read the final version of each file
2. **Walk through data flow step by step**: From trigger (button / API call) to final output, verify each step's input/output is correct
3. **Verify cross-layer consistency**:
   - Field names / types sent by frontend match what backend expects
   - DB columns queried match actual schema
   - External service calls (object storage / cache / database) use correct parameters
4. **Evaluate edge cases one by one**: List possible exception scenarios (null values, missing data, network failures), confirm code handles them or explicitly documents as known limitations
5. **Output confirmation table**:

| Check Item | Result | Notes |
|------------|:------:|-------|
| Data flow integrity | ✓/✗ | |
| Cross-layer type consistency | ✓/✗ | |
| Edge case handling | ✓/✗ | |
| Unmodified logic unaffected | ✓/✗ | |

If any ✗ items exist, **they must be fixed before entering commit flow**.
