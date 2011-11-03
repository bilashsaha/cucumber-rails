@announce
Feature: Choose javascript database strategy

  When running a scenario with the @javascript tag, Capybara will fire up a web server 
  in the same process in a separate thread to your cukes. By default, this means ActiveRecord will give it a
  separate database connection, which in turn means data you put into your database from 
  Cucumber step definitions (e.g. using FactoryGirl) won't be visible to the web server
  until the database transaction is committed.

  So if you use a transaction strategy for cleaning up your database at the end of a scenario,
  it won't work for javascript scenarios by default.

  There are two ways around this. One is to switch to a truncation strategy for javascript
  scenarios. This is slower, but more reliable.

  The alternative is to patch ActiveRecord to share a single database connection between
  threads. This means you still get the speed benefits of using a transaction to roll back
  your database, but you run the risk of the two threads stomping on one another as they
  talk to the database.

  Right now, the default behavior which works for 80% of cucumber-rails users is to use 
  the shared connection patch, but you can override this by telling cucumber-rails which
  strategy to use for javascript scenarios.

  Background:
    Given I have created a new Rails 3 app and installed cucumber-rails
    And I have a "Widget" ActiveRecord model object
    And I append to "features/env.rb" with:
      """
      Cucumber::Rails::Database.javascript_strategy = :truncation
      """

  Scenario: Set the strategy to truncation and run a javascript scenario.
    Given I write to "features/widgets.feature" with:
      """
      @javascript
      Feature:
        Background:
          Given I have created 2 widgets

        Scenario:
          When I create 3 widgets
          Then I should have 5 widgets

        Scenario:
          Then I should have 2 widgets
      """
    And I write to "features/step_definitions/widget_steps.rb" with:
      """
      Given /created? (\d) widgets/ do |num|
        num.to_i.times { Widget.create! }
      end

      Then /should have (\d) widgets/ do |num|
        Widget.count.should == num.to_i
      end
      """
    When I run the cukes
    Then it should pass with:
       """
       2 scenarios (2 passed)
       5 steps (5 passed)
       """
