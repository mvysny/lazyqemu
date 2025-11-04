# LazyVirt

A TUI client for virt. Under development. Requires Ruby 3.3+. Currently runs `virsh`.
Future plans:

- Implement a full-blown TUI (using `tty-box` and `tty-screen`)
- Automatic balloon control (needs to be enabled)

## Setup

```
bundle install
bundle exec rake test
```

If `bundle install` fails, try running `bundle config set --global path '~/.gem'`.

## Running

```
bin/lazyvirt
```

