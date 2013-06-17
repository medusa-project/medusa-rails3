Feature: Schedule events for a file group
  In order to keep track of workflow
  As a librarian
  I want to be able to schedule events and have the system notify me about them

  Background:
    Given I am logged in as an admin
    And the collection titled 'Animals' has file groups with fields:
      | name |
      | Dogs |
    Given the file group named 'Dogs' has scheduled events with fields:
      | key             | actor_netid | action_date | state     |
      | external_to_bit | pete        | 2011-09-08  | scheduled |

  Scenario: View scheduled events for a file group
    When I view events for the file group named 'Dogs'
    Then I should see the scheduled events table
    And I should see all of:
      | Ingest external file group to bit-level store | pete | 2011-09-08 | scheduled |

  Scenario: I can schedule an event from the show view for a file group
    When I view the file group named 'Dogs'
    And I fill in fields for a scheduled event:
      | Note        | Dog deletion |
      | Actor       | joe          |
      | Action date | 2010-01-02   |
    And I select 'Delete external file group' from 'Scheduled event'
    And I click on 'Create Scheduled event'
    Then the file group named 'Dogs' should have a scheduled event with fields:
      | key             | actor_netid | action_date | note         | state     |
      | external_delete | joe         | 2010-01-02  | Dog deletion | scheduled |
    And I should be on the view page for the file group named 'Dogs'
    And 'joe@illinois.edu' should receive an email with subject 'Medusa scheduled event reminder'

  Scenario: I can schedule an event from the file manager (show view) for the corresponding collection
    When I view the collection titled 'Animals'
    And I click on 'Schedule'
    And I fill in fields for a scheduled event:
      | Note        | Dog deletion |
      | Actor       | joe          |
      | Action date | 2010-01-02   |
    And I select 'Delete external file group' from 'Scheduled event'
    And I click on 'Create Scheduled event'
    Then the file group named 'Dogs' should have a scheduled event with fields:
      | key             | actor_netid | action_date | note         | state     |
      | external_delete | joe         | 2010-01-02  | Dog deletion | scheduled |
    And I should be on the view page for the file group named 'Dogs'
    And 'joe@illinois.edu' should receive an email with subject 'Medusa scheduled event reminder'


  Scenario: Cancel a scheduled event for a file group
    When I view events for the file group named 'Dogs'
    And I click on 'cancel' in the scheduled events table
    Then the file group named 'Dogs' should have a scheduled event with fields:
      | key             | state     |
      | external_to_bit | cancelled |
    And I should be viewing events for the file group named 'Dogs'
    And I should see 'cancelled'

  Scenario: Complete a scheduled event for a file group
    When I view events for the file group named 'Dogs'
    And I click on 'complete' in the scheduled events table
    Then the file group named 'Dogs' should have a scheduled event with fields:
      | key             | state     |
      | external_to_bit | completed |
    And the file group named 'Dogs' should have an event with key 'staged_to_bit' performed by 'pete'
    And I should be viewing events for the file group named 'Dogs'
    And I should see 'completed'