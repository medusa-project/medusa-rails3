Feature: Red flags
  In order to notice potential problems
  As a librarian
  I want to have the system automatically note potential file problems

  Background:
    Given I am logged in as an admin
    And I clear the cfs root directory
    And there is a cfs directory 'dogs'
    And the cfs directory 'dogs' contains cfs fixture file 'grass.jpg'
    And the collection titled 'Dogs' has file groups with fields:
      | name     |
      | pictures |
    And I set the cfs root of the file group named 'pictures' to 'dogs'

  Scenario: A file with basic properties but no FITS replaces the content-type without red flags
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | content_type |
      | text/plain   |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file 'dogs/grass.jpg' should have content type 'image/jpeg'
    And the cfs file 'dogs/grass.jpg' should have 0 red flags
    And the cfs file 'dogs/grass.jpg' should have FITS xml attached

  Scenario: A file with basic properties gets a red flag if size changes when FITS is run
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | size |
      | 100  |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file 'dogs/grass.jpg' should have 1 red flag
    And the cfs file 'dogs/grass.jpg' should have size '169804'

  Scenario: A file with basic properties gets a red flag if md5 sum changes when FITS is run
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | md5_sum                          |
      | 36dc5ffa0b229e9311cf0c4485b21a54 |
    When I create FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file 'dogs/grass.jpg' should have 1 red flag
    And the cfs file 'dogs/grass.jpg' should have md5 sum 'b001b52b12fc80ef6145b7655de0b668'

  Scenario: A file with FITS already run gets a red flag when content type, size, or md5 sum changes
    Given the cfs file info for the path 'dogs/grass.jpg' has fields:
      | fits_xml | content_type | size | md5_sum                          |
      | <fits/>  | text/plain   | 100  | 36dc5ffa0b229e9311cf0c4485b21a54 |
    When I update FITS for the cfs path 'dogs/grass.jpg'
    Then the cfs file 'dogs/grass.jpg' should have 3 red flags