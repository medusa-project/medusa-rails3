Feature: Red flags authorization
  In order to protect the red flags
  As the system
  I want to enforce proper authorization

  Background:
    Given the main storage directory key 'dogs' contains cfs fixture content 'grass.jpg'
    And the collection with title 'Dogs' has child file groups with fields:
      | title    | type              |
      | pictures | BitLevelFileGroup |
    And I set the cfs root of the file group titled 'pictures' to 'dogs'
    And the file group titled 'pictures' has a cfs file for the path 'grass.jpg' with red flags with fields:
      | message       | notes           |
      | Size red flag | The size is off |

  Scenario: Enforce permissions
    Then deny object permission on the red flag with message 'Size red flag' to users for action with redirection:
      | public user | view, edit, update, unflag(post) | authentication |
      | user        | edit, update, unflag(post)       | unauthorized   |

