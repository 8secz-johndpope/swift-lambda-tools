//
//  DynamoCodingTests.swift
//  AWSLambdaAdapter
//
//  Created by Kelton Person on 7/12/19.
//

import XCTest
import Foundation
@testable import SwiftAWS



struct Person: Codable, Equatable {
    
    enum Severity: String, Codable {
        
        case low
        case medium
        case high
        
    }
    
    struct Allergy: Codable, Equatable {
     
        let name: String
        let category: String
        let severity: Severity
        
    }
    
    enum Animal: Codable, Equatable {
        
        case dog
        case cat
        case other(name: String)
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let animalOrOther = try values.decode(String.self, forKey: .rawValue)
            if animalOrOther == "dog" {
                self = .dog
            }
            else if animalOrOther == "cat" {
                self = .cat
            }
            else {
                let other = try values.decode(String.self, forKey: .rawValue)
                self = .other(name: other)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .cat: try container.encode("cat", forKey: .rawValue)
            case .dog: try container.encode("dog", forKey: .rawValue)
            case .other(let name): try container.encode(name, forKey: .rawValue)
            }
        }
        
        
        enum CodingKeys: String, CodingKey {
            case rawValue
        }
        
    }
    
    let firstName: String
    let lastName: String
    let age: Int
    
    let favoriteAnimal: Animal
    let secondFavoriteAnimal: Animal?
    let thirdFavoriteAnimal: Animal?

    let allergies: [Allergy]
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.age == rhs.age
            && lhs.firstName == rhs.firstName
            && lhs.lastName == rhs.lastName
            && lhs.favoriteAnimal == rhs.favoriteAnimal
            && lhs.secondFavoriteAnimal == rhs.secondFavoriteAnimal
            && lhs.allergies == rhs.allergies

        
    }

}


class DynamoCodingTests: XCTestCase {
    
    let person = Person(
        firstName: "Jane",
        lastName: "Smith",
        age: 45,
        favoriteAnimal: .cat,
        secondFavoriteAnimal: .other(name: "meerkat"),
        thirdFavoriteAnimal: nil,
        allergies: [
            Person.Allergy(name: "pollen", category: "nature", severity: .medium),
            Person.Allergy(name: "peanuts", category: "food", severity: .high)
        ]
    )

    func testEncode() {
        let dynamoDict = try! person.toDynamo()
        let expectedDict: [String : Any] = [
            "firstName": [
                "S": "Jane"
            ],
            "favoriteAnimal": [
                "M": [
                    "rawValue": [
                        "S": "cat"
                    ]
                ]
            ],
            "age": [
                "N": "45"
            ],
            "lastName": [
                "S": "Smith"
            ],
            "secondFavoriteAnimal": [
                "M": [
                    "rawValue": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "allergies": [
                "L": [
                    [
                        "M": [
                            "name": [
                                "S": "pollen"
                            ],
                            "category": [
                                "S": "nature"
                            ],
                            "severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "name": [
                                "S": "peanuts"
                            ],
                            "category": [
                                "S": "food"
                            ],
                            "severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        XCTAssertEqual(dynamoDict as NSObject, expectedDict as NSObject)
    }
    
    func testDecode() {
        let dict: [String : Any] = [
            "firstName": [
                "S": "Jane"
            ],
            "favoriteAnimal": [
                "M": [
                    "rawValue": [
                        "S": "cat"
                    ]
                ]
            ],
            "age": [
                "N": "45"
            ],
            "lastName": [
                "S": "Smith"
            ],
            "secondFavoriteAnimal": [
                "M": [
                    "rawValue": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "allergies": [
                "L": [
                    [
                        "M": [
                            "name": [
                                "S": "pollen"
                            ],
                            "category": [
                                "S": "nature"
                            ],
                            "severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "name": [
                                "S": "peanuts"
                            ],
                            "category": [
                                "S": "food"
                            ],
                            "severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let serialPerson = try! dict.fromDynamo(type: Person.self)
        XCTAssertEqual(person, serialPerson)
    }
    
    func testEncodeSnake() {
        let dynamoDict = try! person.toDynamo(caseSettings: .init(source: .camel, target: .snake))
        let expectedDict: [String : Any] = [
            "first_name": [
                "S": "Jane"
            ],
            "favorite_animal": [
                "M": [
                    "raw_value": [
                        "S": "cat"
                    ]
                ]
            ],
            "age": [
                "N": "45"
            ],
            "last_name": [
                "S": "Smith"
            ],
            "second_favorite_animal": [
                "M": [
                    "raw_value": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "allergies": [
                "L": [
                    [
                        "M": [
                            "name": [
                                "S": "pollen"
                            ],
                            "category": [
                                "S": "nature"
                            ],
                            "severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "name": [
                                "S": "peanuts"
                            ],
                            "category": [
                                "S": "food"
                            ],
                            "severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        XCTAssertEqual(dynamoDict as NSObject, expectedDict as NSObject)
    }
    
    func testDecodeSnake() {
        let dict: [String : Any] = [
            "first_name": [
                "S": "Jane"
            ],
            "favorite_animal": [
                "M": [
                    "raw_value": [
                        "S": "cat"
                    ]
                ]
            ],
            "age": [
                "N": "45"
            ],
            "last_name": [
                "S": "Smith"
            ],
            "second_favorite_animal": [
                "M": [
                    "raw_value": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "allergies": [
                "L": [
                    [
                        "M": [
                            "name": [
                                "S": "pollen"
                            ],
                            "category": [
                                "S": "nature"
                            ],
                            "severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "name": [
                                "S": "peanuts"
                            ],
                            "category": [
                                "S": "food"
                            ],
                            "severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let serialPerson = try! dict.fromDynamo(
            type: Person.self,
            caseSettings: .init(source: .camel, target: .snake)
        )
        XCTAssertEqual(person, serialPerson)
    }
    
    
    func testEncodePascal() {
        let dynamoDict = try! person.toDynamo(caseSettings: .init(source: .camel, target: .pascal))
        let expectedDict: [String : Any] = [
            "FirstName": [
                "S": "Jane"
            ],
            "FavoriteAnimal": [
                "M": [
                    "RawValue": [
                        "S": "cat"
                    ]
                ]
            ],
            "Age": [
                "N": "45"
            ],
            "LastName": [
                "S": "Smith"
            ],
            "SecondFavoriteAnimal": [
                "M": [
                    "RawValue": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "Allergies": [
                "L": [
                    [
                        "M": [
                            "Name": [
                                "S": "pollen"
                            ],
                            "Category": [
                                "S": "nature"
                            ],
                            "Severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "Name": [
                                "S": "peanuts"
                            ],
                            "Category": [
                                "S": "food"
                            ],
                            "Severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        XCTAssertEqual(dynamoDict as NSObject, expectedDict as NSObject)
    }

    func testDecodePascal() {
        let dict: [String : Any] = [
            "FirstName": [
                "S": "Jane"
            ],
            "FavoriteAnimal": [
                "M": [
                    "RawValue": [
                        "S": "cat"
                    ]
                ]
            ],
            "Age": [
                "N": "45"
            ],
            "LastName": [
                "S": "Smith"
            ],
            "SecondFavoriteAnimal": [
                "M": [
                    "RawValue": [
                        "S": "meerkat"
                    ]
                ]
            ],
            "Allergies": [
                "L": [
                    [
                        "M": [
                            "Name": [
                                "S": "pollen"
                            ],
                            "Category": [
                                "S": "nature"
                            ],
                            "Severity": [
                                "S": "medium"
                            ]
                        ]
                    ],
                    [
                        "M": [
                            "Name": [
                                "S": "peanuts"
                            ],
                            "Category": [
                                "S": "food"
                            ],
                            "Severity": [
                                "S": "high"
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let serialPerson = try! dict.fromDynamo(
            type: Person.self,
            caseSettings: .init(source: .camel, target: .pascal)
        )
        XCTAssertEqual(person, serialPerson)
    }
    
}
