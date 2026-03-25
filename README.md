# ytb

`ytb` is an Ubuntu-focused command-line wrapper around `yt-dlp` and `ffmpeg`.

It downloads YouTube videos and playlists, saves each video into its own folder, downloads only manual English subtitles, and burns those subtitles into a final MP4 when they exist.

## What it does

- Supports standard YouTube watch URLs
- Supports short `youtu.be` URLs
- Supports playlists
- Creates one folder per video
- Keeps the original downloaded media, subtitles, metadata, and logs
- Burns manual English subtitles into a final MP4
- Never uses YouTube auto-generated subtitles
- Retries age-restricted videos with browser cookies only when needed

## Output layout

Single video:

```text
~/Videos/<video title> [<video id>]/
```

Playlist:

```text
~/Videos/<playlist title> [<playlist id>]/
  <video title> [<video id>]/
```

Inside each video folder:

- downloaded media
- manual English subtitle `.srt`, if available
- burned MP4 `... [burned].mp4`, if subtitles were burned
- `metadata.json`
- `ytb.log`

## Dependency policy

`ytb` installs and updates its dependencies in two different ways on purpose:

- `yt-dlp`: installed from the official upstream GitHub release into `~/.local/bin/yt-dlp`
- `ffmpeg`: installed from Ubuntu packages with `apt`

Why:

- `yt-dlp` changes fast and the Ubuntu package is often too old for current YouTube behavior
- `ffmpeg` is stable and safest to get from Ubuntu packages on Ubuntu systems

This means:

- first install gets the latest upstream `yt-dlp`
- every `ytb` run refreshes `yt-dlp` automatically if the last refresh was more than 7 days ago
- `ffmpeg` is installed or upgraded by `install.sh`
- later `ffmpeg` updates should come from normal Ubuntu package updates or by rerunning `./install.sh`

If you specifically want upstream nightly `ffmpeg`, that is a different policy and should use a third-party source or static build. This repository does not do that by default.

## Before you start

This repository is private right now. Anyone installing it must have GitHub access to the repository.

Ubuntu assumptions:

- Ubuntu 22.04 or 24.04
- `bash`
- `sudo`
- internet access

## Step-by-step install on Ubuntu

### 1. Install the minimum bootstrap packages

```bash
sudo apt-get update
sudo apt-get install -y git curl
```

### 2. Clone the repository

```bash
git clone https://github.com/Photowalk/ytb.git
cd ytb
```

If Git asks for authentication, use a GitHub account that has access to this private repository.

### 3. Run the installer

```bash
chmod +x install.sh
./install.sh
```

What `install.sh` does:

- installs or upgrades `curl`, `jq`, and `ffmpeg` with `apt`
- downloads the latest official `yt-dlp` release into `~/.local/bin/yt-dlp`
- installs `ytb` into `~/.local/bin/ytb`

### 4. Reload your shell profile

```bash
source ~/.profile
```

### 5. Run it

Single video:

```bash
ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

Short link:

```bash
ytb "https://youtu.be/VIDEO_ID"
```

Playlist:

```bash
ytb "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

## Age-restricted videos

By default, `ytb` uses browser cookies only if a video actually needs them.

Default cookie browser:

```bash
chrome
```

If a video is age-restricted, `ytb` retries with:

```bash
--cookies-from-browser chrome
```

Requirements:

- the browser profile must exist on this machine
- that browser must be signed in to YouTube
- the signed-in account must be able to open the video
- the desktop keyring must allow cookie decryption

If you want to use Firefox instead:

```bash
YTB_COOKIES_BROWSER=firefox ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

If you want to disable browser cookies entirely:

```bash
YTB_COOKIES_BROWSER=none ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

## Automatic `yt-dlp` updates

`ytb` refreshes `yt-dlp` automatically if the last refresh was more than 7 days ago.

You can change that interval:

```bash
YTB_AUTO_UPDATE_DAYS=3 ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

If you want to force a fresh install immediately:

```bash
./install.sh
```

## Subtitle rules

- only manual subtitles are used
- auto-generated subtitles are ignored
- English preference order:
  - `en`
  - `en-US`
  - `en-GB`
  - any other `en-*`
- if no manual English subtitles exist, the video is still downloaded, but no burned MP4 is created

## Upgrade

To upgrade the repo files and reinstall:

```bash
cd ytb
git pull
./install.sh
```

This refreshes:

- `ytb`
- `yt-dlp`
- Ubuntu-packaged `ffmpeg`
- Ubuntu-packaged `jq`

## Uninstall

```bash
rm -f ~/.local/bin/ytb ~/.local/bin/yt-dlp
```

## Troubleshooting

### `ytb: command not found`

Run:

```bash
source ~/.profile
```

If that still fails, verify that `~/.local/bin` is in your `PATH`.

### A public video fails with old YouTube extraction errors

Run:

```bash
./install.sh
```

This installs the current upstream `yt-dlp`, which is the main fix when YouTube changes.

### Age-restricted video fails with cookie errors

Typical causes:

- browser profile exists but is not signed in
- desktop keyring is locked
- Chrome cookies could not be decrypted
- the selected browser is not the one you actually use for YouTube

Try one of these:

```bash
YTB_COOKIES_BROWSER=firefox ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

```bash
YTB_COOKIES_BROWSER=none ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

For public videos, disabling cookies is often fine.

### Playlist partially fails

`ytb` continues through the playlist, but returns a non-zero exit code at the end if one or more items had a hard failure.

Common reasons:

- private or deleted video
- region restriction
- age restriction without usable browser cookies
- temporary YouTube/network failure
