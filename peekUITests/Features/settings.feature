Feature: Settings
  As a user on slow Wi-Fi
  I want to trade picture quality for speed
  So that the remote screen stays responsive

  @saved-password
  Scenario: Settings shows a connection log after connecting
    Given I am connected to "Studio Mac"
    And I tap "Disconnect"
    When I open Settings
    Then I should see "Connection Log"
    And I should see "Share Full Log"

  Scenario: Color depth can be changed
    Given the app is launched
    When I open Settings
    And I choose the "16-bit" color depth
    Then the "16-bit" color depth should be selected
