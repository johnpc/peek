Feature: Nearby computers
  As a Mac owner
  I want Macs with Screen Sharing turned on to show up by themselves
  So that I never have to look up an address

  Scenario: Macs with Screen Sharing on appear automatically
    Given the app is launched
    Then the "John's Mac mini" nearby computer should be listed

  Scenario: Saving a nearby computer pre-fills its address
    Given the app is launched
    When I tap the "John's Mac mini" nearby computer
    Then the hostname field should contain "johns-mac-mini.local"
    When I tap "Save"
    Then the "John's Mac mini" computer should be listed

  Scenario: Help explains what to check when a Mac doesn't show up
    Given the app is launched
    When I tap "Help"
    Then I should see "Can't see your Mac?"
    And I should see "Away from home"

  @no-local-network
  Scenario: Declined Local Network access is explained instead of spinning forever
    Given the app is launched
    Then I should see "Local Network access is off"
    And I should see "Open Settings"
