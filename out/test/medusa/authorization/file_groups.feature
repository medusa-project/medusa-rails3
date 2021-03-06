Feature: File group authorization
  In order to protect file groups
  As the system
  I want to enforce proper authorization

  Background:
    Given the repository with title 'Animals' has child collection with fields:
      | title |
      | Dogs  |
    And the collection with title 'Dogs' has child file groups with fields:
      | title  | type              |
      | images | BitLevelFileGroup |

  Scenario: Enforce permissions
    Then deny object permission on the file group with title 'images' to users for action with redirection:
      | public user | view, edit, update, events, red_flags, attachments, assessments | authentication |
      | user        | edit, update                                                  | unauthorized   |
    And deny permission on the file group collection to users for action with redirection:
      | public user | new, create | authentication |

  Scenario: user tries to start a file group
    Then a user is unauthorized to start a file group for the collection titled 'Dogs'

  Scenario: user tries to create a file group
    Then a user is unauthorized to create a file group for the collection titled 'Dogs'


