# 🚀 VM Overlay Manager

> 🧠 Smart QCOW2 Overlay Management for Libvirt / KVM\
> ⚡ Instant switching • 🔄 Auto-reset • 🛡 Snapshot safety

------------------------------------------------------------------------

## ✨ Why this project exists

Managing QCOW2 overlays manually in Libvirt can be risky, slow and
error-prone.

VM Overlay Manager provides a clean, safe and fast way to manage
overlays like a professional.

------------------------------------------------------------------------

## 🔥 Features

### 🖥 Multi-VM Support

Manage multiple virtual machines independently.

### 🔄 Instant Overlay Switching

Switch overlays in seconds without editing XML manually.

### 🛡 Automatic Snapshots

Before any overlay change: - Snapshot is created automatically -
Rollback remains possible

### 🧹 Auto Reset on Shutdown

When the VM stops: - Automatically switches back to `Default` overlay -
Keeps production environment clean

### 🧠 Smart Detection

-   Detects Libvirt VMs
-   Lists available QCOW2 images dynamically

------------------------------------------------------------------------

## 🧩 Overlay Structure

Base.qcow2 (Clean Backing File) │ ├── Default.qcow2 🟢 Production ├──
Dev.qcow2 🧪 Testing ├── Sandbox.qcow2 🔬 Experiments └── Temp.qcow2 ⚠
Risky Stuff

------------------------------------------------------------------------

## 🛠 Installation

``` bash
git clone https://github.com/LordZatchi/vm-overlay-manager.git
cd vm-overlay-manager
chmod +x vm-overlay.sh
```

Run:

``` bash
./vm-overlay.sh
```

Follow the interactive setup wizard.

------------------------------------------------------------------------

## 🎮 Usage

``` bash
./vm-overlay.sh
```

Available actions: - 📂 List & switch overlays - ➕ Create new overlay -
🔄 Force return to Default - 📜 View logs

------------------------------------------------------------------------

## 🎯 Use Cases

-   🧪 Software testing
-   🛠 Windows repair VMs
-   🖥 WinApps environments
-   🔬 Sandbox labs
-   🧱 Disposable VM states

------------------------------------------------------------------------

## 📦 Requirements

-   Linux
-   QEMU / KVM
-   Libvirt
-   Bash
-   QCOW2 disk images

------------------------------------------------------------------------

## 🗺 Roadmap

-   [ ] Overlay diff view
-   [ ] Snapshot browser
-   [ ] Fast CLI mode
-   [ ] Optional web interface

------------------------------------------------------------------------

## ⚖ License

MIT License\
See `LICENSE` file for details.

------------------------------------------------------------------------

Built by Lord Zatchi ⚙️
