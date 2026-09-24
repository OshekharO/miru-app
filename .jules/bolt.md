## 2025-02-23 - Pre-compiled RegExp Optimization
**Learning:** Instantiating `RegExp` objects inside frequently executed functions or hot paths (such as `parseExtension` during extension loading or string manipulation in error handlers) creates unnecessary overhead and heap allocation.
**Action:** Extract `RegExp` instances to static final fields at class level to re-use pre-compiled regex patterns across calls.
