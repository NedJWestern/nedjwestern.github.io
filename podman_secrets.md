---
title: "Podman Secrets"
css: custom.css
---

Manage your secrets with Podman secrets


# Run time secrets
    
## Secret File

Your secrets are in a dotenv (.env) file:
      
    #.env
    SECRET1=token1
    SECRET2=token2


<details>
<summary>Create a new "Podman secret":</summary>
A secret is a blob of sensitive data, managed by Podman, which a container needs at runtime but is not stored in the image. Replace `mydotenv` with your name of the secret.
</details>

      
    $ podman secret create mydotenv .env

<details>
<summary>List your Podman secrets:</summary>

    $ podman secret ls
    ID                         NAME                DRIVER      CREATED        UPDATED
    e7647ada09b64a2011b98bf9a  mydotenv            file        7 seconds ago  7 seconds ago

</details>

<details>
<summary>Inspect your secret's contents:</summary>
Unfortunately, Podman does not offer a direct way to do this, so use a disposable container. Warning: this is not secure.

    $ podman run --rm --secret mydotenv docker.io/library/alpine:latest cat /run/secrets/mydotenv

</details>


Load into a running container, to a file named `.env`:

    $ podman run --secret mydotenv,target=/path/to/.env ...
    
<details>
<summary>Options:</summary>

The default target is a file at `/run/secrets/mydotenv`


    $ podman run --secret mydotenv ...


Change the file permissions


    $ podman run --secret mydotenv,target=/path/to/.env,mode=0777 ...


Since `type` is `mount` by default, this argument is redundant


    $ podman run --secret mydotenv,type=mount,target=/path/to/.env ...


</details>



## Secret Variable

Your secret variable is already (securely) defined as:

    MYVAR=token1

Create a new Podman secret:

    podman secret create --env=true myvar MYVAR

<details>
<summary>List your Podman secrets:</summary>

    $ podman secret ls
    ID                         NAME                 DRIVER      CREATED        UPDATED
    0768ad449b71d56d6e65eca34  myvar            file        7 seconds ago  7 seconds ago

Note: Here the `DRIVER=file` does NOT refer to the secret `type`.

</details>


Load in running container:

TODO check

    $ podman run --secret=id=MYVAR ...
    $ podman run --secret=id=myvar,type=env ...
    
Not working

    $ podman run --rm --secret drefs_pg_pword,type=env,target=MY_SECRET docker.io/library/alpine:latest echo $MY_SECRET


# Build Time Secrets

## Secret File

<details>
<summary>
Sometimes you need a secret only for a single step in the image build. 
</summary>
E.g. you need to access an internal package repository during build time and you don't want those credentials in the final image.
</details>

Pass in the secret file:

    $ podman build --secret=id=mydotenv,src=.env ...

In the Containerfile, do:

    RUN --mount=type=secret,id=mydotenv,target=/path/to/.env cat /path/to/.env

The secret will exist only for this RUN command, it will not persist in the final image.

Note: changing the contents of secret files will not trigger a rebuild of layers that use said secrets. So if you change the contents of the secret file, add the `--no-cache` argument to force reloading the secrets.


## Secret Variable

Pass in the secret variable:

    $ podman build --secret=id=myvar,env=MYVAR ...

In the Containerfile:

    RUN --mount=type=secret,id=myvar cat /run/secrets/myvar

<details>
<summary>
Note: this is loaded as a file, not a variable
</summary>
In Docker you can do

    RUN --mount=type=secret,id=myvar,env=SECRET_TOKEN echo $SECRET_TOKEN

This is not supported in Podman. As a workaround, do:

    RUN --mount=type=secret,id=myvar,env=SECRET_TOKEN echo $(cat /run/secrets/myvar)

</details>


<details>
<summary>
concise
</summary>
Verbose
</details>
