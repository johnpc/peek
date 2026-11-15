Feature: Touchpad mode
  As someone with big fingers and a small phone
  I want to steer the Mac's pointer like a trackpad
  So that I can hit tiny targets without zooming

  @saved-password
  Scenario: Dragging moves the pointer and a tap clicks where it landed
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I switch to touchpad mode
    And I drag one finger across the remote screen
    And I tap the remote screen
    Then the last input should be a left click to the right of center
