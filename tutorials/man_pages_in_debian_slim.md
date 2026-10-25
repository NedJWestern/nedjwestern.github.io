---
layout: default
title: Man Pages in Debian Slim
---

You're in a container built from `debian:<suite>-slim`. You install `man-db`, run `man ls`, and get

```
No manual entry for ls
```

Slim images tell dpkg to throw away every man page as packages are installed, so there's nothing for `man` to show.


# The Fix

Delete the rule that drops man pages, *before* installing anything else

```Dockerfile
RUN sed -i '\|^path-exclude /usr/share/man/\*|d' /etc/dpkg/dpkg.cfg.d/docker
```

Reinstall the packages already in the base image, to restore their pages, then install as normal

```Dockerfile
RUN apt-get update \
    && apt-get install -y --reinstall $(dpkg-query -W -f='${binary:Package}\n') \
    && apt-get install -y man-db manpages <your packages>
```

Check

```bash
man ls
```

All three steps are needed, in this order:

| Step | `man ls` |
| -- | -- |
| Install `man-db` only | No manual entry |
| Also delete the `path-exclude` rule | No manual entry: the rule only affects future installs |
| Also reinstall the installed packages | Works |

The reinstall covers only the base image's packages (84 on Debian 13, about 11 seconds). Anything installed after the `sed` gets its pages as normal.

<details markdown="1">
<summary>Why it happens</summary>

Slim images ship `/etc/dpkg/dpkg.cfg.d/docker`, which contains lines like

```
path-exclude /usr/share/doc/*
path-exclude /usr/share/info/*
path-exclude /usr/share/locale/*
path-exclude /usr/share/man/*
```

dpkg skips any file matching a `path-exclude` pattern while unpacking a package. The pages for the base image's own packages were stripped when the image was built, which is why deleting the rule isn't enough on its own.

See it for yourself

```bash
podman run --rm docker.io/library/debian:stable-slim cat /etc/dpkg/dpkg.cfg.d/docker
```

</details>

<details markdown="1">
<summary>Also restore docs, info pages or translations</summary>

Delete their `path-exclude` lines too, or the whole file, before the reinstall

```Dockerfile
RUN rm /etc/dpkg/dpkg.cfg.d/docker
```

</details>

<details markdown="1">
<summary>Or don't use slim</summary>

`debian:<suite>` (not `-slim`) has no exclude rule. Its man pages are already there and only `man-db` is missing

```Dockerfile
FROM docker.io/library/debian:stable
RUN apt-get update && apt-get install -y man-db manpages
```

On Ubuntu, minimized images do the same stripping, but `unminimize` undoes it in one command (it restores everything, not just man pages, so it's slower).

</details>

<details markdown="1">
<summary>Where this is documented</summary>

What slim removes is documented; how to undo it isn't.

- Docker Hub's [slim variant description](https://github.com/docker-library/docs/blob/master/debian/variant-slim.md): "removing some extra files that are normally not necessary within containers, such as man pages and documentation", and "definitely subject to change".
- The exact list: debuerreotype's [`.slimify-excludes`](https://github.com/debuerreotype/debuerreotype/blob/master/scripts/.slimify-excludes).
- `path-exclude` itself: `man dpkg`, which slim doesn't include.

</details>
