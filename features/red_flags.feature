Feature: Red flags
  In order to notice potential problems
  As a librarian
  I want to have the system automatically note potential file problems

  Background:
    Given I clear the cfs root directory
    And there is a physical cfs directory 'dogs'
    And the cfs directory 'dogs' contains cfs fixture file 'grass.jpg'
    And the collection titled 'Dogs' has file groups with fields:
      | name     | type              |
      | pictures | BitLevelFileGroup |
    And I set the cfs root of the file group named 'pictures' to 'dogs'

  Scenario: A file with basic properties but no FITS replaces the content-type without red flags
    Given PENDING
    Given I am logged in as an admin
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | content_type |
      | text/plain   |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file 'dogs/grass.jpg' should have content type 'image/jpeg'
    And the cfs file at path 'grass.jpg' for the file group named 'pictures' should have 0 red flags
    And the cfs file 'dogs/grass.jpg' should have FITS xml attached

  Scenario: A file with basic properties gets a red flag if size changes when FITS is run
    Given PENDING
    Given I am logged in as an admin
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | size |
      | 100  |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file at path 'grass.jpg' for the file group named 'pictures' should have 1 red flag
    And the cfs file 'dogs/grass.jpg' should have size '169804'

  Scenario: A file with basic properties gets a red flag if md5 sum changes when FITS is run
    Given PENDING
    Given I am logged in as an admin
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | md5_sum                          |
      | 36dc5ffa0b229e9311cf0c4485b21a54 |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file at path 'grass.jpg' for the file group named 'pictures' should have 1 red flag
    And the cfs file 'dogs/grass.jpg' should have md5 sum 'b001b52b12fc80ef6145b7655de0b668'

  Scenario: A file with FITS already run gets a red flag when content type, size, or md5 sum changes
    Given PENDING
    Given I am logged in as an admin
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | fits_xml | content_type | size | md5_sum                          |
      | <fits/>  | text/plain   | 100  | 36dc5ffa0b229e9311cf0c4485b21a54 |
    When I update FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file at path 'grass.jpg' for the file group named 'pictures' should have 3 red flags

  Scenario: A list of red flags is available in the dashboard
    Given PENDING
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       |
      | Size red flag |
      | Md5 red flag  |
    When I go to the dashboard
    Then I should see all of:
      | Size red flag | Md5 red flag | medium | flagged |

  Scenario: View a red flag
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    Then I should see all of:
      | Size red flag | The size is off | medium | flagged |

  Scenario: View a red flag as manager
    Given I am logged in as a manager
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    Then I should see all of:
      | Size red flag | The size is off | medium | flagged |

  Scenario: View a red flag as visitor
    Given I am logged in as a visitor
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    Then I should see all of:
      | Size red flag | The size is off | medium | flagged |

  Scenario: Navigate from red flag to owning object
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    And I click on 'grass.jpg'
    Then I should be viewing the cfs file for the file group named 'pictures' for the path 'grass.jpg'

  Scenario: Edit red flag from its show view
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    And I click on 'Edit'
    And I fill in fields:
      | Notes | The size is really off |
    And I click on 'Update Red flag'
    Then I should see 'The size is really off'
    And I should not see 'The size is off'

  Scenario: Edit red flag from its show view as a manager
    Given I am logged in as a manager
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I view the first red flag for the file group named 'pictures' for the cfs file for the path 'grass.jpg'
    And I click on 'Edit'
    And I fill in fields:
      | Notes | The size is really off |
    And I click on 'Update Red flag'
    Then I should see 'The size is really off'
    And I should not see 'The size is off'

  Scenario: Navigate from index to red flag view
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I go to the dashboard
    And I click on 'View' in the red flags table
    Then I should be viewing the first red flag for the file group named 'pictures' for the path 'grass.jpg'

  Scenario: Navigate from index to red flag edit
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I go to the dashboard
    And I click on 'Edit' in the red flags table
    Then I should be editing the first red flag for the file group named 'pictures' for the path 'grass.jpg'

  Scenario: Mark red flag as unflagged from index view
    Given I am logged in as an admin
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I go to the dashboard
    And I click on 'Unflag' in the red flags table
    Then I should be on the dashboard page
    And I should see 'unflagged'

  Scenario: Mark red flag as unflagged from index view as a manager
    Given I am logged in as a manager
    And the file group named 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |
    When I go to the dashboard
    And I click on 'Unflag' in the red flags table
    Then I should be on the dashboard page
    And I should see 'unflagged'
