//
//  SwiftTestCodeGeneratorTests+MultipleScenarios.swift
//  CapriccioLibTests
//
//  Created by Felipe Docil on 28/05/2019.
//

import Foundation
import Nimble
import Gherkin
@testable import CapriccioLib

extension SwiftTestCodeGeneratorTests {
    func testItGeneratesTheCorrectCodeWithAnOutlineScenarioAndASimpleScenario() {
        let examples = [Example(values: ["key1": "value1", "key2": "value2"]),
                        Example(values: ["key1": "value3", "key2": "value4"])]
        
        let scenarioOutline: Gherkin.Scenario = .outline(ScenarioOutline(name: "Scenario I want to test",
                                                                  description: "",
                                                                  steps:[Step(name: .given, text: "I'm in a situation"),
                                                                         Step(name: .when, text: "Something happens <key1>"),
                                                                         Step(name: .then, text: "Something else happens <key2>")],
                                                                  examples: examples))
        
        let scenarioSimple: Gherkin.Scenario = .simple(ScenarioSimple(name: "Simple Scenario I want to test",
                                                                      description: "",
                                                                      steps: [Step(name: .given, text: "I'm in a situation"),
                                                                              Step(name: .when, text: "Something simple happens")]))
        
        let feature = Feature(name: "Feature number one",
                              description: "",
                              scenarios: [scenarioOutline, scenarioSimple])
        
        let expectedResult = """
        /**
        This code is autogenerated using Capriccio 1.0.0 - https://github.com/shibapm/capriccio
        DO NOT EDIT
        */
        import XCTest
        import XCTest_Gherkin

        final class FeatureNumberOne: XCTestCase {
                func testScenarioIWantToTestWithValue1AndValue2() {
                    Given("I'm in a situation")
                    When("Something happens value1")
                    Then("Something else happens value2")
        
                }
        
                func testScenarioIWantToTestWithValue3AndValue4() {
                    Given("I'm in a situation")
                    When("Something happens value3")
                    Then("Something else happens value4")
                }

                func testSimpleScenarioIWantToTest() {
                    Given("I'm in a situation")
                    When("Something simple happens")
                }
        }
        """
        
        fileGenerationCheck(feature: feature, expectedResult: expectedResult)
    }
    
    func testAnotherTemplateThatUsesExampleStepParameter() {
        let path = "testPath"
        
        try! """
        import XCTest

        /**
        Feature:
        {{ feature.description }}
        */

        class {{ feature.name }}FeatureTest: {{ classType }} {
            {% for scenario in feature.scenarios %}
            {% if scenario.examples.count > 0 %}
            {% for example in scenario.examples %}
            func testScenario_{{ scenario.name }}_{{ example.valuesDescription }}() {
                {% for step in example.steps %}
                stepDefiner.step{{ step.name }}({% if step.parameters.count > 0 %}{% for parameter in step.parameters %}{{parameter.key}}: "{{parameter.value}}"{% if not forloop.last %},{% endif %}{% endfor %}{% endif %})
                {% endfor %}
            }
            {% endfor %}
            {% else %}
            func testScenario_{{ scenario.name }}() {
                {% for step in scenario.steps %}
                stepDefiner.step{{ step.name }}()
                {% endfor %}
            }
            {% endif %}
            {% endfor %}
        }
        """.write(toFile: path, atomically: false, encoding: .utf8)
        
        let scenarioSimple: Gherkin.Scenario = .simple(ScenarioSimple(name: "I want a simple test",
                                                                description: "",
                                                                steps:[Step(name: .given, text: "I'm in a situation"),
                                                                       Step(name: .when, text: "Something happens")] ))
        
        let examples = [Example(values: ["a": "testA", "b": "situationA"]),
                        Example(values: ["a": "testB", "b": "situationB"])]
        
        let scenarioOutline: Gherkin.Scenario = .outline(ScenarioOutline(name: "I want a complex test",
                                                                         description: "",
                                                                         steps:[Step(name: .given, text: "I'm in a situation"),
                                                                                Step(name: .when, text: "Something <a> happens"),
                                                                                Step(name: .then, text: "<b> just happened")],
                                                                         examples: examples))
        let feature = Feature(name: "Number one",
                              description: "",
                              scenarios: [scenarioSimple, scenarioOutline])
        
        let expectedResult = """
        import XCTest

        /**
        Feature:
        Number one
        */

        class NumberOneFeatureTest: XCTestCase {
            func testScenario_IWantASimpleTest() {
                stepDefiner.stepImInASituation()
                stepDefiner.stepSomethingHappens()
            }
            
            func testScenario_IWantAComplexTest_TestAAndSituationA() {
                stepDefiner.stepImInASituation()
                stepDefiner.stepSomethingHappens(a: "testA")
                stepDefiner.stepJustHappened(b: "situationA")
            }

            func testScenario_IWantAComplexTest_TestBAndSituationB() {
                stepDefiner.stepImInASituation()
                stepDefiner.stepSomethingHappens(a: "testB")
                stepDefiner.stepJustHappened(b: "situationB")
            }
        }
        """
        
        fileGenerationCheck(feature: feature, expectedResult: expectedResult, templateFilePath: path)
        
        try? FileManager.default.removeItem(atPath: path)
    }
}
