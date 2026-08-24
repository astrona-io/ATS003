# Chapter 1: Packet Filtering with nftables

Unlike older tools, "nftables" starts completely empty. You construct the filtering structure yourself:

```text
[Ruleset] -> [Tables] -> [Chains] -> [Rules]
```

To create an IPv4 table and an ingress base chain:
```bash
sudo nft add table ip my_filter
sudo nft add chain ip my_filter ingress { type filter hook input priority 0 ; policy accept ; }
```

---

## Guided Practice Lab 1: nftables Filtering

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-031
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure filtering rules
Initialize table and input chain:
```bash
nft add table ip filter_table
nft add chain ip filter_table ingress { type filter hook input priority 0 ; policy accept ; }
```
Append rules to drop port 5000, and restrict port 6002 access to IP "192.168.10.80" only:
```bash
nft add rule ip filter_table ingress tcp dport 5000 drop
nft add rule ip filter_table ingress ip saddr 192.168.10.80 tcp dport 6002 accept
nft add rule ip filter_table ingress tcp dport 6002 drop
```
Verify the ruleset:
```bash
nft list ruleset
```
