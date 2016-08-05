@current
Feature: File Formats
  In order to manage files of various formats
  As a librarian
  I want to be able to group file format profiles and record notes about them

  Background:
    Given every file format with fields exists:
      | name | pronom_id | policy_summary                  |
      | tiff | fmt/353   | what we do with TIFF files      |
      | jp2  | fmt/392   | what we do with JPEG 2000 files |

  Scenario: View index of file formats
    Given I am logged in as a visitor
    When I go to the site home
    And I click on 'File Formats'
    Then I should see all of:
      | tiff | fmt/353 | what we do with TIFF files | jp2 | fmt/392 | what we do with JPEG 2000 files |

  Scenario: View file format
    Given I am logged in as a visitor
    When I view the file format with name 'tiff'
    Then I should see all of:
      | tiff | fmt/353 | what we do with TIFF files |

  Scenario: Create file format
    Given I am logged in as an admin
    When I go to the file format index page
    And I click on 'Add File Format'
    And I fill in fields:
      | Name           | XML        |
      | Pronom ID      | fmt/638    |
      | Policy summary | xml policy |
    And I click on 'Create'
    Then I should be on the view page for the file format with name 'XML'
    And I should see all of:
      | XML | fmt/638 | xml policy |

  Scenario: Edit file format
    Given I am logged in as an admin
    When I view the file format with name 'tiff'
    And I click on 'Edit'
    And I fill in fields:
      | Name           | TIFF       |
      | Pronom ID      | fmt/354    |
      | Policy summary | New policy |
    And I click on 'Update'
    Then I should be on the view page for the file format with name 'TIFF'
    And I should see all of:
      | TIFF | fmt/354 | New policy |
    And I should see none of:
      | tiff | fmt/353 | what we do with TIFF files |

  Scenario: Delete file format
    Given I am logged in as an admin
    When I edit the file format with name 'tiff'
    And I click on 'Delete'
    Then I should be on the file format index page
    And I should see none of:
      | tiff | fmt/353 | what we do with TIFF files |
    And I should see all of:
      | jp2  | fmt/392   | what we do with JPEG 2000 files |
    And there should be no file format with name 'tiff'
