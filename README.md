# ytb

`ytb` is a small Ubuntu-focused command-line tool for downloading YouTube videos and playlists, saving every video into its own folder, and burning manual English subtitles into the final MP4 when those subtitles exist.

It supports:

- Standard YouTube links like `https://www.youtube.com/watch?v=...`
- Short links like `https://youtu.be/...`
- Playlist links like `https://www.youtube.com/playlist?list=...`
- Watch links that include `list=...`
- Age-restricted videos, if you have a signed-in browser profile available

It does **not** use YouTube auto-generated subtitles. If a video has no manual English subtitles, `ytb` still downloads the video but skips subtitle burn-in.

## What gets created

Single video:

```text
~/Videos/<video title> [<video id>]/
```

Playlist:

```text
~/Videos/<playlist title> [<playlist id>]/<video title> [<video id>]/
```

Inside each video folder, `ytb` keeps:

- The downloaded media file
- The subtitle `.srt` file, if manual English subtitles exist
- The burned final MP4, named `... [burned].mp4`
- `metadata.json`
- `ytb.log`

## Before you start

This repository is currently private. Anyone installing it needs GitHub access to the repository first.

Ubuntu assumptions:

- Ubuntu 22.04 or 24.04
- `bash`
- `sudo`
- internet access

## Step-by-step install on Ubuntu

### 1. Install basic packages

```bash
sudo apt-get update
sudo apt-get install -y git curl
```

You do not need to manually install `jq`, `yt-dlp`, or `ffmpeg` ahead of time. `ytb` can install them automatically on first run with `sudo apt-get`.

### 2. Optional but recommended: install Google Chrome for age-restricted videos

If you only download public videos, you can skip this step.

If you want age-restricted videos to work, install Google Chrome and sign in to YouTube in that browser profile:

```bash
curl -fsSLo /tmp/google-chrome-stable_current_amd64.deb \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y /tmp/google-chrome-stable_current_amd64.deb
```

Then start Chrome once and sign in to the YouTube account that can open the age-restricted video:

```bash
google-chrome
```

### 3. Clone the repository

If you already have GitHub access configured:

```bash
git clone https://github.com/Photowalk/ytb.git
cd ytb
```

If `git clone` asks for authentication, use a GitHub account that has access to this private repository.

### 4. Install the command

```bash
chmod +x install.sh
./install.sh
```

The installer copies `bin/ytb` to `~/.local/bin/ytb`.

### 5. Open a new terminal, or reload your shell profile

```bash
source ~/.profile
```

### 6. Run it

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

## First-run behavior

On the first run, `ytb` checks for:

- `jq`
- `yt-dlp`
- `ffmpeg`

If any of them are missing, it runs:

```bash
sudo apt-get update
sudo apt-get install -y jq yt-dlp ffmpeg
```

## How subtitle handling works

- `ytb` only uses manual subtitles from the `subtitles` section of YouTube metadata.
- `ytb` does not use `automatic_captions`.
- English subtitle preference order is:
  - `en`
  - `en-US`
  - `en-GB`
  - any other `en-*`
- If no manual English subtitles exist, the video is still downloaded, but no burned MP4 is created.

## Age-restricted videos

By default, `ytb` looks for browser cookies from:

```bash
chrome
```

If a usable Chrome profile is found, `ytb` passes `--cookies-from-browser chrome` to `yt-dlp`.

If no usable Chrome profile is found:

- public videos can still work
- age-restricted videos will usually fail

You can choose a different browser:

```bash
YTB_COOKIES_BROWSER=firefox ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

You can also disable browser cookies entirely:

```bash
YTB_COOKIES_BROWSER=none ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

## Optional environment variables

Change the output directory:

```bash
YTB_OUTPUT_ROOT="$HOME/MyVideos" ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

Use Firefox cookies instead of Chrome:

```bash
YTB_COOKIES_BROWSER=firefox ytb "https://www.youtube.com/watch?v=VIDEO_ID"
```

## Upgrade

```bash
cd ytb
git pull
./install.sh
```

## Uninstall

```bash
rm -f ~/.local/bin/ytb
```

## Troubleshooting

### `ytb: command not found`

Run:

```bash
source ~/.profile
```

If that still fails, confirm `~/.local/bin` is in your `PATH`.

### Age-restricted video fails

Make sure:

- Google Chrome is installed, or set `YTB_COOKIES_BROWSER` to a browser you actually use
- the browser profile is signed in to YouTube
- the signed-in account can open that exact video in the browser

### Playlist partially fails

`ytb` continues through the rest of the playlist when a single item fails. Common reasons:

- private video
- deleted video
- region restriction
- unavailable age-restricted cookies

At the end, the command returns a non-zero exit code if any playlist item had a hard failure.

### No subtitle burn-in happened

That usually means the video does not have manual English subtitles. In that case, the downloaded media is still kept in the video folder, and the warning is written to `ytb.log`.
