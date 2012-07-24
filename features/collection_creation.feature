Feature: Collection Management
  In order to make manage collections
  As a librarian
  I want to be able to create and delete collections from repositories

  Background:
    Given I am logged in
    And I have repositories with fields:
      | title       |
      | Sample Repo |
    And the repository titled 'Sample Repo' has collections with fields:
      | title             |
      | Sample Collection |

  Scenario: View collections of a repository
    When I view the repository titled 'Sample Repo'
    Then I should see the repository collection table
    And I should see 'Sample Collection'

  Scenario: Delete collection from a repository
    When I view the repository titled 'Sample Repo'
    And I click on 'Delete' in the collections table
    Then I should be on the view page for the repository titled 'Sample Repo'
    And I should not see 'Sample Collection'

  Scenario: Add a collection to a repository
    When I view the repository titled 'Sample Repo'
    And I click on 'Add Collection'
    Then I should be on the new collection page

  Scenario: Navigate to collection
    When I view the repository titled 'Sample Repo'
    And I click on 'Sample Collection'
    Then I should be on the view page for the collection titled 'Sample Collection'
