Feature: Shell shortcuts preserve failures and argument boundaries
  Scenario: Clipboard copy fails in the Ctrl-O widget
    Given pbcopy exits with status 19
    When the copybuffer widget runs
    Then it returns status 19
    And it does not display a success message

  Scenario: Clipboard copy succeeds in the Ctrl-O widget
    Given pbcopy succeeds
    When the copybuffer widget runs
    Then it displays the success message

  Scenario: Home directory contains shell-special characters
    Given HOME contains spaces and a single quote
    When down, dev, or doc is invoked
    Then cd receives the corresponding directory as one argument
    When brewst is invoked
    Then brew receives the complete Brewfile path as one argument
