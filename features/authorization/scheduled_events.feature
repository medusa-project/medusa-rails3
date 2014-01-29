Feature: Scheduled event authorization
  In order to protect the scheduled events
  As the system
  I want to enforce proper authorization

  Background:
    Given the collection titled 'Dogs' has file groups with fields:
      | name | type              |
      | Toys | BitLevelFileGroup |
    And the file group named 'Toys' has scheduled events with fields:
      | key             | actor_netid | action_date | state     |
      | external_to_bit | Buster      | 2012-02-02  | scheduled |

  Scenario: Enforce permissions
    Then deny object permission on the scheduled event with key 'external_to_bit' to users for action with redirection:
      | public user      | edit, update, create, destroy, cancel(post), complete(post) | authentication |
      | visitor, manager | edit, update, create, destroy, cancel(post), complete(post) | unauthorized   |