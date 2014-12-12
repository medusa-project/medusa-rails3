Feature: Collection File Package Summary in File Groups
  In order to more conveniently record information about a whole file package
  As a librarian
  I want to be able to edit and see the collection file package summary when working on one of its file groups

  Background:
    Given I am logged in as an admin
    And the repository with title 'Animals' has child collections with fields:
      | title | file_package_summary          |
      | Dogs  | Original file package summary |
    And the collection with title 'Dogs' has child file groups with fields:
      | name | external_file_location | file_format | total_file_size | total_files |
      | main | Main Library           | image/jpeg  | 100             | 1200        |

  Scenario: See file package summary when viewing file group
    When I view the file group with name 'main'
    Then I should see all of:
      | Collection file package summary | Original file package summary |

  Scenario: Edit file package summary when editing file group, see results in file group
    When I edit the file group with name 'main'
    And I fill in fields:
      | Collection File Package Summary | New file package summary |
    And I click on 'Update'
    Then I should see 'New file package summary'
    And I should not see 'Original file package summary'

  Scenario: Edit file package summary when editing file group, see results in collection
    When I edit the file group with name 'main'
    And I fill in fields:
      | Collection File Package Summary | New file package summary |
    And I click on 'Update'
    And I view the collection with title 'Dogs'
    Then I should see 'New file package summary'
    And I should not see 'Original file package summary'
