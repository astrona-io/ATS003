# Question

Solve this question on: `terminal`

## Scenario

Astronaut, you are the visitor `cadet` on this training ship. The remote station is an SSH server on `localhost`, port `2222`, with the account `pilot` (password `pilotpass`). A web service on the station listens on `127.0.0.1:8081` only. You must reach the station without a password, give it a nickname and open a tunnel to the web service.

Open the visitor's shell with `sudo -iu cadet`. Do tasks 1 to 4 as `cadet`.

## Tasks

1. **Make a key pair.** Create an `ed25519` key pair at `~/.ssh/id_ed25519` with an empty passphrase. The private key must not be readable by other users.

2. **Install the public key.** Copy the public key to `pilot` on the station (`localhost`, port `2222`) so that `pilot` accepts it. Accept the host key when `ssh` asks, so that it is saved in `~/.ssh/known_hosts`.

3. **Give the station a nickname.** In `~/.ssh/config` create the entry `Host station` with `HostName localhost`, `User pilot`, `Port 2222` and `IdentityFile ~/.ssh/id_ed25519`. The command `ssh -o BatchMode=yes station true` must work with no prompt.

4. **Open a tunnel.** Keep a background `ssh` process running that forwards local port `9090` to `127.0.0.1:8081` on the station. `curl http://127.0.0.1:9090/` must return the web page.

The grader checks the key files, the `authorized_keys` file of `pilot`, `ssh -G station`, a real batch-mode login as `cadet`, and the tunnel with `ss` and `curl`.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-04](../../course.md).

The grader checks:

- Confirms cadet owns an ed25519 key pair with a private key readable only by cadet.
- Confirms the public key of cadet is in the authorized_keys file of pilot.
- Confirms 'ssh -G station' resolves to pilot@localhost port 2222 and a batch-mode login as cadet works.
- Confirms an ssh process listens on 127.0.0.1:9090 and the web service answers through it.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
