# Global

### NOTE: this repo is meant to be used for me only. if you somehow stumbled on this, be sure to change some stuff in `runglobal.yml`.

This repository transforms GitHub Actions into a (12 * 2)/(3.5 * 2) s36v36. It is originally a fork of [Docker-VNC](https://github.com/Efebey2903/Docker-VNC), but I got too addicted into this and turned it into another project with a lot more improvements.

# How It Works

During the first runtime, a data directory named `globalData` is created in `/mnt/`, which is [Azure's temporary storage partition](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview#temporary-disk). This partition, by default is used for storing the swap file, but also offers a lot of space for storing large files.

Now here's where my stuff comes in. The runtime will make a `globalData` directory in that temporary storage partition. You can store the stuff that you don't want to keep throughout the runtimes inside that folder. But there’s also another folder called `toBackup` inside `globalData`. Files in this folder will persist across the runtimes. It also contains these two scripts:  

- `postinstall.sh` – runs after the runtime finishes setting things up.  
- `postruntime.sh` – executes 30 minutes before the runtime stops (which has a maximum limit of 6 hours).  

You can configure tasks that you want to start or stop at each runtime.

For the `toBackup` data bridge, I first archive the folder into the file `archive.tar.gz`. Then I used [serve](https://github.com/vercel/serve), which runs on the old runtime's port 5000, then on the new runtime, I used [aria2](https://github.com/aria2/aria2) to download the archive in parallel and finally extract the archive.

And with all of this, I also have Discord Webhook integration so you get notified on new runtimes, and [Tail with a Scale](https://tailscale.com/) set up so you can actually access the runtime.

# Why not just use action's [`cron`](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#onschedule)?

The time is not accurate, which may lead to a downtime gap between each runtime. See [https://github.com/orgs/community/discussions/52477](https://github.com/orgs/community/discussions/52477)

# Secrets that are NEEDED to set

- `WEBHOOK_URL` - discord webhook url
- `TAILSCALE_KEY` - tailscale auth key

