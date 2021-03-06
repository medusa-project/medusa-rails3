Feature: Cfs files by file extension
  In order to support preservation for certain content types implied by file extension
  As a librarian
  I want to be able to view and have statistics on files with given file extensions

  #Note that this doesn't physically copy files into place, just makes the db records
  Background:
    Given there are cfs directories with fields:
      | path |
      | root |
    And there are cfs files of the cfs directory with path 'root' with fields:
      | name          | size |
      | chihuahua.jpg | 567  |
      | pit_bull.xml  | 789  |
      | long_hair.JPG | 4000 |

  @javascript
  Scenario: Navigate from dashboard to view of cfs files with a extension
    Given I am logged in as an admin
    When I go to the dashboard
    And I click on 'File Statistics'
    And I click on 'jpg'
    Then I should be on the cfs files page for the file extension with extension 'jpg'
    And I should see a table of cfs files with 2 rows
    And I should see all of:
      | chihuahua.jpg | long_hair.JPG |
    And I should see none of:
      | pit_bull.xml |

  Scenario: Public user cannot view cfs files via extension
    Then deny object permission on the file extension with extension 'jpg' to users for action with redirection:
      | public user | cfs_files | authentication |

  @javascript
  Scenario: See stats for file extensions on the dashboard
    Given I am logged in as an admin
    When I go to the dashboard
    And I click on 'File Statistics'
    Then I should see all of:
      | 789 Bytes | 4.46 KB | 1 | 2 |

  Scenario: Stats are collected
    Then the file extension with fields should exist:
      | extension | cfs_file_count | cfs_file_size |
      | jpg       | 2              | 4567          |
      | xml       | 1              | 789           |
