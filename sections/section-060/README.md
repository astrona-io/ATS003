# Section 060: Persistent Configurations & Diagnostics

Make network changes survive a reboot and diagnose them when they break: persist config with NetworkManager and Netplan, then inspect live sockets with ss and capture traffic with tcpdump.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [Persistent Network Managers](module-01/course.md)
2. [Netplan YAML Configurations](module-02/course.md)
3. [Active Socket Diagnostics (ss)](module-03/course.md)
4. [Raw Packet Capturing (tcpdump)](module-04/course.md)
5. [Network Troubleshooting Workflow](module-05/course.md)

## Required exercises

- [Repair a persistent NetworkManager profile](module-01/labs/lab-01/question.md): Diagnose the saved and active settings of lab-static; Correct its address and enable autoconnect; Reactivate the profile and verify it after reboot.
- [Repair merged Netplan configuration](module-02/labs/lab-01/question.md): Trace an unexpected address to a second Netplan file; Correct the merged configuration and apply it; Verify the sole intended address after reboot.
- [Active Socket Diagnostics (ss) Lab](module-03/labs/lab-01/question.md): Confirm a service is listening on a reachable address with ss; Find and delete the nftables rule that silently drops its port; Prove the service answers end to end with curl.
- [Capture and decode an HTTP conversation](module-04/labs/lab-01/question.md): Capture only TCP port 8080 on loopback into a pcap; Identify the handshake, request and successful response; Extract the request path and response token from captured payload.
- [Network troubleshooting capstone](module-05/labs/lab-01/question.md): Climb the ladder from link to firewall and find three faults; Repair the link, the name and the firewall rule in order; Prove the service answers end to end with curl.

Finish the [section knowledge check](quiz.yaml). The troubleshooting capstone follows the quiz in the course navigation.

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
