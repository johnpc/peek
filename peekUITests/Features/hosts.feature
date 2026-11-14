Feature: Saved computers
  As someone with a Mac in another room
  I want to keep a list of the computers I connect to
  So that connecting is one tap

  @no-hosts
  Scenario: Empty state invites adding a computer
    Given the app is launched
    Then I should see "No Computers Yet"
    And the "John's Mac mini" nearby computer should be listed

  Scenario: A saved computer is listed with its address
    Given the app is launched
    Then the "Studio Mac" computer should be listed
    And I should see "studio.local"

  Scenario: Adding a computer by address
    Given the app is launched
    When I tap "Add Computer"
    And I enter "Office iMac" as the name
    And I enter "office.local" as the hostname
    And I tap "Save"
    Then the "Office iMac" computer should be listed

  Scenario: Save requires a hostname
    Given the app is launched
    When I tap "Add Computer"
    And I enter "No Address" as the name
    Then the "Save" button should be disabled

  Scenario: Removing a computer
    Given the app is launched
    When I swipe to delete "Studio Mac"
    Then the "Studio Mac" computer should not be listed
