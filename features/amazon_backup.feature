Feature: Amazon backup
  In order to have off site backups
  As an administrator
  I want to be able to bag cfs directories and send them to Amazon

  Background:
    Given I clear the cfs root directory
    And the collection with title 'Animals' has child file groups with fields:
      | title | type              |
      | Dogs | BitLevelFileGroup |
      | Cats | BitLevelFileGroup |
    And there is a physical cfs directory 'dogs'
    And there is a physical cfs directory 'cats'
    And the file group titled 'Dogs' has cfs root 'dogs'
    And the file group titled 'Cats' has cfs root 'cats' and delayed jobs are run

  Scenario: Full Amazon backup
    Given I am logged in as an admin
    And the physical cfs directory 'dogs' has the data of bag 'small-bag'
    And I run an initial cfs file assessment on the file group titled 'Dogs'
    When I run a full Amazon backup for the file group titled 'Dogs'
    Then the file group titled 'Dogs' should have a completed Amazon backup

  Scenario: Schedule amazon backup of a bit level file group
    Given I am logged in as an admin
    When I view the file group with title 'Dogs'
    And I click on 'Create backup'
    Then there should be 1 amazon backup delayed job

  @javascript
  Scenario: Bulk schedule amazon backup of bit level file groups
    Given I am logged in as an admin
    When I go to the dashboard
    And I click on 'Amazon'
    And I wait 1 second
    And I check all amazon backup checkboxes
    And I click on 'Create Backups'
    Then there should be 2 amazon backup delayed jobs

  Scenario: Amazon backup is restricted to medusa admins
    Then deny object permission on the bit level file group with title 'Dogs' to users for action with redirection:
      | public user      | create_amazon_backup(post) | authentication |
      | user, manager | create_amazon_backup(post) | unauthorized   |

  Scenario: Bulk amazon backup is restricted to medusa admins
    When deny permission on the bit level file group collection to users for action with redirection:
      | public user      | bulk_amazon_backup via post | authentication |
      | user, manager | bulk_amazon_backup via post | unauthorized   |

