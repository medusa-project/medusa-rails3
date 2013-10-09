Feature: Package Profiles
  In order to facilitate preservation
  As a librarian
  I want to track the package profile used to preserve a collection

  Background:
    Given I am logged in as an admin
    And I have package profiles with fields:
      | name  | url                              | notes                           |
      | book  | http://book_profile.example.com  | Preservation package for books  |
      | image | http://image_profile.example.com | Preservation package for images |

  Scenario: View package profile
    When I view the package profile named 'book'
    Then I should be on the view page for the package profile named 'book'
    And I should see all of:
      | book | http://book_profile.example.com | Preservation package for books |
    And I should see none of:
      | image | http://image_profile.example.com | Preservation package for images |

  Scenario: View package profile index
    When I go to the package profile index page
    Then I should be on the package profile index page
    And I should see all of:
      | book | http://book_profile.example.com | image | http://image_profile.example.com |

  Scenario: Edit package profile
    When I edit the package profile named 'book'
    And I fill in fields:
      | Name  | tome                            |
      | Url   | http://tome_profile.example.com |
      | Notes | Preservation package for tomes  |
    And I click on 'Update Package profile'
    Then I should be on the view page for the package profile named 'tome'
    And I should see none of:
      | book | http://book_profile.example.com | Preservation package for books |
    And I should see all of:
      | tome | http://tome_profile.example.com | Preservation package for tomes |

  Scenario: Create package profile
    When I go to the package profile index page
    And I click on 'New Package Profile'
    And I fill in fields:
      | Name  | tome                            |
      | Url   | http://tome_profile.example.com |
      | Notes | Preservation package for tomes  |
    And I click on 'Create Package profile'
    Then I should be on the view page for the package profile named 'tome'
    And I should see all of:
      | tome | http://tome_profile.example.com | Preservation package for tomes |

  Scenario: Navigate from index to view package profile
    When I go to the package profile index page
    And I click on 'View'
    Then I should be on the view page for the package profile named 'book'

  Scenario: Navigate from show to index
    When I view the package profile named 'book'
    And I click on 'Index'
    Then I should be on the package profile index page

  Scenario: Delete package profile from index
    When I go to the package profile index page
    And I click on 'Delete'
    Then I should be on the package profile index page
    And I should see 'image'
    And I should not see 'book'

  Scenario: Delete package profile from show
    When I view the package profile named 'book'
    And I click on 'Delete'
    Then I should be on the package profile index page
    And I should see 'image'
    And I should not see 'book'

  Scenario: Edit package profile from index
    When I go to the package profile index page
    And I click on 'Edit'
    Then I should be on the edit page for the package profile named 'book'

  Scenario: Edit package profile from show
    When I view the package profile named 'book'
    And I click on 'Edit'
    Then I should be on the edit page for the package profile named 'book'

  Scenario: Link to package profile index from main page
    When I go to the dashboard
    And I click on 'Packages'
    Then I should be on the package profile index page

  Scenario: Navigate from index to collections for given package profile
    When the collection titled 'Dogs' has a file group with package profile named 'book'
    And the collection titled 'Cats' has a file group with package profile named 'book'
    And the collection titled 'Cats' has a file group with package profile named 'image'
    And the collection titled 'Bats' has a file group with package profile named 'image'
    When I go to the package profile index page
    And I click on 'book'
    Then I should be on the collection index page for collections with package profile 'book'
    And I should see all of:
      | Dogs | Cats |
    And I should not see 'Bats'
