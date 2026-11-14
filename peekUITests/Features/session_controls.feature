Feature: Controlling the remote screen
  As a user
  I want taps and keys to reach the remote computer
  So that I can actually use it, not just look at it

  @saved-password
  Scenario: Tapping the screen clicks
    Given I am connected to "Studio Mac"
    When I tap the remote screen
    Then the last input should be a left click

  @saved-password
  Scenario: The keyboard bar sends special keys
    Given I am connected to "Studio Mac"
    When I tap "Keyboard"
    And I tap the "esc" key
    Then the last input should be "key esc"

  @saved-password
  Scenario: Modifiers stay held until the next key
    Given I am connected to "Studio Mac"
    When I tap "Keyboard"
    And I tap the "⌘" key
    Then the "⌘" modifier should be held
    And the last input should be "hold ⌘"
    When I tap the "tab" key
    Then the "⌘" modifier should be released
    And the last input should be "key tab"
