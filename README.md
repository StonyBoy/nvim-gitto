# nvim-gitto

**nvim-gitto** shows the git log of your current folder and helps you navigate branches and files

## Features

- Show the git log of the repository of your current file
- Show all local branches in the repository
- Open a commit and inspect the changes it contains
- Open a specific file and inspect the changes using vimdiff
- Create a new branch at a specific commit
- Delete a branch (not the current)
- Change to a different branch

## Dependencies

You need at least NVIM version 0.9.0 to use this plugin, and of course you need git installed somewhere in your path.

## Installation

Add StonyBoy/nvim-gitto to your list of plugins

This is how to add the plugin with Lazy (https://github.com/folke/lazy.nvim):

```lua
  {
    'StonyBoy/nvim-gitto',                         -- Git log plugin
    config = function()
      vim.api.nvim_create_user_command('GL', function()
        require('log_session').new()
      end, {
        nargs = '*',
        desc = 'Start a Gitto git log session'
      })
      vim.api.nvim_set_keymap('n', '<Leader><Leader>q', '',
      {
        noremap = true, silent = true,
        callback = require('git_session').shutdown
      })
    end,
  },
```


## Customization

The plugin uses mostly hardcoded bindings, so the two actions that you can configure is:

- Startup: require('log_session').new()
- Shutdown: require('git_session').shutdown

The startup and shutdown was shown in the previous section.

With that configuration the ```:GL``` command will start a new Gitto Log Session on the current file and the
`<Leader><Leader>q` sequence will close all Gitto windows.

## Usage

Use the above `GL` command to open a Gitto Session for the current file.  This will show the git log for the repository
that the current file is part of or an error message `<filename> is not in a git repo` if the file is not part of a
repository.

The plugin has a number of states (sessions) that you can use to see different types of information from Git.

Here is a state diagram that shows what is available:

![State Diagram](/documentation/states.png "The Plugin States")

The curly brackets shows the keybinding that you use to activate an action or change to a new state.  In some cases you
need to move the cursor to a certain line in the file to let Gitto know what the contents of the new session should
contain.

### Log Session

This is what you see when you start the plugin, and the view opens a 50% window that lists the log of the git
repository in the current folder (or one of the parent folders).

The view looks like this:

![Log Session](/documentation/log_session.png "List")

What you see here is a list of commits sorted in descending time order.  You can see the SHA, Commit Date, Commit Author
and the subject.

By default only the first 100 commits are shown as this a time consuming operation, but you can get the next block of
commits by pressing `gn`.

You can toggle between the full repository log and a file-specific log by pressing `gf`. When file filtering is active,
only commits that touched the file you had open when starting `:GL` are shown.

If you now scroll to a particular commit and open a Diff Session with `gd` (or `<Enter>`) or show a list of branches by
opening a Branch Session with `gb`.

If you modify the state of the repository from e.g. a terminal session the log that you view might be outdated, but you
can refresh the view with `gr`.

Finally you can create a branch at the current commit (where the cursor is) by using `gc`.

![New branches](/documentation/new_branches.png "Show new branches")

The above shows two new branches `helper` and `tester`.

To see all the available keybinding you can press F1 to get a small help screen like this:

![Log Session Help](/documentation/log_session_help.png "Help")

### Branch Session

The Branch Session shows all the local branches in the repository.  It is possible to change to one of the branches or
delete a branch from this session.

![Branches](/documentation/branches.png "Showing all local branches")

The current branch is marked with a star.

Use `gq` or `<BS>` (Backspace) to close the Branch Session and return to the Log Session.

### Commit Session

The commit session shows the content of the commit that you selected in the Log Session, and contains two parts:

- The commit message section
- The diff section

![Commit](/documentation/commit_session.png "Showing commit content")

The diff section is collapsed by default but can be expanded with the standard folding keybindings:

- `<Right>` : Open the fold under the cursor
- `<Left>` : Close the fold under the cursor
- `<Enter>` : Toggle the fold under the cursor (open/close)
- `zR` : Open all folds
- `zC` : Close all folds under the cursor recursively

Use the command `:help folding` to find out more.

When the cursor is in the diff section you can open a File Diff Session to view the full file content using the `go`
binding.

Use `gq` or `<BS>` (Backspace) to close the Commit Session and return to the Log Session.

### Diff Session

The Diff Session also shows the content of the selected commit but in a slightly different way than the Commit Session.

What you will see is:

- The commit message section
- The file list section

The file list section contains all the files that are changed in this commit with the number of added and deleted lines
shown in front of each filename.

![Diff Session](/documentation/diff_session.png "Showing commit file difference")

Each file can then be selected (by moving the cursor on top of it) and you can open a File Diff Session with `go` (or
`<Enter>`)

Use `gq` or `<BS>` (Backspace) to close the Diff Session and return to the Log Session.

### Diff HEAD Session

The Diff HEAD Session is very similar to the Diff Session but here the difference is not to the previous commit but to
the HEAD of the git repository, so you can see what has been changed since the commit was created.

Use `gq` or `<BS>` (Backspace) to close the Diff HEAD Session and return to the Log Session.

## File Diff Session

The File Diff Session opens a new tab where the changed file is shown in the usual vimdiff style.

![File Diff Session](/documentation/file_diff_session.png "Showing file differences")

Use `gq` or `<BS>` (Backspace) to close the File Diff Session and return to the previous view.

## Future new features

This is the list of features that I plan to add to the plugin:

- Show differences on another branch without checking out that branch
- Get a copy of a file on a different branch
- Drop the use of syntax files and provide something more modern (treesitter syntax?)

