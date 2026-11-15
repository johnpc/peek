Feature: Clipboard
  As someone juggling a phone and a Mac
  I want text to move between them
  So that I never retype a URL or password

  @saved-password @pasteboard
  Scenario: The Paste key sends the phone's clipboard to the Mac
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Keyboard"
    And I tap the "Paste" key
    Then the last input should be "paste 21 characters"

  @saved-password
  Scenario: Pasting with an empty clipboard says so
    Given I am connected to "Studio Mac"
    And I dismiss the controls tip
    When I tap "Keyboard"
    And I tap the "Paste" key
    Then I should see "Nothing to paste"
