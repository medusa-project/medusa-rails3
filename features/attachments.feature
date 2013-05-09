Feature: order to organize documents created outside of the system
  As a librarian
  I want to attach files to collections

  Background:
    Given I am logged in as an admin
    And There is a collection titled 'Dogs'
    And I view the collection titled 'Dogs'
    And I click on 'Add Attachment'
    And I fill in fields:
      | Description | What the attachment is. |
    And I attach fixture file 'grass.jpg' to 'Attachment'
    And I click on 'Create Attachment'


  Scenario: Attach a file to a collection
    When I view the collection titled 'Dogs'
    Then I should see 'What the attachment is.'
    And the collection titled 'Dogs' should have 1 attachment

  Scenario: Download attachment from collection
    When I view the collection titled 'Dogs'
    And I click on 'Download'
    Then I should be on the download page for the attachment 'grass.jpg'

  Scenario: Delete attachment from collection
    When I view the collection titled 'Dogs'
    And I click on 'Delete' in the attachments section
    Then I should be on the view page for the collection titled 'Dogs'
    And the collection titled 'Dogs' should have 0 attachments

  Scenario: Update attachment from collection
    When I view the collection titled 'Dogs'
    And I click on 'Update' in the attachments section
    And I fill in fields:
      | Description | New info for attachment |
    And I attach fixture file 'fits.xml' to 'Attachment'
    And I click on 'Update Attachment'
    Then I should see 'New info for attachment'
    And I should not see 'What the attachment is.'
    And the collection titled 'Dogs' should have 1 attachment

  Scenario: View attachment details
    When I view the collection titled 'Dogs'
    And I click on 'grass.jpg'
    Then I should see all of:
      | grass.jpg | What the attachment is. | image/jpeg |