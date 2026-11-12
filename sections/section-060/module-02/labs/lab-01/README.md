# Repair merged Netplan configuration

The disposable `np0` interface has two IPv4 addresses. An extra YAML file adds an unintended address to its base configuration. The management interface must keep its existing settings.

Read the [task](question.md) and the [worked solution](solution.md).

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-02/labs/lab-01
astrona ssh ats-003-lab-062
```
