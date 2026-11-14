Feature: Settings
  As a user on slow Wi-Fi
  I want to trade picture quality for speed
  So that the remote screen stays responsive

  Scenario: Color depth can be changed
    Given the app is launched
    When I open Settings
    And I choose the "16-bit" color depth
    Then the "16-bit" color depth should be selected
