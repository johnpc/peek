Feature: Connecting
  As a user
  I want to sign in to a computer and see its screen
  So that I can use it from my phone

  Scenario: Connecting asks for the password when none is saved
    Given the app is launched
    When I tap the "Studio Mac" computer
    Then I should be asked for a password
    And the username field should contain "john"

  Scenario: A wrong password can be retried
    Given the app is launched
    When I tap the "Studio Mac" computer
    And I enter "wrong" as the password
    And I tap "Connect"
    Then I should see "The password was not accepted."
    When I tap "Try Again"
    Then I should be asked for a password

  Scenario: The right password shows the remote screen
    Given the app is launched
    When I tap the "Studio Mac" computer
    And I enter "secret" as the password
    And I tap "Connect"
    Then I should see the remote screen
    And the status should read "Connected"

  @saved-password
  Scenario: A remembered password connects without asking
    Given the app is launched
    When I tap the "Studio Mac" computer
    Then I should see the remote screen

  @saved-password
  Scenario: Disconnecting returns to the computer list
    Given I am connected to "Studio Mac"
    When I tap "Disconnect"
    Then the "Studio Mac" computer should be listed

  Scenario: Remembering the password saves it for next time
    Given the app is launched
    When I tap the "Studio Mac" computer
    And I enter "secret" as the password
    And I turn on "Remember password"
    And I tap "Connect"
    And I tap "Disconnect"
    And I tap the "Studio Mac" computer
    Then I should see the remote screen
