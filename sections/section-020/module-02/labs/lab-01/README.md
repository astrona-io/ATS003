# Build a persistent software bridge

The VM supplies dummy0 as disposable dummy interfaces. They let you inspect kernel bridge state without moving the management NIC. They do not model physical cable failure.

Read the [task](question.md) and the [worked solution](solution.md).

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-02/labs/lab-01
astrona ssh ats-003-lab-022
```
