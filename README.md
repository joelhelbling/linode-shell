# linode-shell

This is a pure Bash shell utility which can rebuild any linode instance.

## Objectives

On each new Linode, on your first login, you should find...

- some basic security measures configured
- a defined sudoer user installed
- a defined github user's `authorized_keys` file is installed
- ssh via root is disabled
- ssh via password is disabled
- Your arbitrary shell script, stored in a gist, has been run

The script, when it completes, will print (STDOUT) the passwords for both the root user
and the primary sudoing user.

## Setup / Configuration

First off, make a copy of `config/udf.example.json` at `config/udf.json`.  Change
values accordingly:
- the username for sudo-able login on the linode
- your github username (your ssh public keys will be retrieved from github)
- the timezone of the server
- a gist id to a shell script which will be run after the linode stackscript

Note that the `GIST_ID` is optional; if not provided, then the custom gist script step will
be skipped.  If provided, however, it should be just the SHA part of the Gist's URL.  The
gist URL will be constructed using the `GIST_ID` together with `GITHUB_USER`, so this gist
should belong to the `GITHUB_USER`.

Next, copy `.env.example` to `.env` and set the `SUMMARY_PATH` environment
variable.  This is the path to the directory where after-action summaries will
be written.  Those summaries will be json files named after your linodes'
labels/hostnames, and will contain copies of parameters used in building
those linodes, including, in plain text, the user and root passwords.

If you decide not to define the `SUMMARY_PATH`, then no summary file will be
written, but the contents will be printed to standard out.

## Usage

Currently the only available command is rebuilding an existing linode:

```
$ bin/linode-rebuild my-linode
```

You can also do a dry run:

```
$ DRY_RUN=true bin/linode-rebuild my-linode
```

## Dependencies

The two major dependencies for this utility are `jq` for parsing and mutating JSON,
and `linode-cli` for interacting with the Linode API.

_Please note that for some reason, the latest installable version of `linode-cli` is
behind the latest version of the Linode API nowadays (August, 2019), which means that
warnings to that effect are generated constantly.  For that reason this utility runs
`linode-cli` with the `--suppress-warnings` flag._

Here are instructions for installing...
- [jq](https://stedolan.github.io/jq/download/)
- [linode-cli](https://www.linode.com/docs/platform/api/using-the-linode-cli/)

## Acknowledgements

I also like Digital Ocean!  We are so lucky to have both Linode and DO.  Many of the configurations and security measures in these scripts
are inspired by two of [Digital Ocean's](https://www.digitalocean.com) excellent tutorials:

- [Initial Server Setup with Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04)
- [Additional Recommended Steps for New Ubuntu 14.04 Servers](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)
