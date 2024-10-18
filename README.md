# Global

This repository transforms GitHub Actions into a (12 * 2)/(3.5 * 2) free s36v36 no CC required. It is originally made out of [Docker-VNC](https://github.com/Efebey2903/Docker-VNC), but I got too addicted into this and turned it into another project with a lot more improvements.

# How It Works

#### (totally not [ChatGPT](https://chatgpt.com) generated (with some modifications), [original prompt](https://chatgpt.com/share/6711fc01-0178-8009-8ac8-2be6917b54f6))

During the first runtime, a data directory named `globalData` is created in `/mnt/`, which is [Azure's temporary storage partition](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview#temporary-disk). This partition is used for storing the swap file by default, but also offers a lot of space for storing large files. You can store the stuff that you don't want to keep throughout the runtimes inside that folder.

There's also another folder called `toBackup` inside `globalData`. Files in this folder will persist across the runtimes. It also contains these two scripts:  

- `postinstall.sh` – runs after the runtime finishes setting things up.  
- `postruntime.sh` – executes 30 minutes before the runtime stops (which has a maximum limit of 6 hours).  

You can configure tasks that you want to start or stop at each runtime.

For the `toBackup` data bridge, the script first archives the folder into the file `archive.tar.gz` (inside `globalData`). Then I used [serve](https://github.com/vercel/serve), which runs on the old runtime's port 5000, then on the new runtime, I used [aria2](https://github.com/aria2/aria2) to download the archive in parallel and finally extract the archive.

And with all of this, I also have Discord Webhook integration so you get notified on new runtimes, and [Tailscale](https://tailscale.com/) set up so you can actually access the runtime.

# Why not just use actions' [`on.schedule.cron`](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#onschedule)?

[The time is not accurate](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule:~:text=The%20schedule%20event%20can%20be%20delayed%20during%20periods%20of%20high%20loads%20of%20GitHub%20Actions%20workflow%20runs.%20High%20load%20times%20include%20the%20start%20of%20every%20hour.), which may lead to a downtime gap between each runtime.

# Secrets that are NEEDED to set

- `WEBHOOK_URL` - discord webhook url
- `TAILSCALE_KEY` - tailscale auth key

