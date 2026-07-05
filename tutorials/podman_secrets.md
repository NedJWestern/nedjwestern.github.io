---
layout: default
title: Podman Secrets
---

A Podman secret is a blob of sensitive data — a token, password, or credentials file — managed by Podman rather than baked into your image or passed as a plain environment variable. Secrets can be mounted into containers at runtime or injected into a single build step without persisting in the final image.


# Runtime Secrets

## Secret File

Your secrets are in a dotenv (.env) file

```
#.env
SECRET1=token1
SECRET2=token2
```

Create a new "Podman secret"

      
```bash
podman secret create your_dotenv .env
```

List your Podman secrets

```bash
$ podman secret ls
ID                         NAME                DRIVER      CREATED        UPDATED
e7647ada09b64a2011b98bf9a  your_dotenv         file        7 seconds ago  7 seconds ago
```

Load into a running container, to a file named `.env`

```bash
podman run --secret your_dotenv,target=/path/to/.env ...
```
    
<details markdown="1">
<summary>File Examples</summary>

Sensible defaults

```bash
podman run --rm --secret your_dotenv,target=/path/to/.env docker.io/library/alpine:latest cat /path/to/.env
```

The default target is a file at `/run/secrets/your_dotenv`

```bash
podman run --rm --secret your_dotenv docker.io/library/alpine:latest cat /run/secrets/your_dotenv
```

Change the file permissions

```bash
podman run --rm --secret your_dotenv,target=/path/to/.env,mode=0400 docker.io/library/alpine:latest ls -al /path/to
```

Since `type` is `mount` by default, this argument is redundant

```bash
podman run --rm --secret your_dotenv,type=mount,target=/path/to/.env docker.io/library/alpine:latest cat /path/to/.env
```


</details>



## Secret Variable

Your secret variable is already (securely) defined as

```bash
YOUR_VAR=token1
```

Create a new Podman secret

```bash
podman secret create --env=true your_var YOUR_VAR
```

<details markdown="1">
<summary>List your Podman secrets</summary>

```bash
$ podman secret ls
ID                         NAME                 DRIVER      CREATED        UPDATED
0768ad449b71d56d6e65eca34  your_var             file        7 seconds ago  7 seconds ago
```

Note: Here the `DRIVER=file` does NOT refer to the secret `type`.

</details>


Load into running container

```bash
podman run --secret your_var,type=env,target=YOUR_VAR_TARGET ...
```

<details markdown="1">
<summary>Variable Examples</summary>


Define a custom target variable name
```bash
podman run --rm --secret your_var,type=env,target=YOUR_VAR_TARGET docker.io/library/alpine:latest printenv YOUR_VAR_TARGET
```

Without `target`, the variable name is the same as the Podman secret name
```bash
podman run --rm --secret your_var,type=env docker.io/library/alpine:latest printenv your_var
```

Saved to file when `type=mount` - probably not what you want
```bash
podman run --rm --secret your_var docker.io/library/alpine:latest cat /run/secrets/your_var
```

</details>

# Build Time Secrets

## Secret File

You need a secret only for a single step in the image build, e.g. to access an internal package repository.

Note: in this case, you do not need to first create a Podman secret.

```bash
podman build --secret id=your_dotenv,src=.env ...
```

In the Containerfile, do:

```Dockerfile
RUN --mount=type=secret,id=your_dotenv,target=/path/to/.env cat /path/to/.env
```

The secret will exist only for this single RUN command, it will not persist in the final image.

Note: changing the contents of secret files will not trigger a rebuild of layers that use said secrets. So if you change the contents of the secret file, add the `--no-cache` argument to force reloading the secrets.


## Secret Variable

Pass in the secret variable

```bash
podman build --secret id=your_var,env=YOUR_VAR ...
# equivalent long form
podman build --secret id=your_var,src=YOUR_VAR,type=env ...
```

In the Containerfile, do:

```Dockerfile
RUN --mount=type=secret,id=your_var cat /run/secrets/your_var
```

Note: In Podman, build time secrets can be loaded as files only, not environment variables. As a workaround, do:


```Dockerfile
RUN --mount=type=secret,id=your_var \
    export MY_VAR=$(cat /run/secrets/your_var) \
    && echo $MY_VAR
```



