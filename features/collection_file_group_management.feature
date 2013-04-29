Feature: File Group Management
  In order to manage File Groups connected with a collection
  As a librarian
  I want to create and delete File Groups for a collection

  Background:
    Given I am logged in as an admin
    And the repository titled 'Animals' has collections with fields:
      | title |
      | Dogs  |
    And the collection titled 'Dogs' has file groups with fields:
      | external_file_location | file_format | total_file_size | total_files | name   |
      | Main Library           | image/jpeg  | 100             | 1200        | images |
      | Grainger               | text/xml    | 4               | 2400        | texts  |

  Scenario: View file groups of a collection
    When I view the collection titled 'Dogs'
    Then I should see the file group collection table
    And I should see all of:
      | images | texts | 1200 | 2400 |

  Scenario: Navigate to file group
    When I view the collection titled 'Dogs'
    And I click on 'images' in the file groups table
    Then I should be on the view page for the file group with location 'Main Library' for the collection titled 'Dogs'

  Scenario: See id of file group in table
    When I view the collection titled 'Dogs'
    Then I should see the file group id for the file group with location 'Main Library' in the file group collection table
