Feature: Record structured rights data for collections and file groups
  In order to follow proper legal procedures and correctly restrict access
  As a librarian
  I want to be able to assign rights properties to collections and file groups

  Background:
    Given I am logged in as an admin
    And the repository with title 'Animals' has child collections with fields:
      | title |
      | Dogs  |
    And the collection with title 'Dogs' has child file groups with fields:
      | name     | external_file_location |
      | grainger | Grainger               |

  Scenario: Every collection should have rights attached
    Then the collection titled 'Dogs' should have rights attached

  Scenario: Every file group should have rights attached
    Then The file group with location 'Grainger' for the collection titled 'Dogs' should have rights attached

  Scenario: A rights declaration created with the default parameters defaults to copyright
    Then The rights declaration for the collection titled 'Dogs' should have rights basis 'copyright'

  Scenario: Viewing a collection I see rights declaration information
    When I view the collection with title 'Dogs'
    Then I should see the rights declaration section
    And I should see 'copyright'

  Scenario: Viewing a file group I see rights declaration information
    When I view the file group with name 'grainger'
    Then I should see the rights declaration section
    And I should see 'copyright'

  Scenario: Editing a collection I see a section to edit the rights declaration
    When I edit the collection with title 'Dogs'
    Then I should see the rights declaration section

  Scenario: Creating a collection I see a section to edit the rights declaration
    When I view the repository with title 'Animals'
    And I click on 'Add Collection'
    Then I should see the rights declaration section

  Scenario: Editing a file group I see a section to edit the rights declaration
    When I edit the file group with name 'grainger'
    Then I should see the rights declaration section

  Scenario: Creating a file group I see a section to edit the rights declaration
    When I view the collection with title 'Dogs'
    And I click on 'Add File Group'
    Then I should see the rights declaration section

  Scenario: Editing and changing rights information for a collection
    When I edit the collection with title 'Dogs'
    And I select 'statute' from 'Rights basis'
    And I select 'Canada' from 'Copyright jurisdiction'
    And I select 'Public domain.' from 'Copyright statement'
    And I select 'Access is open and unrestricted.' from 'Access restrictions'
    And I click on 'Update Collection'
    Then I should be on the view page for the collection with title 'Dogs'
    And I should not see 'copyright'
    And I should see all of:
      | statute | Canada | Public domain. | Access is open and unrestricted. |

  Scenario: Editing and changing rights information for a file group
    When I edit the file group with name 'grainger'
    And I select 'license' from 'Rights basis'
    And I click on 'Update File group'
    Then I should be on the view page for the file group with name 'grainger'
    And I should see 'license'
    And I should not see 'copyright'
