Feature: Authorization
  In order to control access to myself
  As the system
  I want to be able to check user's authorizations

  Background:
    Given the collection with title 'Dogs' exists

  Scenario: A user should not be able to view a restricted page
    Given I am logged in as a user
    When I edit the collection with title 'Dogs'
    Then I should be redirected to the unauthorized page
    And I should see 'You are not authorized to view the requested page.'

  Scenario: An admin should be able to view things
    Given I am logged in as an admin
    When I edit the collection with title 'Dogs'
    Then I should be on the edit page for the collection with title 'Dogs'