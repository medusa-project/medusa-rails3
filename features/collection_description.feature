Feature: Collection description
  In order to track information about collections
  As a librarian
  I want to be able to edit collection information

  Background:
    Given I am logged in
    And the repository titled 'Sample Repo' has collections with fields:
      | title | start_date | end_date   | published | ongoing | description | access_url              | file_package_summary      | rights_statement | rights_restrictions | notes            |
      | dogs  | 2010-01-01 | 2012-02-02 | true      | true    | Dog stuff   | http://dogs.example.com | Dog files, not so orderly | Dog rights       | Dog restrictions    | Stuff about dogs |
      | cats  | 2011-10-10 |            | false     | true    | Cat stuff   | http://cats.example.com | Cat files, very orderly   | Cat rights       | Cat restrictions    | Stuff about cats |

  Scenario: View a collection
    When I view the collection titled 'dogs'
    Then I should see '2010-01-01'
    And I should see '2012-02-02'
    And I should see 'Dog stuff'
    And I should see 'http://dogs.example.com'
    And I should see 'Dog files, not so orderly'
    And I should see 'Dog rights'
    And I should see 'Dog restrictions'
    And I should see 'Stuff about dogs'

  Scenario: Edit a collection
    When I edit the collection titled 'dogs'
    And I fill in fields:
      | field       | value       |
      | Description | Puppy stuff |
    And I press 'Update Collection'
    Then I should be on the view page for the collection titled 'dogs'
    And I should see 'Puppy stuff'
    And I should not see 'Dog stuff'

  Scenario: Navigate from collection view page to owning repository
    When I view the collection titled 'dogs'
    And I click on 'Sample Repo'
    Then I should be on the view page for the repository titled 'Sample Repo'

  Scenario: Delete a collection from its view page
    When I view the collection titled 'dogs'
    And I click on 'Delete Collection'
    Then I should be on the view page for the repository titled 'Sample Repo'
    And I should not see 'dogs'

  Scenario: Create a new collection
    When I view the repository titled 'Sample Repo'
    And I click on 'Add Collection'
    And I fill in fields:
      | field       | value         |
      | Title       | reptiles      |
      | Description | Reptile stuff |
    And I press 'Create Collection'
    Then I should be on the view page for the collection titled 'reptiles'
    And I should see 'Reptile stuff'
    And the repository titled 'Sample Repo' should have a collection titled 'reptiles'