# integrate7-mirror

This is a mirror of a Integrate7 script.
The original has been posted at:

https://www.sevenforums.com/installation-setup/417827-integrate7-script-automatically-download-slipstream-all-updates.html

Unfortunately, the original script, despite being `open-source` (author words),
does not seem to be in any git repository, and is released as a passworded archive and the old released versions are taken offline and are generally unavailable.

This makes it impossible to check for viruses without extracting archive and harder to follow script changes.

This repository will put each version in a separate branch, as many old versions unavailable from the source forum and the release timeline can't be recreated with versions I have.

The password for the archives was `Integrate2020` .

Unfortunately, the archives themselves (the latest ones for sure) were too large for GitHub, so aren't provided for reference in the Git repository.

But you can get them using Docker.
```bash
docker pull accidentalvegetable/integrate7:archives
# Create container without running the image
docker create --name container_name accidentalvegetable/integrate7:archives
docker cp container_name:/src/ .
docker rm container_name
```
See `Dockerfile` for the details of the image.

The hashes of the archives are in `SHA256SUMS` and `SHA512SUMS` just in case for the reference.

## Analysis
The analysis of available versions.

### Directory `tools`

All of the files in this directory are **identical** between available versions.

`download_tools_amd64.sh` documents findings and downloads available (NOT ALL) binary equivalents for the `tools/amd64` subtree.

### Directory `add_these_files_to_Windows`

All of the files in this directory are **identical** between available versions.

No binaries, only `cmd` open-source script.