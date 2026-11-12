# Build a persistent active-backup bond

The VM supplies dummy1, dummy2 as disposable dummy interfaces. They let you inspect kernel bond state without moving the management NIC. They do not model physical cable failure.

Read the [task](question.md) and the [worked solution](solution.md).

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-01/labs/lab-01
astrona ssh ats-003-lab-021
```
