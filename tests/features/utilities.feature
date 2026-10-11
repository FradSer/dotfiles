Feature: Safe interactive shell utilities
  Scenario: Copy a relative path without modifying executable lookup
    Given a relative filename and a clipboard stub
    When copypath is called
    Then its absolute path is copied and PATH is unchanged

  Scenario: Failed clipboard command
    Given a clipboard command that exits 19
    When copypath is called
    Then it exits 19 without printing a success message

  Scenario: Failed archive extraction
    Given a downloaded archive whose extractor exits 23
    When take is called
    Then it exits 23 and does not announce Ready

  Scenario: Literal find-in-files queries
    Given a query containing shell syntax or a leading dash
    When fif searches and renders its preview
    Then both searches receive the query literally after an option terminator

  Scenario: Graceful process termination
    When fkill selects a process without an explicit signal
    Then it requests TERM

  Scenario: Toggle sudo while preserving cursor position
    When sudo is added or removed
    Then the cursor shifts with the prefix and never becomes negative
    And an empty buffer stays unchanged

  Scenario: Standard editor and clipboard widgets
    When keybindings load and the copy widget runs
    Then editing uses the built-in edit-command-line widget
    And copying displays a message without scheduling a callback

  Scenario: fzf initialization without evalcache
    Given fzf is available but evalcache is absent
    When the fzf configuration loads
    Then fzf shell integration is evaluated directly

  Scenario: Branch names containing HEAD remain selectable
    Given a local feature/HEAD-fix branch and a symbolic remote HEAD
    When fgb selects the local branch
    Then it switches to feature/HEAD-fix and excludes only the symbolic ref

  Scenario: Remote branch selection preserves its remote
    Given origin/release and upstream/release remote branches
    When fgb selects upstream/release
    Then it checks out refs/remotes/upstream/release detached

  Scenario: Log actions use the full explicit commit identifier
    Given a commit message containing deadbee and shell syntax
    When fgl previews and opens that commit
    Then both actions show only its full hash without executing message text
