Feature: Controlling the remote screen
  As a user
  I want taps and keys to reach the remote computer
  So that I can actually use it, not just look at it

  @saved-password
  Scenario: A first connection explains the touch controls
    Given I am connected to "Studio Mac"
    Then I should see "Tap to click, double-tap to double-click"
    When I dismiss the controls tip
    Then the controls tip should be gone

  @saved-password
  Scenario: Tapping the screen clicks
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap the remote screen
    Then the last input should be a left click

  @saved-password
  Scenario: The keyboard bar sends special keys
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Keyboard"
    And I tap the "esc" key
    Then the last input should be "key esc"

  @saved-password
  Scenario: The function-key page sends F-keys
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Keyboard"
    And I tap the "page" key
    And I tap the "F5" key
    Then the last input should be "key F5"

  @saved-password
  Scenario: Modifiers stay held until the next key
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Keyboard"
    And I tap the "⌘" key
    Then the "⌘" modifier should be held
    And the last input should be "hold ⌘"
    When I tap the "tab" key
    Then the "⌘" modifier should be released
    And the last input should be "key tab"

  @saved-password
  Scenario: The controls can be tucked away for a full-bleed screen
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Hide controls"
    Then the "Disconnect" button should not be visible
    When I tap "Show controls"
    Then I should see "Connected"

  @saved-password
  Scenario: The toolbar tucks itself away once the screen is up
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    Then the "Disconnect" button should not be visible
    When I tap "Show controls"
    Then I should see "Connected"
