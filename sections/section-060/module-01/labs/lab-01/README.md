# Repair a persistent NetworkManager profile

NetworkManager manages only the disposable `nm0` interface. Its saved `lab-static` profile has the wrong address and does not autoconnect. The management NIC belongs to the existing network service.

Read the [task](question.md) and the [worked solution](solution.md).

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-01/labs/lab-01
astrona ssh ats-003-lab-061
```
