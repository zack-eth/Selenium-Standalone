Feature: Cucumber

  Scenario: Cost
    Given a random symbol
    And a random quantity
    When I place an order
    Then the cost should equal the price times the quantity
