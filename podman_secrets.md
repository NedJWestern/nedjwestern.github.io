# Podman Secrets

Manage your secrets with Podman secrets
    

    
## Dotenv File

Given this dotenv (.env) file:
      
    #.env
    SECRET1=token1
    SECRET2=token2

Create a new Podman secret:
      
    $ podman secret create mysecret .env
      
View your Podman secrets:

    $ podman secret ls
    ID                         NAME                DRIVER      CREATED        UPDATED
    e7647ada09b64a2011b98bf9a  mysecret            file        7 seconds ago  7 seconds ago

Unfortunately, Podman does not offer a way to directly inspect the contents of a secret. Use a disposable container for this purpose. Warning: this is not considered secure.

    $ podman run --rm --secret mysecret docker.io/library/alpine:latest cat /run/secrets/mysecret

Load into a running container:

    $ podman run --secret mysecret,target=/path/to/.env ...
    
- If undefined, the target defaults to a file at `/run/secrets/mysecret`
- Change the target filename with `target=/new/path/to/.env`


## Secret Variable

Your secret variable is already (securely) defined as:

    MYSECRET=token1

Create a new Podman secret:

    podman secret create --env=true mysecret2 MYSECRET

View your Podman secrets:

    $ podman secret ls
    ID                         NAME                 DRIVER      CREATED        UPDATED
    0768ad449b71d56d6e65eca34  mysecret2            file        7 seconds ago  7 seconds ago

Note: Here the DRIVER=file does NOT refer to the secret type

Load in running container:

TODO check

    $ podman run --secret mysecret2,type=env ...
    
Not working

    $ podman run --rm --secret drefs_pg_pword,type=env,target=MY_SECRET docker.io/library/alpine:latest echo $MY_SECRET


## Build Time Secrets

Sometimes you need a secret only for a single step in the image build. Pass in the secret:

    $ podman build --secret=id=mysecret,src=.env

In the Containerfile, do:

    RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret

The secret will exist only for this RUN command, it will not persist in the final image.

Podman only supports secret files here, not variables.