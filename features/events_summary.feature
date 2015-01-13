Feature: Events Summary
  In order to track events
  As a librarian
  I want to be able to view events at a variety of levels

  Background:
    Given I am logged in as an admin
    And the repository with title 'Animals' has child collections with fields:
      | title |
      | Dogs  |
      | Cats  |
    And the collection with title 'Dogs' has child file groups with fields:
      | title | type              |
      | Toys | BitLevelFileGroup |
      | Hot  | BitLevelFileGroup |
    And the collection with title 'Cats' has child file groups with fields:
      | title | type              |
      | Cool | BitLevelFileGroup |
    And the file group titled 'Toys' has events with fields:
      | note       |
      | toy note 1 |
      | toy note 2 |
    And the file group titled 'Toys' has scheduled events with fields:
      | key             | actor_email | action_date | state     |
      | external_to_bit | Buster@example.com      | 2012-02-02  | scheduled |
      | external_to_bit | Ruthie@example.com      | 2014-02-02  | completed |
    And the file group titled 'Hot' has events with fields:
      | note       |
      | hot note 1 |
    And the file group titled 'Hot' has scheduled events with fields:
      | key             | actor_email | action_date | state     |
      | external_to_bit | Oscar@example.com       | 2011-07-08  | scheduled |
    And the file group titled 'Cool' has events with fields:
      | note        |
      | cool note 1 |
    And the file group titled 'Cool' has scheduled events with fields:
      | key             | actor_email | action_date | state     |
      | external_to_bit | Coltrane@example.com    | 2011-09-10  | scheduled |
    And the repository with title 'Plants' has child collections with fields:
      | title |
      | Crops |
    And the collection with title 'Crops' has child file groups with fields:
      | title | type              |
      | Corn | BitLevelFileGroup |
    And the file group titled 'Corn' has events with fields:
      | note        |
      | corn note 1 |
    And the file group titled 'Corn' has scheduled events with fields:
      | key             | actor_email | action_date | state     |
      | external_to_bit | delmonte@example.com    | 2010-10-11  | scheduled |

  Scenario: View collection events
    When I view the collection with title 'Dogs'
    And I click on 'Events'
    Then I should see the events table
    And I should see all of:
      | toy note 1 | toy note 2 | hot note 1 | Buster | Oscar |
    And I should see none of:
      | cool note 1 | corn note 1 | Coltrane | delmonte | Ruthie |

  Scenario: View collection events as a manager
    Given I relogin as a manager
    When I view the collection with title 'Dogs'
    And I click on 'Events'
    Then I should see the events table
    And I should see all of:
      | toy note 1 | toy note 2 | hot note 1 | Buster | Oscar |
    And I should see none of:
      | cool note 1 | corn note 1 | Coltrane | delmonte | Ruthie |

  Scenario: View collection events as a visitor
    Given I relogin as a visitor
    When I view the collection with title 'Dogs'
    And I click on 'Events'
    Then I should see the events table
    And I should see all of:
      | toy note 1 | toy note 2 | hot note 1 | Buster | Oscar |
    And I should see none of:
      | cool note 1 | corn note 1 | Coltrane | delmonte |

  Scenario: Navigate from events list to owning object of an event
    When I view the collection with title 'Dogs'
    And I click on 'Events'
    And I click on 'Toys'
    Then I should be on the view page for the file group with title 'Toys'
    
  Scenario: View repository events
    When I view the repository with title 'Animals'
    And I click on 'Events'
    Then I should see the events table
    And I should see all of:
      | toy note 1 | toy note 2 | hot note 1 | cool note 1 | Buster | Oscar | Coltrane |
    And I should see none of:
      | corn note 1 | delmonte | Ruthie |

  Scenario: View all events
    When I go to the dashboard
    Then I should see the events table
    And I should see all of:
      | toy note 1 | toy note 2 | hot note 1 | cool note 1 | Buster | Oscar | Coltrane | corn note 1 | delmonte | Dogs | Cats |
    And I should see none of:
      | Ruthie |