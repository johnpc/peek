Feature: Zooming the remote screen
  As a phone user looking at a big Mac display
  I want to pinch in on part of the screen and still click accurately
  So that small targets are usable

  @saved-password
  Scenario: Pinching zooms in, clicks stay accurate, and Fit zooms back out
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I pinch to zoom in on the remote screen
    Then the "Fit to screen" button should be visible
    When I tap the remote screen
    Then the last input should be a left click near the middle of the screen
    When I tap "Fit to screen"
    Then the "Fit to screen" button should not be visible
