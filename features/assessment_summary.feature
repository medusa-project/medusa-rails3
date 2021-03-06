Feature: Assessment summary
  In order to have an overview of assessments at different levels
  As a librarian
  I want to be able to view a summary of assessments for objects owned by other objects

  Background:
    Given I am logged in as an admin
    And the repository with title 'Animals' has child collections with fields:
      | title |
      | Dogs  |
      | Cats  |
    And the repository with title 'Plants' has child collections with fields:
      | title |
      | Cacti |
    And the collection with title 'Dogs' has child file groups with fields:
      | title |
      | Toy  |
      | Hot  |
    And the assessable file group with title 'Toy' has assessments with fields:
      | name           |
      | toy assessment |
    And the assessable file group with title 'Hot' has assessments with fields:
      | name           |
      | hot assessment |
    And the assessable collection with title 'Dogs' has assessments with fields:
      | name           |
      | dog assessment |
    And the assessable collection with title 'Cats' has assessments with fields:
      | name           |
      | cat assessment |
    And the assessable collection with title 'Cacti' has assessments with fields:
      | name           |
      | cacti assessment |

  Scenario: View collection and go to summary of assessments
    When I view the collection with title 'Dogs'
    And I click on 'Assessments'
    Then I should see all of:
      | toy assessment | hot assessment | dog assessment |
    And I should see none of:
      | cat assessment | cacti assessment |

  Scenario: View repository and go to summary of assessments
    When I view the repository with title 'Animals'
    And I click on 'Assessments'
    Then I should see all of:
      | toy assessment | hot assessment | dog assessment | cat assessment |
    And I should see none of:
      | cacti assessment |
