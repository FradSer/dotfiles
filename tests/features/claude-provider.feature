Feature: Safe Claude provider handling
  Scenario: Native Claude remains transparent
    Given inherited native authentication and a missing or malformed provider file
    When Claude is called without a provider or with arguments after --
    Then native authentication and arguments are preserved without invoking Python
  Scenario: Explicit provider selection
    When Claude is called with --provider NAME
    Then only the named provider is applied
    And missing, unknown, or repeated selections fail closed
    And inherited Vertex, Bedrock and Foundry routing is cleared in the child only
  Scenario: Provider execution is isolated
    Given a provider with token_var and extra environment flags
    When Claude exits with status 37 with redirected output
    Then the wrapper returns 37 without terminal escapes or parent environment mutation
  Scenario: Selected providers validate routing and isolate credentials
    Given a provider references ANTHROPIC_API_KEY as its token variable
    When that provider is selected
    Then the inherited token is resolved before native credentials are cleared
    And empty or invalid HTTP URLs are rejected before invoking Claude
    And extra flags cannot override authentication or endpoint variables
  Scenario: Provider data is never shell code
    Given TOML strings containing command substitutions
    When providers are loaded
    Then only environment variable references expand and substitutions remain data
  Scenario: Inline credentials fail closed
    Given a provider containing a legacy key field
    When it is selected or an edited document contains an inline key
    Then the operation fails with token_var guidance without exposing the key
  Scenario: Editor-based management preserves comments and validates changes
    Given a provider document with comments
    When an editor changes the document
    Then valid changes are saved atomically with private permissions
    And invalid changes do not replace the original document
    And success explains that only the target changed and gives the exact chezmoi add command
  Scenario: Python lacks the standard TOML parser
    Given Python cannot import tomllib
    When provider management starts
    Then a concise Python 3.11 requirement is printed without a traceback
  Scenario: Completion is read-only
    When completion is invoked repeatedly
    Then the global provider cache is unchanged
  Scenario: Completion respects the wrapper prefix
    When completion follows only leading --yolo or --provider NAME arguments
    Then wrapper options and provider value completion remain available
    And provider value completion lists configured names without changing the global cache
    But wrapper options are not offered after a native argument or --
  Scenario: Wrapper options form only a leading prefix
    When native option values contain --yolo or --provider
    Then all arguments from the first native argument remain verbatim
    And leading wrapper option permutations still select the provider and permission mode
    And --yolo-only calls require the Python helper without loading provider configuration
  Scenario: Expanded assignments and exported credentials remain literal
    Given extra flag values expand to spaces and shell syntax
    And an exported credential variable is named token, provider, url, or value
    When the provider is selected
    Then the child receives the exact values and the parent is unchanged
  Scenario: Editor validation checks semantics without secrets
    When an editor saves invalid URLs, missing token variable names, or unsupported tuning assignments
    Then the original document remains unchanged
    But valid environment-dependent templates can be saved without their environment
