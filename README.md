# ytb

`ytb` is an Ubuntu-focused command-line wrapper around `yt-dlp` and `ffmpeg`.

It downloads YouTube videos and playlists, saves each video into its own folder, downloads only manual English subtitles, and burns those subtitles into a final source-matched video when they exist.

## What it does

- Supports standard YouTube watch URLs
- Supports short `youtu.be` URLs
- Supports playlists
- Creates one folder per video
- Keeps the original downloaded media, subtitles, metadata, and logs
- Burns manual English subtitles into a final source-matched video
- Uses NVIDIA NVENC automatically when available, with CPU fallback
- Never uses YouTube auto-generated subtitles
- Retries age-restricted videos with browser cookies only when needed
- Preserves source container, codec family, resolution, frame rate, pixel format, and audio layout whenever ffmpeg can read them directly from the source file
- Reuses the source bitrate instead of picking a new quality target; when the stream bitrate is missing, it is calculated from the source packets

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
- burned output `... [burned].<ext>`, if subtitles were burned
- `metadata.json`
- `ytb.log`

Burned output extension:

- if the downloaded media is `webm`, the burned output is `webm`
- if the downloaded media is `mp4`, `m4v`, or `mov`, the burned output is `mp4`
- otherwise `ytb` keeps the same extension as the downloaded media

## Dependency policy

`install.sh` installs everything `ytb` needs up front:

- `curl`, `jq`, and `ffmpeg` from Ubuntu packages with `apt`
- the latest official upstream `yt-dlp` release
- the `ytb` launcher itself

After installation, `ytb` does not run `apt` and does not download `yt-dlp` during normal video downloads.

If you want to refresh dependencies later, rerun:

```bash
./install.sh
```

## GPU encoding

Default video encoder mode:

```bash
auto
```

In `auto` mode, `ytb` does this:

- if `nvidia-smi` exists and ffmpeg supports a source-compatible NVENC encoder, it uses NVIDIA GPU encoding
- otherwise it falls back to CPU encoding with `libx264`

You can force a specific encoder:

```bash
YTB_VIDEO_ENCODER=h264_nvenc ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

```bash
YTB_VIDEO_ENCODER=cpu ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

Supported values:

- `auto`
- `cpu`
- `libx264`
- `h264_nvenc`
- `hevc_nvenc`
- `av1_nvenc`

Important note:

- subtitle rendering itself is still a software filter in ffmpeg
- `ytb` tries to keep the source codec family when practical:
  - source `av1` usually burns to `av1_nvenc` in `webm`
  - source `h264` usually burns to `h264_nvenc` in `mp4`
  - source `vp9` in `webm` prefers `libvpx-vp9`
- `ytb` reuses the source resolution, frame rate, pixel format, color metadata, and bitrate
- if GPU encoding fails at runtime for an `mp4` output, `ytb` automatically retries with CPU `libx264` while keeping the source bitrate

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

- installs `curl`, `jq`, and `ffmpeg` with `apt`
- downloads the latest official `yt-dlp` release
- installs `ytb` and `yt-dlp` into the same command directory

Install target directory:

- non-root user: `~/.local/bin`
- `root`: `/usr/local/bin`

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

Important:

- quote YouTube URLs that contain `&`, such as `&t=30s` or `&list=...`
- example: `ytb "https://www.youtube.com/watch?v=VIDEO_ID&t=30s"`

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

## Subtitle rules

- only manual subtitles are used
- auto-generated subtitles are ignored
- English preference order:
  - `en`
  - `en-US`
  - `en-GB`
  - any other `en-*`
- if no manual English subtitles exist, the video is still downloaded, but no burned output file is created

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

If you installed as `root`, remove these instead:

```bash
rm -f /usr/local/bin/ytb /usr/local/bin/yt-dlp
```

## Troubleshooting

### `ytb: command not found`

Run:

```bash
source ~/.profile
```

If that still fails:

- non-root install: verify that `~/.local/bin` is in your `PATH`
- root install: verify that `/usr/local/bin` is in your `PATH`

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

### I have an NVIDIA GPU but ytb still uses CPU

Check these:

```bash
nvidia-smi
ffmpeg -hide_banner -encoders | grep nvenc
```

If you want to force GPU encoding explicitly:

```bash
YTB_VIDEO_ENCODER=av1_nvenc ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```
