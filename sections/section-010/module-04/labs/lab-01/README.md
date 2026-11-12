# Repair local hostname resolution

The local hosts file maps `app-srv1` to the wrong address. This exercise tests name resolution; the address does not need to be assigned to this VM.

Read the [task](question.md) and the [worked solution](solution.md).

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
astrona ssh ats-003-lab-014
```
