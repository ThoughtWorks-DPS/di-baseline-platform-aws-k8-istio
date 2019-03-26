from invoke import task

@task
def init(ctx):
    ctx.run("terraform init -backend-config $CIRCLE_WORKING_DIRECTORY/backend.conf")

@task
def profiles(ctx):
    ctx.run("terraform output --json  kops_instance_profiles > kops_instance_profiles.json")

@task
def enc(ctx, file='local.env', encoded_file='env.ci'):
    ctx.run("openssl aes-256-cbc -e -in {} -out {} -k $DI_CIRCLECI_ENV_KEY".format(file, encoded_file))

@task
def dec(ctx, encoded_file='env.ci', file='local.env'):
    ctx.run("openssl aes-256-cbc -d -md md5 -in {} -out {} -k $DI_CIRCLECI_ENV_KEY".format(encoded_file, file))
