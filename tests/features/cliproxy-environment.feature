Feature: CLI Proxy API configuration isolation
  Scenario: Shell secrets expose one proxy credential
    Given the local shell secrets configuration
    When it is loaded without inherited provider variables
    Then only CLIPROXYAPI_TOKEN supplies the proxy credential
    And the OpenAI-compatible URL is derived from the proxy host and port
    And no global OpenAI override is exported

  Scenario: Claude providers respect the configured proxy port
    Given managed CLI Proxy API providers, a proxy host, a non-default port, and an exported test token
    When every managed CLI Proxy API provider runs a mock Claude child
    Then each child uses that host and port without a v1 suffix
    And every CLI Proxy API provider references CLIPROXYAPI_TOKEN
    And each child receives the referenced test token
    And at least one CLI Proxy API provider is verified
