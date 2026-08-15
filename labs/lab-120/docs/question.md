# Question

web-srv1 runs a firewalld-based distribution (contrast with data-002 elsewhere in this environment, which is Ubuntu-family and uses raw nftables instead). firewalld is installed but not yet running. You're asked to: enable and start firewalld, confirm the default zone, assign the primary interface to the `public` zone if it isn't already, permanently allow the `https` service through that zone, permanently allow a custom application port `8443/tcp` through the same zone, and prove that both changes are active right now AND will survive a reload — not just one or the other.
