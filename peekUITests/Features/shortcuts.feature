Feature: Shortcut links
  As someone who reaches for the same Mac every day
  I want a link that opens straight into it
  So that a Shortcut or the Action Button connects in one tap

  @saved-password
  Scenario: A peek link connects to the named computer
    Given the app is launched
    When I open the link "peek://connect?host=Studio%20Mac"
    Then I should see the remote screen

  Scenario: A peek link to an unknown address offers to add it
    Given the app is launched
    When I open the link "peek://connect?host=office.local:5901"
    Then the hostname field should contain "office.local"
