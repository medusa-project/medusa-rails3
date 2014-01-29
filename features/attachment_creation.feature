Feature: order to organize documents created outside of the system
  As a librarian
  I want to attach files to collections

  Scenario: Attach file
    Given I am logged in as an admin
    And There is a collection titled 'Dogs'
    And I view the collection titled 'Dogs'
    And I click on 'Add Attachment'
    And I fill in fields:
      | Description | What the attachment is. |
    And I attach fixture file 'grass.jpg' to 'Attachment'
    And I click on 'Create Attachment'
    When I view the collection titled 'Dogs'
    Then I should see 'What the attachment is.'
    And the collection titled 'Dogs' should have 1 attachment

  Scenario: Attach file as manager
    Given I am logged in as a manager
    And There is a collection titled 'Dogs'
    And I view the collection titled 'Dogs'
    And I click on 'Add Attachment'
    And I fill in fields:
      | Description | What the attachment is. |
    And I attach fixture file 'grass.jpg' to 'Attachment'
    And I click on 'Create Attachment'
    When I view the collection titled 'Dogs'
    Then I should see 'What the attachment is.'
    And the collection titled 'Dogs' should have 1 attachment