Feature: Predictable interactive shell startup
  Scenario: Bun provides a local completion script
    Given a nonempty ~/.bun/_bun script
    When completion initialization runs
    Then the script loads after compinit and registers Bun completion

  Scenario: Bun completion is absent or empty
    Given no usable ~/.bun/_bun script
    When completion initialization runs
    Then startup succeeds without errors

  Scenario: The provider parser runtime is declared
    When a machine is bootstrapped from the Brewfile
    Then Python is an explicit dependency

  Scenario: Repository-only support files stay out of the home directory
    When chezmoi applies the repository
    Then tests and project memory are excluded

  Scenario: All interactive modules load in a clean home
    Given the complete managed rc.d tree and no optional tools
    When an interactive shell starts
    Then startup succeeds with no output or errors

  Scenario: Optional Homebrew plugins are not installed
    Given an isolated home with no Homebrew installation
    When initialization and plugin modules load
    Then startup succeeds without error output

  Scenario: Homebrew is installed at a custom prefix
    Given HOMEBREW_PREFIX points to an isolated installation
    When completion is initialized
    Then completion paths use that prefix

  Scenario: AI commands preserve safe native defaults
    Given mocked AI executables
    When an AI command is called normally
    Then its arguments are passed unchanged
    When its first argument is --yolo
    Then the matching unsafe flag is explicitly passed

  Scenario: Local configuration has final precedence
    Given a local override and optional environment setup
    When the interactive configuration loads
    Then the local override runs last

  Scenario: Interactive editor is consistent with the universal default
    When universal and interactive settings load
    Then the editor does not change between shell modes
    And an inherited editor preference is preserved

  Scenario: The secret editor accepts editor arguments
    Given EDITOR specifies an executable and a wait argument
    When esecret is invoked in an isolated home
    Then the editor receives the argument and the quoted secret file path

  Scenario: Tips are opt-in and reload replaces the shell
    When tip and alias modules load
    Then no tip is printed automatically
    And reload starts a fresh shell preserving login mode
