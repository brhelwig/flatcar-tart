# Flatcar for Tart

[Flatcar Container Linux](https://www.flatcar.org/) (arm64, stable channel) packaged as
[Tart](https://tart.run/) VMs for Apple Silicon.

| Image | Contents |
|---|---|
| `ghcr.io/brhelwig/flatcar` | Flatcar |
| `ghcr.io/brhelwig/flatcar-k3s` | Flatcar with a single-node [k3s](https://k3s.io/) server |
| `ghcr.io/brhelwig/flatcar-tailscale` | Flatcar with [Tailscale](https://tailscale.com/) |
| `ghcr.io/brhelwig/flatcar-k3s-tailscale` | Flatcar with k3s and Tailscale |

Tags: `latest` and `stable` follow the newest Flatcar stable release; `<version>` (for example
`4757.2.1`) pins one.

## Usage

```sh
tart clone ghcr.io/brhelwig/flatcar:latest flatcar
tart run flatcar
ssh admin@$(tart ip flatcar)
```

Username and password are both `admin`. Change the password after first login if the VM is
reachable from anywhere other than your Mac.

Configuration is applied by Ignition on first boot, so the first start takes a little longer.

### Tailscale

In the `-tailscale` images `tailscaled` runs at boot. Join your tailnet with:

```sh
sudo tailscale up
```

Tailscale comes from the [Flatcar sysext bakery](https://github.com/flatcar/sysext-bakery) and
receives updates through `systemd-sysupdate`.

### k3s

```sh
tart clone ghcr.io/brhelwig/flatcar-k3s:latest k3s
tart run k3s
ssh admin@$(tart ip k3s) kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes
```

To use the cluster from the Mac:

```sh
ssh admin@$(tart ip k3s) cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$(tart ip k3s)/" > ~/.kube/flatcar-k3s.yaml
KUBECONFIG=~/.kube/flatcar-k3s.yaml kubectl get nodes
```

k3s is installed from the [Flatcar sysext bakery](https://github.com/flatcar/sysext-bakery) on first
boot and receives patch updates within its minor release through `systemd-sysupdate`.

### Resources

Defaults are 2 CPUs, 2 GB memory and a 20 GB disk. Change them while the VM is stopped:

```sh
tart set flatcar --cpu 4 --memory 4096 --disk-size 40
```

Flatcar grows its root filesystem to fill the disk on the next boot. Disks can grow but not shrink.

### Sharing folders from the Mac

```sh
tart run flatcar --dir code:~/Code
```

Every shared folder appears under `/mnt/host` in the VM, here `/mnt/host/code`. Append `:ro` for a
read-only share, for example `--dir code:~/Code:ro`.

### Serial console

```sh
tart run flatcar --serial
```

## Updates

A [workflow](.github/workflows/build.yml) checks Flatcar's stable channel daily. When a new release
appears it builds both images, pushes them to GHCR and records the version in `FLATCAR_VERSION`.
A fresh `tart clone …:latest` always gets the newest release.

Running VMs update themselves through Flatcar's own update engine.

## How the images are built

1. On Linux, `scripts/build-disk.sh` combines `butane/base.yaml` with the variant's add-ons
   (`k3s.yaml`, `tailscale.yaml`), writes Flatcar to
   a 20 GB disk image with Flatcar's `flatcar-install`, embeds the Ignition config, and points the
   kernel console at Tart's devices.
2. On macOS, `scripts/package-tart.sh` places that disk next to the VM template in `tart/` and
   pushes it with Tart.

Run a build manually with `gh workflow run build.yml`.
