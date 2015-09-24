Feature: Bit level file group deletion
  In order to prevent accidental deletion of bit level file groups with database or disk storage files attached
  As a librarian
  I want to have the system to stop such deletions and require manual intervention

  Background:
    Given the bit level file group with title 'Dogs' exists
    And I am logged in as an admin

  Scenario: A bit level file group with no db information or files except for the root cfs directory may be deleted
    When I edit the bit level file group with title 'Dogs'
    And I click on 'Delete'
    Then there should be no bit level file group with title 'Dogs'

  Scenario: A bit level file group with a db file in the root cfs directory may not be deleted
    Given I set the cfs root of the file group titled 'Dogs' to 'root'
    And the cfs directory with path 'root' has child cfs file with field name:
      | stuff.txt |
    When I edit the bit level file group with title 'Dogs'
    And I click on 'Delete'
    Then a bit level file group with title 'Dogs' should exist
    And I should see 'This file group has content and cannot be deleted. Please contact Medusa administrators to have it removed.'

  Scenario: A bit level file group with a db subdirectory in the root cfs directory may not be deleted
    Given I set the cfs root of the file group titled 'Dogs' to 'root'
    And the cfs directory with path 'root' has child cfs directory with field path:
      | stuff |
    When I edit the bit level file group with title 'Dogs'
    And I click on 'Delete'
    Then a bit level file group with title 'Dogs' should exist
    And I should see 'This file group has content and cannot be deleted. Please contact Medusa administrators to have it removed.'

  Scenario: A bit level file group with a disk file in the root cfs directory may not be deleted
    When PENDING

  Scenario: A bit level file gorup with a disk subdirectory in the root cfs directory may not be deleted
    When PENDING
