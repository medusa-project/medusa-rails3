Feature: File accrual
  In order to add files to already existing file groups
  As a medusa admin
  I want to be able to browse staging and start jobs to copy files from staging to bit storage

  Background:
    Given I clear the cfs root directory
    And the physical cfs directory 'dogs' has the data of bag 'accrual-initial-bag'
    And the collection with title 'Animals' has child file groups with fields:
      | title | type              |
      | Dogs  | BitLevelFileGroup |
      | Cats  | BitLevelFileGroup |
    And the file group titled 'Dogs' has cfs root 'dogs' and delayed jobs are run

  Scenario: There is no accrual button nor form on a file group without cfs directory
    Given I am logged in as a manager
    When I view the bit level file group with title 'Cats'
    Then I should not see 'Add files'
    And I should not see the accrual form and dialog

  Scenario: There is an accrual button and form on a file group with cfs directory
    Given I am logged in as a manager
    When I view the bit level file group with title 'Dogs'
    Then I should see 'Add files'
    And I should see the accrual form and dialog

  Scenario: There is an accrual button and form on a cfs directory
    Given I am logged in as a manager
    When I view the cfs directory for the file group titled 'Dogs' for the path 'pugs'
    Then I should see 'Add files'
    And I should see the accrual form and dialog

  Scenario: There is no accrual button nor form on a file group for a non medusa admin
    Given I am logged in as a visitor
    When I view the bit level file group with title 'Dogs'
    Then I should not see 'Add files'
    And I should not see the accrual form and dialog

  Scenario: There is no accrual button nor form on a cfs directory for a non medusa admin
    Given I am logged in as a visitor
    When I view the cfs directory for the file group titled 'Dogs' for the path 'pugs'
    Then I should not see 'Add files'
    And I should not see the accrual form and dialog

  @javascript
  Scenario: I can navigate the staging storage
    Given I am logged in as an admin
    And the bag 'small-bag' is staged in the root named 'staging-1' at path 'dogs'
    When I view the bit level file group with title 'Dogs'
    And I click link with title 'Run'
    And I click on 'Add files'
    And I click on 'staging-1'
    And I click on 'dogs'
    And within '#add-files-form' I click on 'data'
    Then I should see all of:
      | joe.txt | pete.txt | stuff |
    And I should see none of:
      | more.txt |

  @javascript
  Scenario: No conflict accrual, accepted
    And the bag 'accrual-disjoint-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: No conflict accrual, aborted
    And the bag 'accrual-disjoint-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: Harmless conflict accrual, accepted
    And the bag 'accrual-duplicate-overlap-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: Harmless conflict accrual, aborted
    And the bag 'accrual-duplicate-overlap-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: Changed conflict accrual, aborted by repository manager
    And the bag 'accrual-changed-overlap-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: Changed conflict accrual, aborted by preservation manager
    And the bag 'accrual-changed-overlap-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING

  @javascript
  Scenario: Changed conflict accrual, accepted by preservation manager
    And the bag 'accrual-changed-overlap-bag' is staged in the root named 'staging-1' at path 'dogs'
    When PENDING


#  @javascript
#  Scenario: Complete accrual
#    Given I am logged in as an admin
#    When I view the bit level file group with title 'Dogs'
#    And I click link with title 'Run'
#    And I click on 'Add files'
#    And I click on 'staging-1'
#    And I click on 'dogs'
#    And within '#add-files-form' I click on 'data'
#    And I check 'joe.txt'
#    And I check 'stuff'
#    And I click on 'Ingest'
#    Then the cfs directory with path 'dogs' should have an accrual job with 1 file and 1 directory
#    When delayed jobs are run
#    Then the cfs directory with path 'dogs' should have an accrual job with 0 files and 0 directories
#    Then the file group titled 'Dogs' should have a cfs directory for the path 'stuff'
#    And the file group titled 'Dogs' should have a cfs file for the path 'stuff/more.txt'
#    And the file group titled 'Dogs' should have a cfs file for the path 'joe.txt'
#    And the file group titled 'Dogs' should not have a cfs file for the path 'pete.txt'
#    And there should be 1 amazon backup delayed job
#    When amazon backup runs successfully
#    Then the file group titled 'Dogs' should have a completed Amazon backup
#    And 'admin@example.com' should receive an email with subject 'Amazon backup progress'
#    When delayed jobs are run
#    Then 'admin@example.com' should receive an email with subject 'Medusa accrual completed'
#
#  @javascript
#  Scenario: Abort accrual before copying if there is a file that we are requesting to be overwritten in the root directory
#    When the physical cfs directory 'dogs' has a file 'joe.txt' with contents 'anything'
#    And I am logged in as an admin
#    When I view the bit level file group with title 'Dogs'
#    And I click link with title 'Run'
#    And I click on 'Add files'
#    And I click on 'staging-1'
#    And I click on 'dogs'
#    And within '#add-files-form' I click on 'data'
#    And I check 'joe.txt'
#    And I click on 'Ingest'
#    When delayed jobs are run
#    Then the cfs directory with path 'dogs' should not have an accrual job
#    And there should be 0 amazon backup delayed jobs
#    And 'admin@example.com' should receive an email with subject 'Medusa accrual aborted'
#
#  @javascript
#  Scenario: Abort accrual before copying if there is a file that we are requesting to be overwritten in a subdirectory
#    When the physical cfs directory 'dogs/stuff' has a file 'more.txt' with contents 'anything'
#    And I am logged in as an admin
#    When I view the bit level file group with title 'Dogs'
#    And I click link with title 'Run'
#    And I click on 'Add files'
#    And I click on 'staging-1'
#    And I click on 'dogs'
#    And within '#add-files-form' I click on 'data'
#    And I check 'stuff'
#    And I click on 'Ingest'
#    When delayed jobs are run
#    Then the cfs directory with path 'dogs' should not have an accrual job
#    And there should be 0 amazon backup delayed jobs
#    And 'admin@example.com' should receive an email with subject 'Medusa accrual aborted'
