Feature: Bit Level File Group virus check
  In order to enhance security
  As a librarian
  I want to be able to scan bit level file groups for viruses

  Background:
    Given I clear the cfs root directory
    And the cfs directory 'dogs/images' contains cfs fixture file 'clam.exe'
    And the cfs directory 'dogs/images' contains cfs fixture file 'grass.jpg'
    And the repository with title 'Animals' has child collections with fields:
      | title |
      | Dogs  |
    And the collection with title 'Dogs' has child file groups with fields:
      | name   | type              |
      | images | BitLevelFileGroup |
    And the file group named 'images' has cfs root 'dogs/images'

  Scenario: Run a virus check
    Given I am logged in as an admin
    When I view the collection with title 'Dogs'
    And I click on 'Run' in the virus-scan actions and delayed jobs are run
    Then the file group named 'images' should have 1 virus scan attached
    And the cfs file at path 'clam.exe' for the file group named 'images' should have 1 red flag

  Scenario: Run a virus check as a manager
    Given I am logged in as a manager
    When I view the collection with title 'Dogs'
    And I click on 'Run' in the virus-scan actions and delayed jobs are run
    Then the file group named 'images' should have 1 virus scan attached
    And the cfs file at path 'clam.exe' for the file group named 'images' should have 1 red flag
