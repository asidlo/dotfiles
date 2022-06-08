# Neovim Setup

In order to install this setup the easiest way to do so is to run the
install-tools.sh script located in `dotfiles/nvim/install-tools.sh`.

There are two environment variables that can be set in order to preinstall a
list of language servers and treesitter modules when running nvim for the first
time. These are `LSP_SERVERS` and `TS_MODULES` respectively. Both take a comma
separated list with no spaces in between the string values. `TS_MODULES` can
also take 'all' as the value and it will install all of the current treesitter
modules. By default none are installed for either. See the Dockerfile mentioned
below for an example of the env variables.

You can also try it out in a docker container using the Dockerfile
located at `dotfiles/nvim/Dockerfile`.

## Plugin Configuration Layout

Each plugin has the following methods:

1. requires()
2. config(opts)
3. setup(config)

`requires()` returns a list of plugins that are required by this plugin.
`config(opts)` takes in a lua table of configs that are specific to the
particular plugin and will return a merged config, containing a table of
defaults overriden by any conflicting entries in the supplied opts.
`setup(config)` takes in a lua table with the configuration for this specific
plugin and runs the setup function for this plugin as well as setup any related
functionality.
